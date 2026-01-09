# BC Transporter Mobile App

## Setup

1.  Make sure you have Flutter installed.
2.  Run `flutter pub get` in this directory.

## Configuration

The app connects to the running Node.js server to get its configuration.
See `lib/core/api_constants.dart` to change the `baseUrl`.
By default it points to `http://10.0.2.2:3000` which is localhost for the Android Emulator.

## Architecture

- **Clean Architecture** style structure.
- **MVVM** with `Provider` for state management.
- **Flutter Map** for the background map.
- **Glassmorphism** for the UI elements.

## Running

```bash
flutter run
```
