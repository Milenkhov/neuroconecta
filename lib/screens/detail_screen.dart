import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../src/models/capsula.dart';
import '../src/state/capsulas_state.dart';
import '../src/state/auth_state.dart';
import '../src/services/user_repository.dart';
import '../src/services/capsula_repository.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final capsula = ModalRoute.of(context)?.settings.arguments as Capsula?;
    if (capsula == null) {
      return const Scaffold(body: Center(child: Text('Cápsula no encontrada')));
    }
    final state = context.watch<CapsulasState>();
    final auth = context.watch<AuthState>();
    final userRepo = UserRepository();
    final repo = CapsulaRepository();
    final fav = state.isFavorite(capsula.id);
    return Scaffold(
      appBar: AppBar(title: Text(capsula.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? Colors.red : null),
                  onPressed: () => state.toggleFavorite(capsula.id),
                ),
                Expanded(
                  child: StreamBuilder<double>(
                    stream: repo.watchRatingAverage(capsula.id),
                    builder: (context, snap) {
                      final avg = (snap.data ?? 0).toStringAsFixed(1);
                      return Text('Rating: $avg ⭐');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(capsula.description),
            const SizedBox(height: 16),
            if (capsula.videoUrl != null && capsula.videoUrl!.isNotEmpty)
              VideoCapsulaPlayer(
                videoUrl: capsula.videoUrl!,
                onFirstPlay: () async {
                  // Soft gating: allow playback but notify if quota exceeded
                  final can = (await userRepo.canViewMore()) || auth.profile?.subscription == 'premium';
                  if (!can && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Has alcanzado el límite gratuito de vistas.')),
                    );
                  } else {
                    await userRepo.incrementViewCount();
                  }
                },
              ),
            const SizedBox(height: 16),
            Text('Adjuntos', style: Theme.of(context).textTheme.titleMedium),
            ...capsula.attachments.map(
              (a) => ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text(a),
                onTap: () async {
                  final uri = Uri.tryParse(a);
                  if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
                    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No se pudo abrir el adjunto')),
                        );
                      }
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Adjunto sin URL válida')),
                      );
                    }
                  }
                },
              ),
            ),
            const Divider(),
            Text('Calificar', style: Theme.of(context).textTheme.titleMedium),
            if (auth.isLoggedIn)
              RatingBar(capsulaId: capsula.id)
            else
              const Text('Inicia sesión para calificar'),
            const SizedBox(height: 24),
            Text('Comentarios', style: Theme.of(context).textTheme.titleMedium),
            CommentsSection(capsulaId: capsula.id),
          ],
        ),
      ),
    );
  }
}

class VideoCapsulaPlayer extends StatefulWidget {
  final String videoUrl;
  final Future<void> Function() onFirstPlay;
  const VideoCapsulaPlayer({super.key, required this.videoUrl, required this.onFirstPlay});

  @override
  State<VideoCapsulaPlayer> createState() => _VideoCapsulaPlayerState();
}

class _VideoCapsulaPlayerState extends State<VideoCapsulaPlayer> {
  VideoPlayerController? _controller;
  YoutubePlayerController? _yt;
  bool _initialized = false;
  bool _playedOnce = false;
  bool _ytPlaying = false;

