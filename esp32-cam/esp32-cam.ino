#include "Arduino.h"
#include "esp_camera.h"
#include "FS.h"
#include "SD_MMC.h"
#include "soc/soc.h"            // Prevent brownout problems
#include "soc/rtc_cntl_reg.h"   // Prevent brownout problems
#include "driver/ledc.h"        // For LEDC PWM control
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>        

// Camera pin configuration for AI Thinker ESP32-CAM
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27

#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

// On-board flash LED pin
#define FLASH_PIN          4

// Button pin
#define BUTTON_PIN         12

// WiFi credentials - UPDATE THESE FOR YOUR NETWORK
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// Firebase Cloud Function URL
// Format: https://REGION-PROJECT_ID.cloudfunctions.net/generateUploadUrl
// Update this with your own Firebase project's function URL
const char* functionUrl = "YOUR_CLOUD_FUNCTION_URL";

// API Key for authentication
// Generate a random key and set it using: firebase functions:secrets:set ESP32_API_KEY
// Then put the same key here
const char* apiKey = "YOUR_API_KEY_HERE";

// Video recording state structure
struct VideoRecordingState {
  bool isRecording;
  File file;
  uint32_t totalFrames;
  uint32_t currentFrame;
  uint32_t frameInterval;  // milliseconds between frames
  uint32_t nextFrameTime;  // when to capture next frame
  uint32_t totalBytes;
  uint32_t startTime;
  char path[64];
  uint32_t aviHeaderPos;      // Position where AVI header will be written
  uint32_t moviChunkPos;       // Position where movi chunk starts
  uint32_t indexPos;           // Position where index will be written
  uint32_t* frameSizes;        // Array to store frame sizes for index
  uint32_t* framePositions;    // Array to store frame positions for index
};

static VideoRecordingState recordingState = {0};

// Button state
static bool buttonEnabled = true;
static bool lastButtonState = LOW;        // Last stable button state (after debounce)
static bool lastReading = LOW;            // Last raw reading from pin
static unsigned long lastDebounceTime = 0;
static const unsigned long debounceDelay = 50;  // 50ms debounce delay
static bool sequenceInProgress = false;

// AVI helper functions
static void writeFourCC(File& file, const char* fourcc) {
  file.write((uint8_t*)fourcc, 4);
}

static void writeUint32(File& file, uint32_t value) {
  file.write((uint8_t*)&value, 4);
}

static void writeUint16(File& file, uint16_t value) {
  file.write((uint8_t*)&value, 2);
}

