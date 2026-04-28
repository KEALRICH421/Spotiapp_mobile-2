import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/spotify_service.dart';
import 'artist_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SpotifyService _spotifyService = SpotifyService();
  List<dynamic> _releases = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNewReleases();
  }

  Future<void> _loadNewReleases() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _spotifyService.getNewReleases();
      setState(() {
        _releases = data['albums']['items'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SPOTIAPP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1DB954)),
            onPressed: _loadNewReleases,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1DB954)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNewReleases,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Destacados',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: _releases.length,
              itemBuilder: (context, index) {
                final album = _releases[index];
                return _AlbumCard(album: album);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final dynamic album;

  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    final imageUrl = album['images']?.isNotEmpty == true
        ? album['images'][0]['url']
        : null;
    final name = album['name'] ?? 'Sin nombre';
final description = (album['artists'] as List?)
        ?.map((a) => a['name'])
        .join(', ') ?? '';

    return GestureDetector(
      onTap: () {
  final artistId = (album['artists'] as List?)?.first['id'] ?? '';
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ArtistPage(artistId: artistId),
    ),
  );
},
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox(
                        height: 150,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1DB954),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _noImage(),
                    )
                  : _noImage(),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noImage() {
    return Container(
      height: 150,
      width: double.infinity,
      color: const Color(0xFF535353),
      child: const Icon(Icons.music_note, color: Colors.grey, size: 48),
    );
  }
}