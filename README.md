# PAGOYA (Flutter)

Pago móvil + QR. PAGOYA no es una billetera virtual: es una modalidad para facilitar cómo se recibe y envía dinero.

## Generar el APK (automático)
1. Crea un repositorio en GitHub y sube **todo** el contenido de esta carpeta (incluida `.github`).
2. En **Settings → Actions → General → Workflow permissions** marca **Read and write permissions** y guarda.
3. Cada push a `main` compila solo. También puedes ir a **Actions → Build APK (Flutter) → Run workflow**.
4. El APK queda en la pestaña **Releases** del repositorio (`PAGOYA.apk`) y también en *Artifacts* de la ejecución.

## Estructura
- `lib/main.dart`: app Flutter (WebView, botón atrás, barra de estado, compartir QR).
- `assets/www/index.html`: pantallas y lógica de PAGOYA.
- `assets/icon/`: ícono de la app.
- `.github/workflows/build-apk.yml`: genera `android/`, el ícono y compila.

## Notas
- Tailwind, lucide, QR y fuentes se cargan por internet.
- El APK está firmado con clave de depuración: sirve para instalar y probar, no para Play Store.