// Write AVI main header
static void writeAVIHeader(File& file, uint32_t width, uint32_t height, uint32_t fps, uint32_t totalFrames) {
  // RIFF header
  writeFourCC(file, "RIFF");
  uint32_t riffSizePos = file.position();
  writeUint32(file, 0);  // Will be filled later
  writeFourCC(file, "AVI ");
  
  // AVI header list
  writeFourCC(file, "LIST");
  uint32_t hdrlSizePos = file.position();
  writeUint32(file, 0);  // Will be filled later
  writeFourCC(file, "hdrl");
  
  // AVI main header
  writeFourCC(file, "avih");
  writeUint32(file, 56);  // Size of avih chunk
  uint32_t microSecPerFrame = 1000000 / fps;
  writeUint32(file, microSecPerFrame);
  writeUint32(file, 0);  // MaxBytesPerSec (0 = unknown)
  writeUint32(file, 0);  // Padding
  writeUint32(file, 0x00000010);  // Flags (has index)
  writeUint32(file, totalFrames);
  writeUint32(file, 0);  // InitialFrames
  writeUint32(file, 1);  // Streams
  writeUint32(file, 0);  // SuggestedBufferSize
  writeUint32(file, width);
  writeUint32(file, height);
  writeUint32(file, 0);  // Reserved[0]
  writeUint32(file, 0);  // Reserved[1]
  writeUint32(file, 0);  // Reserved[2]
  writeUint32(file, 0);  // Reserved[3]
  
  // Stream list
  writeFourCC(file, "LIST");
  uint32_t strlSizePos = file.position();
  writeUint32(file, 0);  // Will be filled later
  writeFourCC(file, "strl");
  
  // Stream header
  writeFourCC(file, "strh");
  writeUint32(file, 56);  // Size of strh chunk
  writeFourCC(file, "vids");
  writeFourCC(file, "MJPG");  // MJPEG codec
  writeUint32(file, 0);  // Flags
  writeUint16(file, 0);  // Priority
  writeUint16(file, 0);  // Language
  writeUint32(file, 0);  // InitialFrames
  writeUint32(file, 1);  // Scale
  writeUint32(file, fps);  // Rate
  writeUint32(file, 0);  // Start
  writeUint32(file, totalFrames);  // Length
  writeUint32(file, 0);  // SuggestedBufferSize
  writeUint32(file, 0);  // Quality
  writeUint32(file, 0);  // SampleSize
  writeUint16(file, 0);  // left
  writeUint16(file, 0);  // top
  writeUint16(file, width);  // right
  writeUint16(file, height);  // bottom
  
  // Stream format
  writeFourCC(file, "strf");
  writeUint32(file, 40);  // Size of strf chunk (BITMAPINFOHEADER)
  writeUint32(file, 40);  // Size
  writeUint32(file, width);
  writeUint32(file, height);
  writeUint16(file, 1);  // Planes
  writeUint16(file, 24);  // BitCount
  writeFourCC(file, "MJPG");  // Compression
  writeUint32(file, 0);  // SizeImage
  writeUint32(file, 0);  // XPelsPerMeter
  writeUint32(file, 0);  // YPelsPerMeter
  writeUint32(file, 0);  // ClrUsed
  writeUint32(file, 0);  // ClrImportant
  
  // Update strl size
  uint32_t strlEnd = file.position();
  file.seek(strlSizePos);
  writeUint32(file, strlEnd - strlSizePos - 4);
  file.seek(strlEnd);
  
  // Update hdrl size
  uint32_t hdrlEnd = file.position();
  file.seek(hdrlSizePos);
  writeUint32(file, hdrlEnd - hdrlSizePos - 4);
  file.seek(hdrlEnd);
  
  // Update RIFF size (will be updated again at end)
  recordingState.aviHeaderPos = riffSizePos;
}

static bool initCamera() {
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;

  if (psramFound()) {
    Serial.println("PSRAM found");
    // Optimized for video: smaller frame size and lower quality for faster writes
    config.frame_size = FRAMESIZE_VGA;    // 640x480 (much faster than UXGA)
    config.jpeg_quality = 20;             // 0-63, 20 is good quality but much smaller files
    config.fb_count = 2;                  // Double buffering for smoother capture
  } else {
    // Without PSRAM, use even smaller settings
    config.frame_size = FRAMESIZE_QVGA;   // 320x240
    config.jpeg_quality = 25;              // Lower quality for smaller files
    config.fb_count = 1;
  }

  // Use GRAB_WHEN_EMPTY for consistent frame capture in video recording
  // This ensures we get each frame without skipping
  #ifdef CAMERA_GRAB_WHEN_EMPTY
    config.grab_mode = CAMERA_GRAB_WHEN_EMPTY;
  #endif

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x\n", err);
    return false;
  }
  return true;
}

static bool initSDCard() {
  // Use 1-bit mode for ESP32-CAM SD slot; retry once
  if (!SD_MMC.begin("/sdcard", true)) {
    Serial.println("SD_MMC mount failed (first attempt)");
    delay(500);
    if (!SD_MMC.begin("/sdcard", true, false)) {
      Serial.println("SD_MMC mount failed");
      return false;
    }
  }

  uint8_t cardType = SD_MMC.cardType();
  if (cardType == CARD_NONE) {
    Serial.println("No SD card attached");
    return false;
  }

  Serial.print("SD type: ");
  if (cardType == CARD_MMC) Serial.println("MMC");
  else if (cardType == CARD_SD) Serial.println("SD");
  else if (cardType == CARD_SDHC) Serial.println("SDHC/SDXC");
  else Serial.println("Unknown");

  uint64_t size = SD_MMC.cardSize() / (1024ULL * 1024ULL);
  Serial.printf("SD size: %llu MB\n", size);
  return true;
}

