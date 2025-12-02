# NeuroConecta – Android setup (manual Firebase)

Follow these steps to enable Google Auth + Firestore on Android.

## 1) Create the Firebase project
- Go to https://console.firebase.google.com/
- Click Add project → name it `NeuroConecta` → Continue.

## 2) Add the Android app
- Select Android icon to add an app.
- Android package name: `com.example.neuroconecta`
- App nickname: optional.
- Debug SHA‑1: `2E:52:51:D5:F1:3F:53:39:5D:0A:13:68:AF:60:C8:2C:AA:49:BC:6C`
	- If you need to re-generate: `cd android` then `gradlew.bat signingReport`.
- Register app → Download `google-services.json`.
- Place the file at `android/app/google-services.json` (exact path).

## 3) Enable Sign-in providers
- In Firebase Console → Authentication → Sign-in method → Enable `Google`.
- Add your SHA-1 above if not already present (Project settings → Your apps → Android → Add fingerprint).

## 4) Firestore database
- Firebase Console → Firestore Database → Create database → Start in **test mode** for prototyping.
- Region: pick closest to your users.

## 5) Run the app
```powershell
cd d:\BACKUP-WIN10-VSPROJECTS\MOBILE\neuroconecta
flutter clean
flutter pub get
flutter run -d emulator-5554
```

If `Firebase.initializeApp()` works, the Login button will complete and take you to Home; CRUD will operate on `capsulas` collection.

## Notes
- We already wired the Google Services Gradle plugin and hid the debug banner.
- For release builds you must create a release keystore and add its SHA‑1/256 to Firebase too.
