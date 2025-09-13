### Flutter + PHP push notifications (FCM)

Directories
- `backend/`: PHP endpoint `send_push.php` (FCM legacy key)
- `flutter_app/`: Minimal Flutter app with FCM and local notifications

Setup backend
1) Copy `backend/.env.example` to `backend/.env` and set `FCM_SERVER_KEY`
2) Start server: `php -S 0.0.0.0:8080 -t backend`

Setup Flutter
1) Add Firebase app to your project and download configs
   - Android: place `google-services.json` in `android/app/`
   - iOS: place `GoogleService-Info.plist` in `ios/Runner/`
2) From `flutter_app/`: `flutter pub get` then `flutter run`
3) In the app, tap "Send test push"

Notes
- Android emulator uses `10.0.2.2` to reach host machine
- iOS simulator uses `localhost`

