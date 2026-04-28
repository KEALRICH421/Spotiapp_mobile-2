import 'dart:convert';
import 'package:http/http.dart' as http;

class SpotifyService {
  // Keys
  static const String _clientId = 'f9567f692e764b6a8ac2b400da2cca28';
  static const String _clientSecret = '864b642cab114fe58fb5988b2b15d041';

  static const String _baseUrl = 'https://api.spotify.com/v1';
  static const String _tokenUrl = 'https://accounts.spotify.com/api/token';

  String? _accessToken;
  DateTime? _tokenExpiry;

  // ── Singleton ──────────────────────────────────────────
  static final SpotifyService _instance = SpotifyService._internal();
  factory SpotifyService() => _instance;
  SpotifyService._internal();

  // ── Autenticación: Client Credentials Flow ─────────────
  Future<void> _authenticate() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return;
    }

    final credentials = base64Encode(
      utf8.encode('$_clientId:$_clientSecret'),
    );

    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      _tokenExpiry = DateTime.now().add(
        Duration(seconds: data['expires_in']),
      );
      print('✅ TOKEN: $_accessToken');
      print('⏱ EXPIRA: $_tokenExpiry');
    } else {
      print('❌ AUTH FAILED: ${response.body}');
      throw Exception('Error de autenticación: ${response.body}');
    }
  }

  // ── Headers reutilizables ──────────────────────────────
  Future<Map<String, String>> _getHeaders() async {
    await _authenticate();
    return {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
    };
  }

 
// ── Nuevos Lanzamientos ────────────────────────────────
Future<Map<String, dynamic>> getNewReleases({int limit = 20}) async {
  final headers = await _getHeaders();

  // Usamos search con nuevos álbumes — compatible con apps nuevas
  final response = await http.get(
   Uri.parse('$_baseUrl/search?q=tag:new&type=album&limit=10'),
    headers: headers,
  );

  print('🎵 STATUS RELEASES: ${response.statusCode}');
  print('📦 BODY: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Error al obtener lanzamientos: ${response.body}');
  }
}

  // ── Búsqueda de Artistas ───────────────────────────────
  // ── Búsqueda de Artistas ───────────────────────────────
Future<Map<String, dynamic>> getArtistas(String termino) async {
  final headers = await _getHeaders();
  final query = Uri.encodeComponent(termino.trim());

  final response = await http.get(
    Uri.parse('$_baseUrl/search?q=$query&type=artist&limit=10&market=US'),
    headers: headers,
  );

  print('🔍 STATUS SEARCH: ${response.statusCode}');
  print('📦 BODY SEARCH: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Error en búsqueda: ${response.body}');
  }
}
  // ── Top Tracks de un Artista ───────────────────────────
  // ── Top Tracks de un Artista ───────────────────────────
Future<Map<String, dynamic>> getTopTracks(String artistId) async {
  final headers = await _getHeaders();

  // Primero obtenemos el nombre del artista
  final artistResponse = await http.get(
    Uri.parse('$_baseUrl/artists/$artistId'),
    headers: headers,
  );

  print('👤 STATUS ARTIST: ${artistResponse.statusCode}');

  String artistName = artistId; // fallback

  if (artistResponse.statusCode == 200) {
    final artistData = jsonDecode(artistResponse.body);
    artistName = artistData['name'];
    print('👤 ARTIST NAME: $artistName');
  }

  // Buscamos tracks por nombre del artista
  final query = Uri.encodeComponent(artistName);
  final response = await http.get(
    Uri.parse('$_baseUrl/search?q=artist:"$query"&type=track&limit=10'),
    headers: headers,
  );

  print('🎤 STATUS TOP TRACKS: ${response.statusCode}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final tracks = data['tracks']['items'] as List;
    return {'tracks': tracks};
  } else {
    throw Exception('Error al obtener top tracks: ${response.body}');
  }
  }
}
