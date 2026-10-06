import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ग्रे स्क्रीन को रोकने के लिए: अगर कोई भी एरर आए तो स्क्रीन पर लाल बॉक्स में एरर दिखेगा
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Text(
              '⚠️ App Error:\n\n${details.exceptionAsString()}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  };

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
    return const MaterialApp(
      title: 'Vika Toons',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
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
          // Global Notice Box
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.2),
              border: Border.all(color: const Color(0xFF6366F1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome to Vika Toons 🔥', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF818CF8))),
                SizedBox(height: 4),
                Text('Watch your favorite anime in Hindi and English.', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          
          const Text('All Anime Catalog 🔥', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),

          // Firebase Stream with Fallback
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('anime').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: Color(0xFFF97316)),
                  ),
                );
              }

              // अगर Firebase से डेटा नहीं मिला या Firestore कनेक्ट नहीं हुआ, तो डेमो कार्ड दिखाओ
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildDemoCard(context);
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
                  return _buildAnimeTile(context, animeId, anime);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  static Widget _buildDemoCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PlayerScreen(
              episodeTitle: 'Demo: Big Buck Bunny',
              videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF12141C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF97316)),
        ),
        child: const Column(
          children: [
            Icon(Icons.play_circle_outline, size: 50, color: Color(0xFFF97316)),
            SizedBox(height: 10),
            Text('Demo Video Player Test', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 6),
            Text('Firestore abhi connect nahi hai. Player test karne ke liye yahan tap karein.', 
              style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  static Widget _buildAnimeTile(BuildContext context, String animeId, Map<String, dynamic> anime) {
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
                anime['title'] ?? 'Unknown Anime',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
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
      appBar: AppBar(title: Text(animeData['title'] ?? 'Episodes'), backgroundColor: const Color(0xFF12141C)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(animeData['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(animeData['description'] ?? 'No Synopsis Available', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final String episodeTitle;
  final String videoUrl;

  const PlayerScreen({super.key, required this.episodeTitle, required this.videoUrl});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() => _isLoading = false);
        _controller!.play();
      }).catchError((e) {
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
      body: Center(
        child: Container(
          height: 240,
          color: Colors.black,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)))
              : (_controller != null && _controller!.value.isInitialized)
                  ? AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!))
                  : const Center(child: Text('Video load nahi hua.', style: TextStyle(color: Colors.red))),
        ),
      ),
    );
  }
}