// Get frame dimensions based on camera config
static void getFrameDimensions(uint32_t* width, uint32_t* height) {
  camera_fb_t* fb = esp_camera_fb_get();
  if (fb) {
    *width = fb->width;
    *height = fb->height;
    esp_camera_fb_return(fb);
  } else {
    // Defaults based on typical ESP32-CAM config
    *width = 1600;
    *height = 1200;
  }
}

// Start video recording (non-blocking)
static bool startVideoRecording(const char* path, uint32_t durationSeconds, uint8_t fps) {
  if (recordingState.isRecording) {
    Serial.println("Recording already in progress");
    return false;
  }
  
  recordingState.frameInterval = 1000 / fps;  // milliseconds between frames
  recordingState.totalFrames = durationSeconds * fps;
  recordingState.currentFrame = 0;
  recordingState.totalBytes = 0;
  recordingState.startTime = millis();
  recordingState.nextFrameTime = millis();  // Start immediately
  strncpy(recordingState.path, path, sizeof(recordingState.path) - 1);
  recordingState.path[sizeof(recordingState.path) - 1] = '\0';
  
  // Allocate arrays for frame tracking
  recordingState.frameSizes = (uint32_t*)malloc(recordingState.totalFrames * sizeof(uint32_t));
  recordingState.framePositions = (uint32_t*)malloc(recordingState.totalFrames * sizeof(uint32_t));
  if (!recordingState.frameSizes || !recordingState.framePositions) {
    Serial.println("Failed to allocate frame tracking arrays");
    return false;
  }
  
  recordingState.file = SD_MMC.open(path, FILE_WRITE);
  if (!recordingState.file) {
    Serial.println("Failed to open file for writing");
    if (recordingState.frameSizes) free(recordingState.frameSizes);
    if (recordingState.framePositions) free(recordingState.framePositions);
    recordingState.isRecording = false;
    return false;
  }

  // Get frame dimensions
  uint32_t width, height;
  getFrameDimensions(&width, &height);
  
  // Write AVI header
  writeAVIHeader(recordingState.file, width, height, fps, recordingState.totalFrames);
  
  // Start movi chunk
  writeFourCC(recordingState.file, "LIST");
  uint32_t moviSizePos = recordingState.file.position();
  writeUint32(recordingState.file, 0);  // Will be filled later
  writeFourCC(recordingState.file, "movi");
  recordingState.moviChunkPos = moviSizePos;

  recordingState.isRecording = true;
  Serial.printf("Started recording %u seconds at %u fps (%u frames) at %ux%u...\n", 
                durationSeconds, fps, recordingState.totalFrames, width, height);
  return true;
}

