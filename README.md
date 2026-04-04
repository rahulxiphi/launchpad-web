# LaunchPad Web

Flutter web frontend for the LaunchPad voice pipeline demo.

## Prerequisites

- Flutter SDK 3.x (with web support enabled)
- Chrome (recommended for local web testing)
- LaunchPad API running locally on `http://localhost:8000`

## 1) Install Dependencies

From `finance-app/launchpad-web`:

```powershell
flutter pub get
```

## 2) Verify API Base URL

The frontend currently calls:

- `http://localhost:8000/api/v1/conversations/voice-token`

This is configured in `lib/config/api_config.dart`.

If your API is on another host/port, update `ApiConfig.baseUrl` in `lib/config/api_config.dart`.

## 3) Run the App (Web)

```powershell
flutter run -d chrome --web-port 3000
```

Then open:

- `http://localhost:3000`

## Build for Production

```powershell
flutter build web
```

Build output is generated in `build/web`.

## Troubleshooting

- If voice token calls fail, make sure the API is running and CORS allows your web origin.
- If Flutter web fails to start, run:

```powershell
flutter doctor
```
