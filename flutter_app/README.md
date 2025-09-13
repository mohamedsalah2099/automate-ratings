### Flutter FCM demo (with PHP backend)

Steps
- Install Flutter SDK and Firebase CLI
- Create a Firebase project, enable Cloud Messaging
- Add Android and/or iOS apps to the project
- Download and place `google-services.json` under `android/app/` and `GoogleService-Info.plist` under `ios/Runner/`
- In Android, ensure `minSdkVersion` ≥ 21 and apply the Google Services Gradle plugin
- In iOS, enable Push Notifications capability and Background Modes → Remote notifications

Run backend
- Copy `backend/.env.example` to `backend/.env` and set `FCM_SERVER_KEY`
- Run: `php -S 0.0.0.0:8080 -t backend`

Run app
- From `flutter_app/`, run: `flutter pub get`
- Run on emulator or device: `flutter run`
- Tap "Send test push". Ensure the base URL matches your backend host

Notes
- Use `http://10.0.2.2:8080` on Android emulator for host machine localhost
- Use `http://localhost:8080` on iOS simulator
- Real devices need the machine IP, e.g., `http://192.168.1.10:8080`