// Process next frame if it's time (non-blocking, call from loop())
static bool processVideoFrame() {
  if (!recordingState.isRecording) {
    return false;
  }
  
  // Check if it's time to capture the next frame
  uint32_t now = millis();
  if (now < recordingState.nextFrameTime) {
    return true;  // Still recording, but not time for next frame yet
  }
  
  // Time to capture next frame
  camera_fb_t* fb = esp_camera_fb_get();
  if (!fb) {
    Serial.printf("Camera capture failed at frame %u\n", recordingState.currentFrame);
    recordingState.file.close();
    if (recordingState.frameSizes) free(recordingState.frameSizes);
    if (recordingState.framePositions) free(recordingState.framePositions);
    recordingState.isRecording = false;
    return false;
  }

  // Write AVI frame chunk (00dc = uncompressed video frame)
  // Store frame position before writing chunk header (relative to movi chunk data start)
  uint32_t framePos = recordingState.file.position() - (recordingState.moviChunkPos + 8);
  recordingState.framePositions[recordingState.currentFrame] = framePos;
  
  // Write chunk header
  writeFourCC(recordingState.file, "00dc");
  writeUint32(recordingState.file, fb->len);  // Chunk size
  recordingState.frameSizes[recordingState.currentFrame] = fb->len;
  
  // Write the JPEG frame data in one operation
  size_t written = recordingState.file.write(fb->buf, fb->len);
  recordingState.totalBytes += written + 8;  // +8 for chunk header
  
  // Pad to even boundary (AVI requirement) - only if needed
  if (fb->len % 2) {
    recordingState.file.write((uint8_t)0);
    recordingState.totalBytes++;
  }
  
  // Don't flush after each frame - let the SD library buffer writes
  // This significantly improves write performance
  
  esp_camera_fb_return(fb);
  
  if (written != fb->len) {
    Serial.printf("File write incomplete at frame %u: wrote %u of %u bytes\n", 
                  recordingState.currentFrame, (unsigned)written, (unsigned)fb->len);
    recordingState.file.close();
    if (recordingState.frameSizes) free(recordingState.frameSizes);
    if (recordingState.framePositions) free(recordingState.framePositions);
    recordingState.isRecording = false;
    return false;
  }
  
  recordingState.currentFrame++;
  
  // Print progress every 10 frames
  if (recordingState.currentFrame % 10 == 0 || recordingState.currentFrame >= recordingState.totalFrames) {
    Serial.printf("Frame %u/%u recorded\n", recordingState.currentFrame, recordingState.totalFrames);
  }
  
  // Check if recording is complete
  if (recordingState.currentFrame >= recordingState.totalFrames) {
    // Finalize AVI file
    uint32_t moviEnd = recordingState.file.position();
    
    // Update movi chunk size
    recordingState.file.seek(recordingState.moviChunkPos);
    writeUint32(recordingState.file, moviEnd - recordingState.moviChunkPos - 4);
    recordingState.file.seek(moviEnd);
    
    // Write index
    recordingState.indexPos = recordingState.file.position();
    writeFourCC(recordingState.file, "idx1");
    uint32_t indexSize = recordingState.totalFrames * 16;  // 16 bytes per entry
    writeUint32(recordingState.file, indexSize);
    
    for (uint32_t i = 0; i < recordingState.totalFrames; i++) {
      writeFourCC(recordingState.file, "00dc");
      writeUint32(recordingState.file, 0x00000010);  // Flags (keyframe)
      writeUint32(recordingState.file, recordingState.framePositions[i]);
      writeUint32(recordingState.file, recordingState.frameSizes[i]);
    }
    
    // Update RIFF size
    uint32_t fileEnd = recordingState.file.position();
    recordingState.file.seek(recordingState.aviHeaderPos);
    writeUint32(recordingState.file, fileEnd - 8);
    recordingState.file.seek(fileEnd);
    
    recordingState.file.close();
    
    // Free frame tracking arrays
    if (recordingState.frameSizes) {
      free(recordingState.frameSizes);
      recordingState.frameSizes = nullptr;
    }
    if (recordingState.framePositions) {
      free(recordingState.framePositions);
      recordingState.framePositions = nullptr;
    }
    
    recordingState.isRecording = false;
    
    uint32_t totalTime = millis() - recordingState.startTime;
    Serial.printf("Video saved: %s (%u bytes, %u frames in %u ms)\n", 
                  recordingState.path, (unsigned)fileEnd, 
                  recordingState.totalFrames, totalTime);
    return false;  // Recording complete
  }
  
  // Schedule next frame
  recordingState.nextFrameTime = now + recordingState.frameInterval;
  return true;  // Still recording
}

// Check if currently recording
static bool isRecording() {
  return recordingState.isRecording;
}

