<p align="center">
  <img src="assets/icon/app_logo.png" width="120" alt="Logo de Bóveda">
</p>

<h1 align="center">Bóveda</h1>

<p align="center">
  Guarda los números de cuenta y datos que usas cada mes, y cópialos con un toque.
</p>

---

## ⬇️ Descargar

Descarga el APK desde la página de **[Releases](../../releases/latest)**:

| Archivo | Para quién |
|---|---|
| `Boveda-vX.Y.Z-arm64.apk` | La mayoría de celulares (2017 en adelante). **Recomendado.** |
| `Boveda-vX.Y.Z-armv7.apk` | Celulares antiguos de 32 bits. |
| `Boveda-vX.Y.Z-universal.apk` | Si no sabes cuál elegir (más pesado). |

Requiere **Android 7.0** o superior. Al instalar, Android pedirá permitir
«instalar apps de fuentes desconocidas» para tu navegador o administrador de archivos.

## ✨ Qué hace

- **Copia con un toque** los números de cuenta de luz, agua, gas, internet… para pegarlos en la app de tu banco.
- **Suscripciones** con correo y contraseña. La contraseña queda oculta y solo se ve o copia con huella o PIN.
- **Entrada protegida** con huella (o PIN de respaldo) cada vez que abres la app.
- Las contraseñas copiadas se **borran solas del portapapeles** a los 30 segundos.

## 🔒 Privacidad y seguridad

- Tus datos se guardan **solo en tu teléfono**, cifrados con el almacén seguro de Android (Keystore).
- La app **no tiene acceso a internet**, no usa servidores ni hace copias en la nube.
- Bloquea capturas de pantalla y oculta su contenido en «apps recientes».
- 5 intentos fallidos de PIN bloquean la app temporalmente (el tiempo aumenta con cada fallo).

> ⚠️ **Si desinstalas la app o borras sus datos, la información se pierde.**
> Si olvidas el PIN y la huella no funciona, no hay forma de recuperarla.

---

## 🛠️ Para desarrolladores

```bash
flutter pub get
flutter run
flutter test
```

### Publicar una nueva versión

1. Sube la versión en `pubspec.yaml` (ej. `version: 1.1.0+2`; el número tras `+` debe aumentar siempre).
2. Crea y sube la etiqueta con la misma versión:
   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   ```
3. GitHub Actions ([`.github/workflows/release.yml`](.github/workflows/release.yml)) compila, firma y publica los APK en Releases.

### Llave de firma

Los APK se firman con una llave propia que **nunca** se sube al repositorio.
En GitHub Actions se toma de estos secretos del repositorio:

| Secreto | Contenido |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | El archivo `.jks` codificado en base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Contraseña del keystore |
| `ANDROID_KEY_ALIAS` | Alias de la llave |
| `ANDROID_KEY_PASSWORD` | Contraseña de la llave |

Para compilar firmado en tu PC, crea `android/key.properties` (está en `.gitignore`):

```properties
storeFile=C:/ruta/fuera/del/repo/boveda-release.jks
storePassword=...
keyAlias=boveda
keyPassword=...
```

> Guarda una copia de respaldo del `.jks` y sus contraseñas. Si se pierde, no podrás
> publicar actualizaciones: Android solo instala una actualización firmada con la misma llave.

### Ícono

Generado desde [`assets/icon/logo_lagarrita.svg`](assets/icon/logo_lagarrita.svg).
Para regenerarlo: `dart run flutter_launcher_icons`.
