# NeuroConecta – Guía en Español

Aplicación Flutter con Firebase (Auth + Firestore), biblioteca con búsqueda en vivo, favoritos, calificaciones, comentarios, y reproducción de video (YouTube + MP4). A continuación encontrarás cómo configurar, ejecutar, y construir el APK/AAB.

## 1) Crear el proyecto en Firebase
- Ve a https://console.firebase.google.com/
- Crea un proyecto llamado `NeuroConecta` (o el nombre que prefieras).

## 2) Agregar la app de Android
- Elige el ícono de Android para agregar una app.
- Nombre del paquete (package name): `com.example.neuroconecta`
- Apodo de la app: opcional.
- SHA‑1 de debug (ejemplo): `2E:52:51:D5:F1:3F:53:39:5D:0A:13:68:AF:60:C8:2C:AA:49:BC:6C`
  - Para regenerarla: `cd android` y luego `gradlew.bat signingReport`.
- Registra la app → descarga `google-services.json`.
- Coloca el archivo en `android/app/google-services.json` (ruta exacta).

## 3) Proveedores de inicio de sesión
- En Firebase Console → Authentication → Sign-in method → Habilita `Google`.
- Agrega tu SHA‑1 si aún no aparece (Project settings → Your apps → Android → Add fingerprint).

## 4) Base de datos Firestore
- Firebase Console → Firestore Database → Create database → Inicia en **modo de prueba** para prototipos.
- Región: la más cercana a tus usuarios.

## 5) Ejecutar la app (Android)
```powershell
cd d:\BACKUP-WIN10-VSPROJECTS\MOBILE\neuroconecta
flutter clean
flutter pub get
flutter run -d emulator-5554
```

Si `Firebase.initializeApp()` funciona, el inicio de sesión con Google completará y te llevará a Inicio; el CRUD operará sobre la colección `capsulas`.

## 6) Compilar APK y AAB (release)
```powershell
flutter build apk --release
flutter build appbundle
```
Los artefactos de salida quedan en:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

> Nota: También se copiaron a `export/neuroconecta-release.apk` y `export/neuroconecta-release.aab` para fácil acceso.

## Notas
- Ya está integrado el plugin de Google Services y se ocultó el banner de debug.
- Para publicar en Play Store, usa el AAB, configura la firma (keystore) y la Play Console.
- En emulador puede verse “Lost connection to device”; suele ser ambiental.
