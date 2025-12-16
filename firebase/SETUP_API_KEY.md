# API Key Setup Guide

This guide walks you through setting up API key authentication for the `generateUploadUrl` Cloud Function.

## Step 1: Generate a Strong API Key

Generate a secure, random API key. You can use:

- **Online generator**: https://www.random.org/strings/
- **Command line**: 
  ```bash
  # Linux/Mac
  openssl rand -hex 32
  
  # Windows PowerShell
  -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | % {[char]$_})
  ```

Make it at least 32 characters long. Example:
```
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6
```

## Step 2: Set the Secret in Firebase

```bash
cd firebase
firebase functions:secrets:set ESP32_API_KEY
```

You'll be prompted to enter your API key. Paste the key you generated in Step 1.

**Important:** 
- The secret is stored securely by Firebase
- It won't appear in your code or logs
- You can update it anytime using the same command

## Step 3: Deploy the Function

```bash
firebase deploy --only functions
```

The function will automatically have access to the `ESP32_API_KEY` secret.

## Step 4: Configure Your ESP32

Update `hardware/upload_example.ino`:

```cpp
const char* functionUrl = "https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/generateUploadUrl";
const char* apiKey = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6"; // Your API key
```

## Step 5: Test the Setup

1. Upload the ESP32 code
2. Check the serial monitor
3. The ESP32 should successfully get a signed URL
4. If you see "401 Unauthorized", check that:
   - The API key in your ESP32 code matches the secret
   - The secret is set correctly: `firebase functions:secrets:access ESP32_API_KEY`

## Rotating the API Key

If your API key is compromised or you want to rotate it:

1. Generate a new API key
2. Set the new secret:
   ```bash
   firebase functions:secrets:set ESP32_API_KEY
   ```
3. Redeploy the function:
   ```bash
   firebase deploy --only functions
   ```
4. Update all ESP32 devices with the new key

## Viewing the Secret (for verification)

To verify the secret is set correctly:

```bash
firebase functions:secrets:access ESP32_API_KEY
```

## Troubleshooting

### "API key not configured on server"
- Make sure you've set the secret: `firebase functions:secrets:set ESP32_API_KEY`
- Redeploy the function after setting the secret

### "401 Unauthorized"
- Verify the API key in your ESP32 code matches the secret
- Check for typos or extra spaces
- Make sure you're sending it as `?apiKey=...` or `X-API-Key` header

### Secret not accessible
- Ensure you're using Firebase Functions v2 (which we are)
- The secret must be declared in the function options: `secrets: ["ESP32_API_KEY"]`
- Redeploy after setting the secret

