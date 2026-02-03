# Flutter Technician App - Setup Instructions

## Prerequisites
- Flutter SDK 3.x installed
- Dart 3.x
- Android Studio / VS Code with Flutter extensions

## Setup Steps

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Generate Code Files
The project uses code generation for:
- JSON serialization (json_serializable)
- Riverpod providers (riverpod_generator)
- Retrofit API clients (retrofit_generator)

Run the build runner:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Update Backend URL
Edit `lib/core/api/api_endpoints.dart` and update the `baseUrl` constant with your actual backend URL:
```dart
static const String baseUrl = 'https://your-actual-backend-url.com';
```

### 4. Run the App
```bash
flutter run
```

## Project Structure

The app follows a feature-first architecture:

- `lib/core/` - Core functionality (API, storage, theme, routing, utils)
- `lib/features/` - Feature modules (auth, dashboard, inventory, etc.)
- `lib/shared/` - Shared models and widgets

## Features Implemented

✅ Authentication (Login/Logout)
✅ Dashboard with stats
✅ Fixed Inventory management
✅ Moving Inventory management
✅ Warehouse Transfer accept/reject
✅ Submit Received Devices
✅ Notifications
✅ Profile screen

## Next Steps (Optional Enhancements)

- Excel export functionality
- Barcode scanner integration
- Offline caching improvements
- Pull-to-refresh on all screens
- Loading shimmer effects
- Unit and widget tests

## Notes

- The app uses RTL (Right-to-Left) layout for Arabic
- All text is in Arabic
- Uses Material 3 design
- State management with Riverpod 2.x
- Secure token storage with flutter_secure_storage