// Upload video file to Firebase Storage using signed URL
static bool uploadVideo(const char* videoPath) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected, cannot upload");
    return false;
  }
  
  HTTPClient http;
  
  // Step 1: Get signed upload URL from Cloud Function
  Serial.println("Requesting signed upload URL...");
  
  http.begin(functionUrl);
  http.addHeader("X-API-Key", apiKey);
  
  int httpCode = http.GET();
  
  if (httpCode != HTTP_CODE_OK) {
    Serial.printf("Failed to get upload URL. HTTP code: %d\n", httpCode);
    if (httpCode > 0) {
      String response = http.getString();
      Serial.println("Response: " + response);
    }
    http.end();
    return false;
  }
  
  String response = http.getString();
  http.end();
  
  // Parse JSON response
  StaticJsonDocument<512> doc;
  DeserializationError error = deserializeJson(doc, response);
  
  if (error) {
    Serial.printf("JSON parsing failed: %s\n", error.c_str());
    return false;
  }
  
  const char* uploadUrl = doc["uploadUrl"];
  const char* fileName = doc["fileName"];
  int expiresIn = doc["expiresIn"];
  
  Serial.printf("Got signed URL for: %s (expires in %d seconds)\n", fileName, expiresIn);
  
  // Step 2: Upload video file to the signed URL
  Serial.println("Uploading video file...");
  
  // Open the video file from SD card
  File file = SD_MMC.open(videoPath, FILE_READ);
  if (!file) {
    Serial.printf("Failed to open file: %s\n", videoPath);
    return false;
  }
  
  size_t fileSize = file.size();
  Serial.printf("File size: %u bytes\n", (unsigned)fileSize);
  
  // Upload using PUT request to signed URL
  http.begin(uploadUrl);
  http.addHeader("Content-Type", "video/x-msvideo");  // AVI MIME type
  http.addHeader("Content-Length", String(fileSize));
  
  // Stream the file
  int httpResponseCode = http.sendRequest("PUT", &file, fileSize);
  file.close();
  
  if (httpResponseCode == 200 || httpResponseCode == 201) {
    Serial.println("Upload successful!");
    http.end();
    return true;
  } else {
    Serial.printf("Upload failed. HTTP code: %d\n", httpResponseCode);
    if (httpResponseCode > 0) {
      String response = http.getString();
      Serial.println("Response: " + response);
    }
    http.end();
    return false;
  }
}

// Flash LED helpers (PWM dimmable)
static void flashOn(uint8_t duty = 200) {  // 0..255
  static bool inited = false;
  if (!inited) {
    // Configure LEDC timer
    ledc_timer_config_t ledc_timer = {};
    ledc_timer.speed_mode = LEDC_LOW_SPEED_MODE;
    ledc_timer.timer_num = LEDC_TIMER_1;
    ledc_timer.duty_resolution = LEDC_TIMER_8_BIT;
    ledc_timer.freq_hz = 5000;
    ledc_timer.clk_cfg = LEDC_AUTO_CLK;
    ledc_timer_config(&ledc_timer);
    
    // Configure LEDC channel
    ledc_channel_config_t ledc_channel = {};
    ledc_channel.gpio_num = FLASH_PIN;
    ledc_channel.speed_mode = LEDC_LOW_SPEED_MODE;
    ledc_channel.channel = LEDC_CHANNEL_1;
    ledc_channel.timer_sel = LEDC_TIMER_1;
    ledc_channel.intr_type = LEDC_INTR_DISABLE;
    ledc_channel.duty = 0;
    ledc_channel.hpoint = 0;
    ledc_channel_config(&ledc_channel);
    inited = true;
  }
  // Set duty cycle (0-255 maps to 0-100%)
  ledc_set_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_1, duty);
  ledc_update_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_1);
}

static void flashOff() {
  ledc_set_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_1, 0);
  ledc_update_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_1);
}

// Configure camera settings (recommended settings for ESP32-CAM)
static void configureCameraSettings() {
  sensor_t* s = esp_camera_sensor_get();
  if (!s) return;
  s->set_gain_ctrl(s, 1);                // auto gain on
  s->set_exposure_ctrl(s, 1);           // auto exposure on
  s->set_awb_gain(s, 1);                // Auto White Balance enable (0 or 1)
  s->set_brightness(s, 1);              // (-2 to 2) - set brightness
}

