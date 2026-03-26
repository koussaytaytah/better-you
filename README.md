# Better You - Health & Lifestyle App

A comprehensive Flutter application for health and lifestyle improvement, featuring habit tracking, AI assistance, community interaction, and professional healthcare integration.

## Features

- **User Authentication**: Firebase Auth with role-based access (User, Coach, Doctor)
- **Habit Tracking**: Daily logging of smoking, alcohol, diet, and exercise
- **Statistics Dashboard**: Interactive charts showing progress over time
- **AI Assistant**: Hugging Face integration for health advice
- **Community Feed**: Social interaction with posts, comments, and likes
- **Chat System**: Global chat and private consultations
- **Progress Calendar**: Visual calendar showing habit streaks and achievements
- **Gamification**: Badges and streaks for motivation

## Technology Stack

- **Frontend**: Flutter with Dart
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **State Management**: Riverpod
- **Charts**: fl_chart
- **Fonts**: Google Fonts (Poppins)
- **AI**: Hugging Face API

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (3.11.1+)
- Firebase CLI
- Android Studio / VS Code
- iOS Simulator (for iOS development)

### 2. Firebase Setup

1. Create a new Firebase project at https://console.firebase.google.com/
2. Enable the following services:
   - Authentication
   - Firestore Database
   - Firebase Cloud Messaging
   - Firebase Storage

3. Add your Flutter app to Firebase:
   - For Android: Download `google-services.json` and place it in `android/app/`
   - For iOS: Download `GoogleService-Info.plist` and place it in `ios/Runner/`

4. Configure Firestore Security Rules (see `firestore.rules`)

### 3. Hugging Face Setup

1. Get an API token from https://huggingface.co/settings/tokens
2. Replace `YOUR_HUGGING_FACE_TOKEN` in `lib/core/constants/app_constants.dart`

### 4. Installation

```bash
# Clone the repository
git clone <repository-url>
cd better_you

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### 5. Build Configuration

For Android:
- Ensure `android/app/build.gradle` has the correct package name
- Configure signing for release builds

For iOS:
- Update bundle identifier in Xcode
- Configure push notifications capabilities

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── services/
│   └── utils/
├── models/
├── providers/
├── screens/
│   ├── auth/
│   ├── main/
│   └── onboarding/
└── widgets/
```

## Key Components

- **Clean Architecture**: Separation of concerns with clear layers
- **Riverpod**: Reactive state management
- **Firebase Integration**: Real-time data synchronization
- **Material Design**: Professional UI with custom theming
- **Responsive Design**: Works on mobile and tablet

## Development

### Running Tests
```bash
flutter test
```

### Building for Production
```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email [your-email] or create an issue in the repository.

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
