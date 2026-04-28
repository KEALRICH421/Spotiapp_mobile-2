import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/spotify_service.dart';
import 'artist_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SpotifyService _spotifyService = SpotifyService();
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _artistas = [];
  bool _isLoading = false;
  bool _searched = false;

  Future<void> _buscarArtistas(String termino) async {
    if (termino.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _searched = true;
    });

    try {
      final data = await _spotifyService.getArtistas(termino);
      setState(() {
        _artistas = data['artists']['items'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _getImageUrl(dynamic artist) {
    final images = artist['images'];
    if (images == null || images.isEmpty) return null;
    return images[0]['url'];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BUSCAR')),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar artista...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1DB954)),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _artistas = [];
                            _searched = false;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF282828),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _buscarArtistas,
              onChanged: (value) {
                setState(() {});
                if (value.trim().length >= 3) {
                  _buscarArtistas(value.trim());
                }
            },  ),    ),
          // Contenido
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1DB954)),
      );
    }

    if (!_searched) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text(
              'Busca tu artista favorito',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_artistas.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron artistas',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _artistas.length,
      itemBuilder: (context, index) {
        final artist = _artistas[index];
        final imageUrl = _getImageUrl(artist);
        final name = artist['name'] ?? 'Sin nombre';
        final followers = artist['followers']?['total'] ?? 0;
        final genres = (artist['genres'] as List?)?.take(2).join(', ') ?? '';

        return ListTile(
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF535353),
            backgroundImage:
                imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          title: Text(
            name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
  genres.isNotEmpty
      ? genres
      : 'Ver canciones', 
  style: const TextStyle(color: Colors.grey, fontSize: 12),
),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArtistPage(artistId: artist['id']),
              ),
            );
          },
        );
      },
    );
  }

  String _formatFollowers(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}