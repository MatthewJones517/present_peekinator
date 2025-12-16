const {onRequest} = require("firebase-functions/v2/https");
const {onObjectFinalized} = require("firebase-functions/v2/storage");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const crypto = require("crypto");

/**
 * Lazy initialization helper for Firebase Admin SDK.
 * @return {admin} The initialized admin instance.
 */
function getAdmin() {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  return admin;
}

/**
 * Get a random notification title.
 * @return {string} A random title from the predefined list.
 */
function getRandomTitle() {
  const titles = [
    "Present Peeker Detected!",
    "Caught in the Act!",
    "Someone's Being Sneaky...",
    "Gift Box Opened Early!",
    "Naughty List Alert!",
    "Sneak Peek Detected!",
    "Mystery Box Opened!",
    "The Trap Has Sprung!",
  ];
  return titles[Math.floor(Math.random() * titles.length)];
}

/**
 * Get a random notification body.
 * @return {string} A random body from the predefined list.
 */
function getRandomBody() {
  const bodies = [
    "Someone just opened the gift box!",
    "Your present is being investigated right now...",
    "Tap to watch the culprit caught on camera!",
    "The trap worked! Check out who couldn't wait.",
    "Caught red-handed! See the evidence.",
    "The wait was too much for them...",
    "Your gift box has been compromised!",
    "Time to see who the sneaky one is!",
  ];
  return bodies[Math.floor(Math.random() * bodies.length)];
}

/**
 * Send a push notification to all devices subscribed to the topic.
 * @param {string} downloadURL The download URL of the video.
 * @return {Promise<void>}
 */
async function sendPushNotification(downloadURL) {
  try {
    const messaging = getAdmin().messaging();
    const title = getRandomTitle();
    const body = getRandomBody();

    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: "video_uploaded",
        downloadURL: downloadURL,
      },
      topic: "all_devices", // Matches the topic the app subscribes to
    };

    const response = await messaging.send(message);
    logger.info("Push notification sent successfully", {
      messageId: response,
      title: title,
      body: body,
      downloadURL: downloadURL,
    });
  } catch (error) {
    logger.error("Error sending push notification", {
      error: error.message,
      downloadURL: downloadURL,
    });
    // Don't throw - we don't want notification failures to break
    // video processing
  }
}

// Cloud Storage trigger: When a video file is uploaded, get its download URL
// and store it in Firestore with a timestamp
exports.onVideoUploaded = onObjectFinalized(
    {
      region: "us-east1", // Must match storage bucket region
    },
    async (event) => {
      const file = event.data;
      const filePath = file.name;
      const contentType = file.contentType;

      logger.info(`File uploaded: ${filePath}`, {
        contentType: contentType,
        size: file.size,
      });

      // Only process video files
      if (!contentType || !contentType.startsWith("video/")) {
        logger.info(`Skipping non-video file: ${filePath}`);
        return;
      }

      try {
        // Get the download URL for the uploaded file
        const bucket = getAdmin().storage().bucket(file.bucket);
        const fileRef = bucket.file(filePath);

        // Make the file publicly accessible and get the download URL
        // Note: You can also use signed URLs if you prefer not to
        // make files public
        await fileRef.makePublic();
        const downloadURL = `https://storage.googleapis.com/${file.bucket}/${filePath}`;

        logger.info(`Download URL generated: ${downloadURL}`);

        // Store the URL and timestamp in Firestore
        const db = getAdmin().firestore();
        const timestamp = getAdmin().firestore.FieldValue.serverTimestamp();

        await db.collection("videos").add({
          filePath: filePath,
          downloadURL: downloadURL,
          contentType: contentType,
          size: file.size,
          uploadedAt: timestamp,
          bucket: file.bucket,
        });

        logger.info(`Video metadata saved to Firestore: ${filePath}`);

        // Send push notification to all devices
        await sendPushNotification(downloadURL);
      } catch (error) {
        logger.error(`Error processing video upload: ${filePath}`, error);
        throw error;
      }
    });

// HTTP function to generate a signed URL for video uploads from ESP32
// This provides a more secure way to upload files
// Secrets are declared in the function options for v2 functions
exports.generateUploadUrl = onRequest(
    {
      region: "us-east1", // Deploy in us-east1
      secrets: ["ESP32_API_KEY"], // Declare the secret
      cors: true, // Enable CORS
    },
    async (req, res) => {
      // API Key authentication
      // Check for API key in query parameter, header, or body
      const apiKey = req.query.apiKey ||
          req.headers["x-api-key"] ||
          (req.body && typeof req.body === "object" &&
            req.body.apiKey);

      // Get the expected API key from the secret
      // Set this using: firebase functions:secrets:set ESP32_API_KEY
      const expectedApiKey = process.env.ESP32_API_KEY;

      if (!expectedApiKey) {
        const errorMsg = "ESP32_API_KEY not configured. " +
            "Set it using: firebase functions:secrets:set ESP32_API_KEY";
        logger.error(errorMsg);
        res.status(500).json({
          error: "Server configuration error",
          message: "API key not configured on server",
        });
        return;
      }

      if (!apiKey || apiKey !== expectedApiKey) {
        logger.warn("Unauthorized request - invalid or missing API key", {
          hasApiKey: !!apiKey,
          ip: req.ip,
        });
        res.status(401).json({
          error: "Unauthorized",
          message: "Invalid or missing API key",
        });
        return;
      }

      try {
        const bucket = getAdmin().storage().bucket();
        // Generate a unique GUID for the filename to avoid collisions
        const guid = crypto.randomUUID();
        // Changed to .avi to match ESP32 output
        const fileName = `videos/${guid}.avi`;
        const file = bucket.file(fileName);

        // Generate a signed URL that allows uploads
        // Note: This requires the service account to have
        // "Service Account Token Creator" role
        const [url] = await file.getSignedUrl({
          version: "v4",
          action: "write",
          expires: Date.now() + 15 * 60 * 1000, // 15 minutes
          contentType: "video/x-msvideo", // AVI MIME type
        });

        logger.info(`Generated upload URL for: ${fileName}`, {
          ip: req.ip,
        });

        res.status(200).json({
          uploadUrl: url,
          fileName: fileName,
          expiresIn: 15 * 60, // seconds
        });
      } catch (error) {
        logger.error("Error generating upload URL", error);
        // Log more details about the error
        logger.error("Error details:", {
          message: error.message,
          code: error.code,
          stack: error.stack,
        });
        res.status(500).json({
          error: "Failed to generate upload URL",
          message: error.message,
          code: error.code,
        });
      }
    });
