# Deployment Date Tracking Setup

This setup allows you to track and display the last deployment date in your Flutter app.

## Setup Instructions

### 1. Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (`accelerator-squared-9e24e`)
3. Go to Project Settings > Service Accounts
4. Click "Generate new private key"
5. Download the JSON file and rename it to `serviceAccountKey.json`
6. Place it in your project root directory

### 2. Install Node.js Dependencies

```bash
npm install
```

### 3. Update Deployment Date

After deploying your app to Firebase, run:

```bash
npm run update-deploy-date
```

Or manually:

```bash
node update_deploy_date.js
```

## Alternative Approaches

### Option 2: Build-time Injection

You can also inject the deployment date at build time by modifying your build script:

```bash
# Add this to your deployment script
echo "const deployDate = '$(date)';" > lib/deploy_info.dart
```

### Option 3: Environment Variable

Set an environment variable during deployment:

```bash
export DEPLOY_DATE=$(date)
flutter build web --dart-define=deploy_date=$DEPLOY_DATE
```

Then access it in your app:

```dart
const deployDate = String.fromEnvironment('deploy_date', defaultValue: 'Unknown');
```

## Current Implementation

The current implementation uses **Option 1** (Firestore) which:

- ✅ Works across all platforms
- ✅ Updates automatically when you run the script
- ✅ Persists across app restarts
- ✅ Handles errors gracefully
- ✅ Shows loading state while fetching

The deployment date will appear in the Settings page under the "General" section.
