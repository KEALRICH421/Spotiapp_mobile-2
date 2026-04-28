import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../services/spotify_service.dart';

class ArtistPage extends StatefulWidget {
  final String artistId;
  const ArtistPage({super.key, required this.artistId});

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  final SpotifyService _spotifyService = SpotifyService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Map<String, dynamic>? _artist;
  List<dynamic> _topTracks = [];
  bool _isLoading = true;
  String? _error;
  String? _playingTrackId;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadArtistData();
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _playingTrackId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadArtistData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tracksData = await _spotifyService.getTopTracks(widget.artistId);
      final tracks = tracksData['tracks'] as List;

      setState(() {
        _topTracks = tracks.take(10).toList();

        for (var t in _topTracks) {
          print('🎵 ${t['name']} — preview: ${t['preview_url']}');
        }

        if (_topTracks.isNotEmpty) {
          final artists = _topTracks[0]['artists'] as List;
          _artist = artists.firstWhere(
            (a) => a['id'] == widget.artistId,
            orElse: () => artists[0],
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePlay(String trackId, String? previewUrl) async {
    final track = _topTracks.firstWhere((t) => t['id'] == trackId);
    final spotifyUrl = track['external_urls']?['spotify'];

    if (previewUrl != null) {
      // Si hay preview, reproducimos
      try {
        if (_playingTrackId == trackId && _isPlaying) {
          await _audioPlayer.pause();
          setState(() => _isPlaying = false);
        } else {
          await _audioPlayer.stop();
          await _audioPlayer.setUrl(previewUrl);
          await _audioPlayer.play();
          setState(() {
            _playingTrackId = trackId;
            _isPlaying = true;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de reproducción: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (spotifyUrl != null) {
      // Si no hay preview, mostramos link de Spotify
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.open_in_new, color: Colors.black, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Escuchar en Spotify: ${track['name']}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1DB954),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vista previa no disponible'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String? _getArtistImage() {
    if (_topTracks.isEmpty) return null;
    final images = _topTracks[0]['album']?['images'] as List?;
    if (images == null || images.isEmpty) return null;
    return images[0]['url'];
  }

  String _formatDuration(int ms) {
    final minutes = (ms / 60000).floor();
    final seconds = ((ms % 60000) / 1000).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1DB954)),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!),
                      TextButton(
                        onPressed: _loadArtistData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final imageUrl = _getArtistImage();
    final artistName = _artist?['name'] ?? 'Artista';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: const Color(0xFF121212),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              artistName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            background: imageUrl != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1DB954),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _noImageHeader(),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0xFF121212),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : _noImageHeader(),
          ),
        ),

        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Top Canciones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final track = _topTracks[index];
              final trackId = track['id'];
              final previewUrl = track['preview_url'];
              final trackName = track['name'] ?? 'Sin nombre';
              final duration = track['duration_ms'] ?? 0;
              final albumName = track['album']?['name'] ?? '';
              final isCurrentlyPlaying =
                  _playingTrackId == trackId && _isPlaying;

              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isCurrentlyPlaying
                      ? const Color(0xFF1DB954).withOpacity(0.15)
                      : const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrentlyPlaying
                        ? const Color(0xFF1DB954)
                        : const Color(0xFF535353),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrentlyPlaying
                            ? Colors.black
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    trackName,
                    style: TextStyle(
                      color: isCurrentlyPlaying
                          ? const Color(0xFF1DB954)
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    albumName,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          isCurrentlyPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: isCurrentlyPlaying
                              ? const Color(0xFF1DB954)
                              : const Color(0xFF1DB954),
                          size: 32,
                        ),
                        onPressed: () => _togglePlay(trackId, previewUrl),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: _topTracks.length,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _noImageHeader() {
    return Container(
      color: const Color(0xFF282828),
      child: const Center(
        child: Icon(Icons.person, color: Colors.grey, size: 80),
      ),
    );
  }
}