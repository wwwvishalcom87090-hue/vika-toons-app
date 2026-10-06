import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  runApp(const VikaToonsApp());
}

class VikaToonsApp extends StatelessWidget {
  const VikaToonsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vika Toons',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        title: const Text('⚡ VIKA TOONS', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
        backgroundColor: const Color(0xFF12141C),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('app_settings').doc('global_notice').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                var data = snapshot.data!.data();
                if (data != null && data is Map<String, dynamic>) {
                  if (data['enabled'] == true) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                        border: Border.all(color: const Color(0xFF6366F1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['title'] ?? 'Notice', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF818CF8))),
                          const SizedBox(height: 4),
                          Text(data['message'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    );
                  }
                }
              }
              return const SizedBox.shrink();
            },
          ),
          const Text('All Anime Catalog 🔥', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('anime').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Color(0xFFF97316)),
                ));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Database connect hone me samasya: ${snapshot.error}', style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Koi Anime nahi mila. Admin panel se jodein!', style: TextStyle(color: Colors.white70)),
                  ),
                );
              }

              final animeList = snapshot.data!.docs;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: animeList.length,
                itemBuilder: (context, index) {
                  var anime = animeList[index].data() as Map<String, dynamic>;
                  String animeId = animeList[index].id;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EpisodeListScreen(animeId: animeId, animeData: anime),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF12141C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1F2330)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: (anime['poster'] != null && anime['poster'].toString().isNotEmpty)
                                  ? Image.network(
                                      anime['poster'],
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                    )
                                  : const Center(child: Icon(Icons.movie, color: Colors.grey)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              anime['title'] ?? 'Unknown',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFF1F2330), borderRadius: BorderRadius.circular(4)),
                                  child: Text(anime['audio'] ?? 'Sub', style: const TextStyle(fontSize: 10, color: Color(0xFFF97316))),
                                ),
                                const SizedBox(width: 6),
                                Text(anime['type'] ?? 'TV', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class EpisodeListScreen extends StatelessWidget {
  final String animeId;
  final Map<String, dynamic> animeData;

  const EpisodeListScreen({super.key, required this.animeId, required this.animeData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        title: Text(animeData['title'] ?? 'Episodes'),
        backgroundColor: const Color(0xFF12141C),
      ),
      body: ListView(
        children: [
          if (animeData['banner'] != null && animeData['banner'].toString().isNotEmpty)
            Image.network(
              animeData['banner'],
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(animeData['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text(animeData['description'] ?? 'No Synopsis Available', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF1F2330)),
                const Text('Episodes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('anime').doc(animeId).collection('episodes').orderBy('episodeNumber').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Is Anime ke liye koi episode nahi mila.', style: TextStyle(color: Colors.grey)),
                );
              }

              final episodes = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: episodes.length,
                itemBuilder: (context, index) {
                  var ep = episodes[index].data() as Map<String, dynamic>;
                  var servers = ep['servers'] ?? {};

                  return ListTile(
                    leading: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(color: const Color(0xFF12141C), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text('${ep['episodeNumber'] ?? index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF97316)))),
                    ),
                    title: Text(ep['title'] ?? 'Episode ${ep['episodeNumber'] ?? index + 1}', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Season ${ep['seasonNumber'] ?? 1}', style: const TextStyle(color: Colors.grey)),
                    trailing: const Icon(Icons.play_circle_fill, color: Color(0xFFF97316), size: 32),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerScreen(
                            episodeTitle: ep['title'] ?? 'Episode ${ep['episodeNumber'] ?? index + 1}',
                            servers: servers,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final String episodeTitle;
  final Map<dynamic, dynamic> servers;

  const PlayerScreen({super.key, required this.episodeTitle, required this.servers});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  String currentServerKey = 'server1';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startPlaying(widget.servers['server1'] ?? '');
  }

  void _startPlaying(String url) {
    if (url.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    _controller?.dispose();
    setState(() => _isLoading = true);

    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {
          _isLoading = false;
        });
        _controller!.play();
      }).catchError((error) {
        setState(() => _isLoading = false);
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(title: Text(widget.episodeTitle), backgroundColor: const Color(0xFF12141C)),
      body: Column(
        children: [
          Container(
            height: 220,
            width: double.infinity,
            color: Colors.black,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)))
                : (_controller != null && _controller!.value.isInitialized)
                    ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      )
                    : const Center(child: Text('Video load nahi hua. Server badlein.', style: TextStyle(color: Colors.red))),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Stream Server:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (widget.servers['server1'] != null && widget.servers['server1'].toString().isNotEmpty)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentServerKey == 'server1' ? const Color(0xFFF97316) : const Color(0xFF1F2330),
                        ),
                        onPressed: () {
                          setState(() => currentServerKey = 'server1');
                          _startPlaying(widget.servers['server1']);
                        },
                        child: const Text('Server 1', style: TextStyle(color: Colors.white)),
                      ),
                    const SizedBox(width: 8),
                    if (widget.servers['server2'] != null && widget.servers['server2'].toString().isNotEmpty)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentServerKey == 'server2' ? const Color(0xFFF97316) : const Color(0xFF1F2330),
                        ),
                        onPressed: () {
                          setState(() => currentServerKey = 'server2');
                          _startPlaying(widget.servers['server2']);
                        },
                        child: const Text('Server 2', style: TextStyle(color: Colors.white)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
