# ESP32 Video Upload Guide

This guide explains how to securely upload videos from ESP32 to Firebase Cloud Storage.

## Overview

There are two main approaches for uploading files from ESP32:

1. **Signed URLs** (Recommended) ✅
2. **Service Account Authentication** (More complex)

## Approach 1: Signed URLs (Recommended)

### How It Works

1. ESP32 requests a signed upload URL from your Cloud Function
2. Cloud Function generates a temporary, secure URL (valid for 15 minutes)
3. ESP32 uploads the video directly to Google Cloud Storage using the signed URL
4. The signed URL bypasses storage rules because it has built-in authentication

### Advantages

- ✅ **Secure**: No credentials stored on ESP32
- ✅ **Simple**: Just make an HTTP request to get the URL
- ✅ **Temporary**: URLs expire after 15 minutes
- ✅ **Scoped**: Each URL is for a specific file only

### Implementation

#### Step 1: Set the API Key Secret

Before deploying, set your API key as a Firebase secret:

```bash
cd firebase
firebase functions:secrets:set ESP32_API_KEY
```

You'll be prompted to enter your API key. Make it long and random (e.g., use a password generator).

**Important:** Keep this key secret! Don't commit it to version control.

#### Step 2: Deploy the Cloud Function

Deploy the function with the secret:

```bash
firebase deploy --only functions
```

The function will automatically have access to the `ESP32_API_KEY` secret.

#### Step 3: Get Your Function URL

After deployment, you'll get a URL like:
```
https://us-central1-your-project-id.cloudfunctions.net/generateUploadUrl
```

#### Step 4: Configure ESP32

1. Update `hardware/upload_example.ino`:
   - Set `functionUrl` to your Cloud Function URL
   - Set `apiKey` to the same key you set in Step 1

2. Upload the code to your ESP32

See `hardware/upload_example.ino` for a complete example.

**Quick Example:**

```cpp
const char* functionUrl = "YOUR_FUNCTION_URL";
const char* apiKey = "YOUR_API_KEY";

// 1. Request signed URL with API key
HTTPClient http;
String urlWithKey = String(functionUrl) + "?apiKey=" + String(apiKey);
http.begin(urlWithKey);
int code = http.GET();
String response = http.getString();

// Parse JSON to get uploadUrl
StaticJsonDocument<512> doc;
deserializeJson(doc, response);
const char* uploadUrl = doc["uploadUrl"];

// 2. Upload video to signed URL
http.begin(uploadUrl);
http.addHeader("Content-Type", "video/mp4");
File file = SPIFFS.open("/video.mp4", "r");
http.sendRequest("PUT", &file, file.size());
```

**Note:** You can also send the API key as a header:
```cpp
http.begin(functionUrl);
http.addHeader("X-API-Key", apiKey);
```

### Storage Rules

With signed URLs, your storage rules can deny direct writes:

```javascript
match /videos/{videoId} {
  allow write: if false; // Signed URLs bypass this anyway
}
```

The signed URL has its own authentication, so it works even with `allow write: if false`.

---

## Approach 2: Service Account Authentication

### How It Works

1. Create a Firebase service account
2. Download the JSON key file
3. Store the key on ESP32 (risky!)
4. ESP32 uses the key to authenticate directly with Firebase Storage

### Advantages

- ✅ Direct upload without calling a function first
- ✅ Can upload to any path (if rules allow)

### Disadvantages

- ❌ **Security Risk**: Service account key stored on device
- ❌ **Complex**: Requires JWT token generation on ESP32
- ❌ **If compromised**: Attacker has full service account access

### Implementation (Not Recommended)

If you really need this approach:

1. **Create Service Account:**
   - Go to Firebase Console → Project Settings → Service Accounts
   - Click "Generate New Private Key"
   - Download the JSON file

2. **Extract Credentials:**
   - You'll need: `project_id`, `private_key`, `client_email`

3. **ESP32 Implementation:**
   - Use a JWT library to create tokens
   - Authenticate with Google Cloud Storage API
   - Upload using OAuth2

**This is complex and not recommended for most use cases.**

---

## Recommendation

**Use Signed URLs (Approach 1)** because:
- More secure (no credentials on device)
- Easier to implement
- Better for production
- The Cloud Function can add additional validation/rate limiting

## Security Best Practices

1. **API Key Authentication** ✅ (Already implemented)
   - The `generateUploadUrl` function requires an API key
   - API key can be sent as query parameter (`?apiKey=...`) or header (`X-API-Key`)
   - Stored securely as a Firebase secret

2. **Restrict storage rules:**
   - Deny direct writes (force signed URLs)
   - Control read access

3. **Monitor uploads:**
   - Check Cloud Function logs
   - Set up alerts for unusual activity
   - Failed authentication attempts are logged

4. **API Key Management:**
   - Use a strong, random API key
   - Rotate keys periodically
   - If compromised, update the secret and redeploy:
     ```bash
     firebase functions:secrets:set ESP32_API_KEY
     firebase deploy --only functions
     ```

## API Key Authentication

The `generateUploadUrl` function is already secured with API key authentication.

**Setting the API Key:**
```bash
firebase functions:secrets:set ESP32_API_KEY
```

**Using the API Key:**

ESP32 can send the API key in two ways:

1. **Query Parameter:**
   ```
   https://your-function-url?apiKey=your-secret-key
   ```

2. **HTTP Header:**
   ```
   X-API-Key: your-secret-key
   ```

Both methods are supported. The function checks for the API key in this order:
1. Query parameter (`?apiKey=...`)
2. Header (`X-API-Key`)
3. Request body (`{"apiKey": "..."}`)

If the API key is missing or incorrect, the function returns `401 Unauthorized`.

