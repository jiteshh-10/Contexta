# Firebase Setup for Contexta

## Overview

Contexta uses Firebase for optional cloud backup and Google Sign-In. Follow these steps to enable these features.

## Prerequisites

- A Google account
- Flutter SDK installed
- FlutterFire CLI (optional but recommended)

## Setup Steps

### Option 1: Using FlutterFire CLI (Recommended)

1. **Install FlutterFire CLI:**
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Login to Firebase:**
   ```bash
   firebase login
   ```

3. **Configure Firebase:**
   ```bash
   flutterfire configure
   ```
   
   This will:
   - Create a new Firebase project (or let you select existing)
   - Generate `google-services.json` for Android
   - Generate `GoogleService-Info.plist` for iOS
   - Create `lib/firebase_options.dart`

4. **Run the app:**
   ```bash
   flutter run
   ```

### Option 2: Manual Setup

1. **Create Firebase Project:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Add project"
   - Name it "Contexta" (or your preference)
   - Disable Google Analytics (optional)
   - Click "Create project"

2. **Add Android App:**
   - In Firebase Console, click "Add app" → Android
   - Package name: `com.example.contexta` (or your app ID)
   - App nickname: "Contexta Android"
   - Debug signing certificate SHA-1:
     ```bash
     cd android
     ./gradlew signingReport
     ```
     Copy the SHA-1 from the debug variant
   - Click "Register app"

3. **Download google-services.json:**
   - Download `google-services.json`
   - Place it in `android/app/google-services.json`

4. **Enable Cloud Firestore:**
   - In Firebase Console → Build → Firestore Database
   - Click "Create database"
   - Choose "Start in production mode"
   - Select a location near your users
   - Click "Create"

5. **Set Firestore Rules:**
   - Go to Firestore → Rules
   - Replace with:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users can only access their own data
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```
   - Click "Publish"

6. **Enable Google Sign-In:**
   - In Firebase Console → Authentication
   - Click "Get started"
   - Go to "Sign-in method" tab
   - Enable "Google"
   - Add your support email
   - Click "Save"

## Verify Setup

After setup, run:
```bash
flutter clean
flutter pub get
flutter run
```

The "Continue with Google" button should now work on the ownership choice screen.

## Troubleshooting

### "Something went wrong" error

1. **Missing google-services.json:**
   - Ensure `android/app/google-services.json` exists

2. **Wrong SHA-1:**
   - Run `./gradlew signingReport` in android folder
   - Add the SHA-1 to Firebase Console → Project Settings → Your apps → Android → Add fingerprint

3. **Google Sign-In not enabled:**
   - Check Firebase Console → Authentication → Sign-in method → Google is enabled

### Build errors

1. **Clean build:**
   ```bash
   flutter clean
   cd android
   ./gradlew clean
   cd ..
   flutter pub get
   flutter run
   ```

2. **Check minSdkVersion:**
   - Firebase requires `minSdkVersion 21` or higher
   - This is already set in flutter.minSdkVersion

## Security Notes

- **google-services.json** is safe to commit to version control (it contains only public identifiers)
- User data in Firestore is protected by security rules
- Only authenticated users can access their own backup data
- No data is shared between users
