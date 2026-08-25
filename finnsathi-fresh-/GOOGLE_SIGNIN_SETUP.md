# Google Sign-In Setup for FinSathi App

This guide explains how to set up Google Sign-In for the FinSathi Flutter app.

## Android Setup

1. **Create OAuth Client ID in Google Cloud Console**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select an existing one
   - Navigate to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth client ID"
   - Select "Android" as the application type
   - Enter your app's package name (e.g., `com.example.finsaathi_multi`)
   - Generate a SHA-1 fingerprint using:
     ```
     keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
     ```
   - Enter the SHA-1 fingerprint
   - Click "Create"

2. **Update Android Configuration**:
   - Replace `YOUR_OAUTH_CLIENT_ID` in `android/app/src/main/res/values/strings.xml` with your actual OAuth Client ID

3. **Enable Google Sign-In API**:
   - In Google Cloud Console, navigate to "APIs & Services" > "Library"
   - Search for "Google Sign-In API" and enable it

## Backend Integration

Your backend needs to implement a Google Sign-In verification endpoint:

1. **Create a `/auth/google` endpoint** that:
   - Accepts POST requests with:
     - `idToken`: The ID token from Google
     - `accessToken`: The access token from Google
     - `name`: User's name from Google
     - `email`: User's email from Google
     - `photoUrl`: User's profile photo URL from Google
   
   - Verifies the Google ID token
   - Creates or updates the user in your database
   - Returns a JWT token for your app's authentication

## Testing

1. Make sure you've run `flutter pub get` to install the `google_sign_in` package
2. Run the app on an Android device or emulator
3. Tap the "Sign in with Google" button
4. Select a Google account
5. The app should authenticate with your backend and navigate to the home screen

## Troubleshooting

- If sign-in fails, check the debug logs for error messages
- Verify that your OAuth Client ID is correct
- Make sure the Google Sign-In API is enabled in Google Cloud Console
- Verify that your backend endpoint is correctly processing the Google tokens
