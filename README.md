# 🎵 Spotiapp Mobile

Aplicación móvil desarrollada con **Flutter** que consume la API de Spotify para mostrar nuevos lanzamientos musicales, buscar artistas y visualizar sus canciones más populares.

---

## 📱 Capturas de Pantalla

| Home | Búsqueda | Detalle Artista |
|------|----------|-----------------|
| Grid de nuevos lanzamientos | Búsqueda en tiempo real | Top canciones del artista |

---

## 🚀 Funcionalidades

- **Home Page**: Grid de álbumes y lanzamientos recientes obtenidos desde la API de Spotify.
- **Search Page**: Búsqueda de artistas en tiempo real mientras el usuario escribe.
- **Artist Page**: Detalle del artista con header animado y listado de sus 10 canciones más populares.
- **Navegación**: Bottom Navigation Bar con transiciones entre pantallas.
- **Manejo de errores**: Estados de carga, error y vacío en todas las pantallas.
- **Imagen por defecto**: Validación de imágenes nulas con widget de reemplazo.

---

## 🛠️ Tecnologías y Dependencias

| Paquete | Versión | Uso |
|---------|---------|-----|
| `http` | ^1.2.1 | Peticiones HTTP a la API de Spotify |
| `cached_network_image` | ^3.3.1 | Carga y caché de imágenes |
| `just_audio` | ^0.9.36 | Reproducción de audio |
| `provider` | ^6.1.2 | Manejo de estado |

---

## 📁 Arquitectura del Proyecto

```
lib/
├── main.dart                  # Punto de entrada y configuración del tema
├── services/
│   └── spotify_service.dart   # Servicio HTTP con autenticación y endpoints
├── models/
│   ├── new_releases_response.dart
│   └── artist_search_response.dart
├── pages/
│   ├── home_page.dart         # Pantalla principal con GridView
│   ├── search_page.dart       # Búsqueda de artistas
│   └── artist_page.dart       # Detalle del artista y top tracks
└── widgets/
    └── artist_card.dart       # Widget reutilizable
```

---

## ⚙️ Configuración y Ejecución

### Prerrequisitos

- Flutter SDK >= 3.0.0
- Dart >= 3.0.0
- Android Studio o VS Code
- Cuenta de desarrollador en [Spotify for Developers](https://developer.spotify.com)

### 1. Clonar el repositorio

```bash
git clone https://github.com/ImKevinL/spotiapp_mobile.git
cd spotiapp_mobile
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar credenciales de Spotify

En `lib/services/spotify_service.dart` reemplaza con tus credenciales:

```dart
static const String _clientId = 'TU_CLIENT_ID';
static const String _clientSecret = 'TU_CLIENT_SECRET';
```

> ⚠️ **Importante:** Nunca subas tus credenciales reales a un repositorio público. Usa variables de entorno en producción.

### 4. Ejecutar la aplicación

```bash
# En emulador Android
flutter run -d emulator-5554

# En Chrome (web)
flutter run -d chrome
```

---

## 🔐 Autenticación con Spotify

Se implementó el flujo **Client Credentials** de OAuth 2.0:

1. Se codifican `clientId:clientSecret` en Base64.
2. Se hace un POST a `https://accounts.spotify.com/api/token`.
3. El token obtenido se cachea y se renueva automáticamente cada 60 minutos.

```dart
final credentials = base64Encode(utf8.encode('$_clientId:$_clientSecret'));
// POST a /api/token con grant_type=client_credentials
```

---

## 🌐 Endpoints Utilizados

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `getNewReleases()` | `/search?q=tag:new&type=album` | Álbumes recientes* |
| `getArtistas(termino)` | `/search?q={termino}&type=artist` | Búsqueda de artistas |
| `getTopTracks(artistId)` | `/artists/{id}` + `/search` | Top canciones del artista |

> *️⃣ **Nota técnica:** El endpoint original `/browse/new-releases` fue deprecado por Spotify en 2024 para aplicaciones nuevas. Se adaptó usando el endpoint `/search` con el filtro `tag:new`, obteniendo los mismos resultados de lanzamientos recientes.

---

## ⚠️ Limitaciones conocidas

### Preview de Audio
El campo `preview_url` fue eliminado por Spotify en 2024 para la mayoría de tracks en aplicaciones nuevas. Como alternativa, al presionar el botón de reproducción se muestra el enlace directo al track en Spotify (`external_urls.spotify`), permitiendo al usuario escuchar la canción completa en la app oficial.

### CORS en Web
La reproducción de audio con `just_audio` presenta restricciones de CORS en Chrome. Funciona correctamente en dispositivos Android e iOS.

---

## 👨‍💻 Autor

Desarrollado como parte del taller de Flutter — Consumo de APIs REST.

---

## 📄 Licencia

Este proyecto es de uso educativo.
