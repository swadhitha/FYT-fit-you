# FYT (Fit-You) Flutter App

A Flutter mobile application that provides AI-powered fashion styling and wardrobe management.

## Getting Started

To get started with this project, ensure you have Flutter installed on your machine. You can follow the official Flutter installation guide [here](https://flutter.dev/docs/get-started/install).

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or VS Code with Flutter extension
- Android SDK (API Level 23+)
- Physical Android device or Android Emulator

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/your_username/FYT-fit-you.git
   ```
2. Navigate to the project directory:
   ```
   cd FYT-fit-you
   ```
3. Install the dependencies:
   ```
   flutter pub get
   ```

### Running the App

This app targets Android only (minSdk 23). To run on an Android device or emulator:

```bash
flutter run -d android
```

Or to run on a specific device:
```bash
flutter devices
flutter run -d <device_id>
```

**Note:** Do not run on Chrome/web as this app is Android-only and may throw Firebase JavaScript errors.

### Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com
2. Add an Android app to your Firebase project
3. Download `google-services.json` and place it in `android/app/`
4. Update `lib/config/api_keys.dart` with your Mistral AI API key

### Project Structure

- `lib/`: Contains the main application code
  - `main.dart`: Entry point with Firebase initialization
  - `app.dart`: Main application widget
  - `config/`: Configuration files (API keys)
  - `design/`: Design system (colors, typography, theme)
  - `models/`: Data models (User, WardrobeItem, BodyProfile)
  - `providers/`: State management (Auth, Wardrobe, UserProfile)
  - `routing/`: Navigation routes and router
  - `screens/`: UI screens (Auth, Home, Wardrobe, etc.)
  - `services/`: Business logic (Firebase, Storage, Auth)
  - `widgets/`: Reusable UI components
- `android/`: Android-specific configuration
- `test/`: Contains widget tests
- `pubspec.yaml`: Project configuration and dependencies

### Features

- **User Authentication**: Firebase Auth with email/password
- **Body Blueprint**: ML Kit pose detection for measurements
- **Smart Closet**: Digital wardrobe management
- **AI Stylist Chat**: Mistral AI for fashion advice
- **Occasion Mode**: Event-based outfit recommendations
- **Profile Management**: User preferences and settings

### Error Handling

The app includes comprehensive error handling:
- Firebase initialization with graceful fallback
- User-friendly error messages for all Firebase operations
- Provider-level error state management
- Proper exception handling in all services

### Contributing

Feel free to submit issues or pull requests for improvements or bug fixes.

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.