void setup() {
  // Disable brownout detector to prevent random resets during power spikes
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);

  Serial.begin(115200);
  delay(2000);
  Serial.println();
  Serial.println("ESP32-CAM: record MJPEG video to SD and upload to Firebase");
  
  // Connect to WiFi
  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);
  
  int wifiAttempts = 0;
  while (WiFi.status() != WL_CONNECTED && wifiAttempts < 20) {
    delay(500);
    Serial.print(".");
    wifiAttempts++;
  }
  Serial.println();
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("WiFi connected!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("WiFi connection failed - upload will not work");
  }

  // Mount SD before powering/initializing the camera to reduce bus/power contention
  if (!initSDCard()) {
    Serial.println("Halting due to SD init failure");
    // Make sure camera is off if it was ever started
    esp_camera_deinit();
    while (true) { delay(1000); }
  }

  if (!initCamera()) {
    Serial.println("Halting due to camera init failure");
    esp_camera_deinit();
    while (true) { delay(1000); }
  }

  // Configure camera settings (test initialization)
  configureCameraSettings();
  
  // Deinitialize camera since we're not recording yet
  // It will be reinitialized when button is pressed
  esp_camera_deinit();
  
  // Initialize button pin (INPUT_PULLDOWN so pin is LOW when not driven HIGH by Nano)
  pinMode(BUTTON_PIN, INPUT_PULLDOWN);
  lastReading = digitalRead(BUTTON_PIN);
  lastButtonState = lastReading;  // Initialize stable state to current reading
  lastDebounceTime = millis();  // Initialize debounce timer to current time
  Serial.printf("Button initialized. Initial state: %s (pin %d)\n", 
                lastButtonState == HIGH ? "HIGH" : "LOW", BUTTON_PIN);
  
  Serial.println("Setup complete. Press button on pin 12 to start recording.");
}

void loop() {
  // Check button press (only if button is enabled and sequence not in progress)
  if (buttonEnabled && !sequenceInProgress) {
    int reading = digitalRead(BUTTON_PIN);
    
    // Check for button state change (reset debounce timer if changed)
    if (reading != lastReading) {
      lastDebounceTime = millis();
      Serial.printf("Button reading changed: %s -> %s\n", 
                    lastReading == HIGH ? "HIGH" : "LOW",
                    reading == HIGH ? "HIGH" : "LOW");
    }
    
    // Update lastReading immediately
    lastReading = reading;
    
    // Only process button state after debounce delay has passed
    if ((millis() - lastDebounceTime) > debounceDelay) {
      // Button state has been stable - check for trigger edge on stable state
      if (reading == HIGH && lastButtonState == LOW) {
        // Trigger signal received (rising edge) - state is stable
        Serial.println("Trigger signal received (debounced) - starting recording sequence");
        buttonEnabled = false;  // Disable button
        sequenceInProgress = true;
        
        // Initialize camera if not already initialized
        if (!initCamera()) {
          Serial.println("Failed to initialize camera");
          buttonEnabled = true;
          sequenceInProgress = false;
        } else {
          // Configure camera settings and pre-light the scene
          configureCameraSettings();
          flashOn(100);
          delay(400);
          
          // Start recording
          char path[64];
          snprintf(path, sizeof(path), "/video_%lu.avi", (unsigned long)millis());
          
          if (!startVideoRecording(path, 5, 12)) {  // 5 seconds at 12 fps
            Serial.println("Failed to start video recording");
            flashOff();
            esp_camera_deinit();
            buttonEnabled = true;
            sequenceInProgress = false;
          }
        }
      }
      // Update lastButtonState to the stable reading after debounce delay
      lastButtonState = reading;
    }
  }
  
  // Process video recording frames (non-blocking)
  if (isRecording()) {
    processVideoFrame();
  } else if (sequenceInProgress) {
    // Recording is complete, clean up and upload
    static bool cleanupDone = false;
    static bool uploadAttempted = false;
    
    if (!cleanupDone) {
      flashOff();
      esp_camera_deinit();
      Serial.println("Recording complete, camera deinitialized");
      cleanupDone = true;
    }
    
    // Upload video file after recording completes
    if (!uploadAttempted && recordingState.path[0] != '\0') {
      uploadAttempted = true;
      Serial.println("Starting video upload...");
      
      if (uploadVideo(recordingState.path)) {
        Serial.println("Video upload completed successfully!");
      } else {
        Serial.println("Video upload failed - file saved on SD card");
      }
      
      // Sequence complete - re-enable button
      Serial.println("Sequence complete. Button re-enabled.");
      buttonEnabled = true;
      sequenceInProgress = false;
      cleanupDone = false;
      uploadAttempted = false;
    }
  }
  
  // Small delay to prevent tight loop
  delay(1);
}