  @override
  void initState() {
    super.initState();
    if (_isYouTube(widget.videoUrl)) {
      final id = _extractYouTubeId(widget.videoUrl);
      _yt = YoutubePlayerController(
        params: const YoutubePlayerParams(
          mute: false,
          showFullscreenButton: true,
          showControls: true,
        ),
      )..loadVideoById(videoId: id ?? '');
      _initialized = true;
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          if (mounted) setState(() => _initialized = true);
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _yt?.close();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (!_initialized) return;
    if (_yt != null) {
      if (_ytPlaying) {
        _yt!.pauseVideo();
        _ytPlaying = false;
      } else {
        if (!_playedOnce) {
          _playedOnce = true;
          await widget.onFirstPlay();
        }
        _yt!.playVideo();
        _ytPlaying = true;
      }
      if (mounted) setState(() {});
      return;
    }
    if (_controller != null) {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        if (!_playedOnce) {
          _playedOnce = true;
          await widget.onFirstPlay();
        }
        _controller!.play();
      }
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_yt != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: YoutubePlayer(controller: _yt!),
            )
          else
            AspectRatio(
              aspectRatio: _initialized && _controller != null ? _controller!.value.aspectRatio : 16 / 9,
              child: _initialized && _controller != null
                  ? VideoPlayer(_controller!)
                  : Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator())),
            ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Column(
              children: [
                if (_controller != null)
                  VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Theme.of(context).colorScheme.primary,
                      backgroundColor: Colors.white24,
                      bufferedColor: Colors.white54,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _togglePlay,
            child: AnimatedOpacity(
              opacity: _isPlaying ? 0.3 : 0.9,
              duration: const Duration(milliseconds: 200),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: Colors.black45,
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 42,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isPlaying {
    if (_yt != null) return _ytPlaying;
    return _controller?.value.isPlaying ?? false;
  }

  bool _isYouTube(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return false;
    final host = u.host.toLowerCase();
    return host.contains('youtube.com') || host.contains('youtu.be');
  }

  String? _extractYouTubeId(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return null;
    if (u.host.contains('youtu.be')) {
      return u.pathSegments.isNotEmpty ? u.pathSegments.first : null;
    }
    if (u.host.contains('youtube.com')) {
      if (u.pathSegments.contains('shorts') && u.pathSegments.length >= 2) {
        return u.pathSegments[1];
      }
      return u.queryParameters['v'];
    }
    return null;
  }
}

class RatingBar extends StatefulWidget {
  final String capsulaId;
  const RatingBar({super.key, required this.capsulaId});

  @override
  State<RatingBar> createState() => _RatingBarState();
}

class _RatingBarState extends State<RatingBar> {
  int _hover = 0;
  int _selected = 0;
  final repo = CapsulaRepository();

  @override
  void initState() {
    super.initState();
    // Watch user's rating to show persisted value
    repo.watchUserRating(widget.capsulaId).listen((stars) {
      if (mounted) setState(() => _selected = stars);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final starIndex = i + 1;
        final filled = starIndex <= (_hover > 0 ? _hover : _selected);
        return GestureDetector(
          onTap: () async {
            setState(() => _selected = starIndex);
            await repo.setRating(widget.capsulaId, starIndex);
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _hover = starIndex),
            onExit: (_) => setState(() => _hover = 0),
            child: Icon(filled ? Icons.star : Icons.star_border, color: Colors.amber),
          ),
        );
      }),
    );
  }
}

class CommentsSection extends StatefulWidget {
  final String capsulaId;
  const CommentsSection({super.key, required this.capsulaId});
  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _ctrl = TextEditingController();
  late final CollectionReference<Map<String, dynamic>> _comments =
      FirebaseFirestore.instance.collection('comments');

  Future<void> _submit() async {
    final auth = context.read<AuthState>();
    final text = _ctrl.text.trim();
    if (text.isEmpty || !auth.isLoggedIn) return;
    try {
      await _comments.add({
        'capsulaId': widget.capsulaId,
        'userId': auth.user!.uid,
        'email': auth.user!.email,
        'displayName': auth.user!.displayName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'subscription': auth.profile?.subscription,
      });
      _ctrl.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al comentar')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (auth.isLoggedIn)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(hintText: 'Escribe tu comentario'),
                ),
              ),
              IconButton(onPressed: _submit, icon: const Icon(Icons.send))
            ],
          )
        else
          const Text('Inicia sesión para dejar comentarios'),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _comments
              .where('capsulaId', isEqualTo: widget.capsulaId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              );
            }
            final docs = snap.data?.docs ?? const [];
            if (docs.isEmpty) return const Text('Sin comentarios');
            return Column(
              children: docs
                  .map((d) => ListTile(
                        leading: const Icon(Icons.comment),
                        title: Text(d['text'] ?? ''),
                        subtitle: Text(_subtitleFor(d)),
                        trailing: _canDelete(auth, d)
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  try {
                                    await d.reference.delete();
                                  } catch (_) {}
                                },
                              )
                            : null,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  bool _canDelete(AuthState auth, QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final uid = auth.user?.uid;
    final role = auth.profile?.role;
    return uid != null && (d['userId'] == uid || role == 'admin');
  }

  String _subtitleFor(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final created = (d['createdAt'] is Timestamp) ? (d['createdAt'] as Timestamp).toDate().toLocal() : null;
    final email = d.data()['email'] as String?;
    final name = d.data()['displayName'] as String?;
    final who = name?.isNotEmpty == true ? name : (email ?? 'Usuario');
    final when = created != null ? created.toString() : '';
    return '$who • $when';
  }
}