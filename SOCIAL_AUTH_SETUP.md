# Social Authentication Setup Guide

This guide will help you configure Google Sign-In and Facebook Login for the Better You app.

## Prerequisites

1. Firebase project created and configured
2. Android and iOS apps registered in Firebase Console
3. SHA-1 fingerprints added for Android (required for Google Sign-In)

---

## 🔵 Google Sign-In Setup

### Step 1: Enable Google Sign-In in Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Authentication** → **Sign-in method**
4. Enable **Google** provider
5. Save

### Step 2: Android Configuration

Google Sign-In should work automatically on Android if you've added the SHA-1 fingerprints to Firebase.

To get your SHA-1 fingerprint:
```bash
cd android
./gradlew signingReport
```

Add the SHA-1 to Firebase Console:
- Project Settings → Your Android App → SHA certificate fingerprints

### Step 3: iOS Configuration

1. In Firebase Console, add your iOS bundle ID
2. Download `GoogleService-Info.plist`
3. Add it to your iOS project in Xcode

---

## 🔵 Facebook Login Setup

### Step 1: Create Facebook App

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create a new app (Select "Build Connected Experiences")
3. Add Facebook Login product to your app

### Step 2: Configure Android

Add to `android/app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Better You</string>
    <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
    <string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
</resources>
```

Add to `android/app/src/main/AndroidManifest.xml` inside `<application>`:

```xml
<meta-data android:name="com.facebook.sdk.ApplicationId" android:value="@string/facebook_app_id"/>
<meta-data android:name="com.facebook.sdk.ClientToken" android:value="YOUR_CLIENT_TOKEN"/>

<activity android:name="com.facebook.FacebookActivity"
    android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
    android:label="@string/app_name" />

<activity
    android:name="com.facebook.CustomTabActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="@string/fb_login_protocol_scheme" />
    </intent-filter>
</activity>
```

### Step 3: Configure iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fbYOUR_FACEBOOK_APP_ID</string>
        </array>
    </dict>
</array>
<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID</string>
<key>FacebookClientToken</key>
<string>YOUR_CLIENT_TOKEN</string>
<key>FacebookDisplayName</key>
<string>Better You</string>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>fbapi</string>
    <string>fb-messenger-share-api</string>
</array>
```

---

## ⚙️ Firebase Console Configuration

### OAuth Redirect URIs (for Facebook)

In Facebook Developer Console → Facebook Login → Settings:

Add these to "Valid OAuth Redirect URIs":
```
https://YOUR-FIREBASE-PROJECT.firebaseapp.com/__/auth/handler
```

You can find this URL in Firebase Console → Authentication → Settings → Authorized domains

---

## 🔐 Security Notes

1. **Never commit API keys** - Use `.env` file or environment variables
2. **Enable app verification** in Firebase for production
3. **Set up OAuth consent screen** in Google Cloud Console
4. **Configure app domains** in Facebook Developer Console

---

## 🧪 Testing

After setup:

1. Run `flutter pub get`
2. Clean build: `flutter clean`
3. Rebuild: `flutter run`

Test both login methods on both platforms.

---

## 🐛 Troubleshooting

### Google Sign-In Issues

**Error: DEVELOPER_ERROR**
- SHA-1 fingerprint not added to Firebase
- Wrong OAuth client ID

**Error: 10:**
- Missing or incorrect SHA-1 in Firebase Console

### Facebook Login Issues

**Error: Invalid key hash**
- Generate key hash: `keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64`
- Add to Facebook Developer Console → Settings → Key Hashes

**Error: App not set up**
- Make sure app is live (not in development mode) in Facebook Developer Console
- Or add test users

---

## 📱 Platform-Specific Notes

### Android
- Minimum SDK: 21 (Android 5.0)
- Requires Chrome Custom Tabs or browser for web fallback

### iOS
- Minimum iOS: 12.0
- Requires CocoaPods 1.10.0+
- Add URL scheme to Info.plist as shown above

---

## 📝 Additional Resources

- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
- [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
- [Facebook Auth Flutter](https://pub.dev/packages/flutter_facebook_auth)
