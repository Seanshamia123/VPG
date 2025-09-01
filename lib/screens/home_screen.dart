// import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
import 'package:escort/services/post_service.dart';
import 'package:escort/models/post.dart' as ModelPost;

import 'settings_screen.dart';
import 'terms_and_conditions_screen.dart';
import 'package:escort/services/advertiser_service.dart';
import 'package:escort/screens/advertisers_screens/advertiser_public_profile.dart';
import 'package:escort/services/messages_service.dart';
import 'package:escort/services/user_session.dart';
import 'package:escort/services/conversations_service.dart';
import 'package:escort/services/comments_service.dart';
import 'package:escort/screens/messages/chat_screen.dart';
import 'package:escort/services/post_likes_service.dart';
import 'package:escort/services/token_storage.dart';

// ---------- Models ----------
class UserProfile {
  String name;
  String username;
  String profileImageUrl;
  String location;

  UserProfile({
    required this.name,
    required this.username,
    required this.profileImageUrl,
    required this.location,
  });
}

// Minimal Post/Advertiser models to match your backend `/posts` shape
class FeedPost {
  final int id;
  final String imageUrl;
  final String? caption;
  final String? location; // optional UI field
  final FeedAdvertiser advertiser;
  final DateTime createdAt;
  final int likeCount;
  final bool likedByMe;

  FeedPost({
    required this.id,
    required this.imageUrl,
    required this.advertiser,
    required this.createdAt,
    this.caption,
    this.location,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: json['id'] as int,
      imageUrl: json['image_url'] as String,
      caption: json['caption'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      advertiser: FeedAdvertiser.fromJson(json['advertiser'] ?? const {}),
      location: json['location'] as String?,
      likeCount: int.tryParse('${json['likes_count'] ?? 0}') ?? 0,
      likedByMe: (json['liked_by_me'] as bool?) ?? false,
    );
  }
}

class FeedAdvertiser {
  final int id;
  final String name;
  final String username;
  final String? profileImage; // optional for avatar

  const FeedAdvertiser({
    required this.id,
    required this.name,
    required this.username,
    this.profileImage,
  });

  factory FeedAdvertiser.fromJson(Map<String, dynamic> json) {
    return FeedAdvertiser(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse('${json['id'] ?? 0}') ?? 0,
      name: (json['name'] as String?) ?? 'Unknown Advertiser',
      username: (json['username'] as String?) ?? 'unknown',
      profileImage: json['profile_image'] as String?,
    );
  }
}

// ---------- Advertiser model used on Location screen ----------
class Advertiser {
  final String name;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String distance;

  Advertiser({
    required this.name,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.distance,
  });
}

// ---------- App Shell ----------
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VipGalz',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
      routes: {'/messages': (context) => MessagesScreen()},
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}

// ---------- Main Screen with Bottom Nav ----------
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LocationScreen(), // Changed from ExploreScreen to LocationScreen
    MessagesScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),
    );
  }
}

// ---------- Location Screen ----------
class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  GoogleMapController? _controller;
  Position? _currentPosition;
  bool _isLoading = true;
  Set<Marker> _markers = {};

  // Demo advertisers
  late List<Advertiser> _advertisers = [
    Advertiser(
      name: 'Stacy Beauty',
      imageUrl:
          'https://images.unsplash.com/photo-1481214110143-ed630356e1bb?q=80&w=387&auto=format&fit=crop&ixlib=rb-4.1.0',
      latitude: 40.7589,
      longitude: -73.9851,
      distance: '0.5 km',
    ),
    Advertiser(
      name: 'Smith Fashion',
      imageUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face',
      latitude: 40.7614,
      longitude: -73.9776,
      distance: '1.2 km',
    ),
    Advertiser(
      name: 'Kriston Wellness',
      imageUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&h=100&fit=crop&crop=face',
      latitude: 40.7505,
      longitude: -73.9934,
      distance: '2.0 km',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadAdvertisers();
  }

  Future<void> _loadAdvertisers() async {
    try {
      final list = await AdvertiserService.fetchAdvertisers(
        page: 1,
        perPage: 20,
      );
      setState(() {
        _advertisers = list
            .map(
              (item) => Advertiser(
                name: item['name'] ?? '',
                imageUrl: item['imageUrl'] ?? '',
                latitude: item['latitude']?.toDouble() ?? 0.0,
                longitude: item['longitude']?.toDouble() ?? 0.0,
                distance: item['distance'] ?? '',
              ),
            )
            .toList();
      });
      _createMarkers();
    } catch (_) {
      // keep empty
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      _createMarkers();
    } catch (e) {
      // Fallback to Times Square
      setState(() {
        _currentPosition = Position(
          latitude: 40.7580,
          longitude: -73.9855,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        _isLoading = false;
      });
      _createMarkers();
    }
  }

  void _createMarkers() {
    final markers = <Marker>{};

    // User location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Add advertiser markers if latitude/longitude available
    for (int i = 0; i < _advertisers.length; i++) {
      final adv = _advertisers[i];
      final lat = adv.latitude;
      final lon = adv.longitude;
      if (lat != null && lon != null) {
        final name = adv.name;
        markers.add(
          Marker(
            markerId: MarkerId('adv_$i'),
            position: LatLng(lat, lon),
            infoWindow: InfoWindow(title: name, snippet: adv.distance),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueYellow,
            ),
          ),
        );
      }
    }

    setState(() => _markers = markers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nearby Advertisers',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.yellow),
            onPressed: () {
              if (_currentPosition != null && _controller != null) {
                _controller!.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
              ),
            )
          : Column(
              children: [
                // Map
                Expanded(
                  flex: 2,
                  child: GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _controller = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition != null
                          ? LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            )
                          : const LatLng(40.7580, -73.9855),
                      zoom: 14,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                  ),
                ),
                // Advertisers list
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.yellow),
                              SizedBox(width: 8),
                              Text(
                                'Nearby Advertisers',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _advertisers.length,
                            itemBuilder: (context, index) {
                              final adv = _advertisers[index];
                              final name = adv.name;
                              final image = adv.imageUrl;
                              final hasImage = image.isNotEmpty &&
                                  !image.contains('via.placeholder.com') &&
                                  !image.contains('placeholder.com') &&
                                  !image.contains('picsum.photos');
                              final location = adv.distance;
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundImage: hasImage ? NetworkImage(image) : null,
                                      backgroundColor: Colors.grey[700],
                                      child: hasImage
                                          ? null
                                          : const Icon(Icons.person, color: Colors.white70),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            location,
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.yellow,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'View',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ---------- Messages Screen ----------
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late Future<List<Map<String, dynamic>>> _futureConversations;

  @override
  void initState() {
    super.initState();
    _futureConversations = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      // Recent conversations (requires user auth)
      final res = await MessagesService.fetchRecent(page: 1, perPage: 20);
      return res;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureConversations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
              ),
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No conversations yet',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final conv = items[index];
              final last = conv['last_message'] as Map<String, dynamic>?;
              final sender = last?['sender'] as Map<String, dynamic>?;
              final name =
                  sender?['name'] ?? sender?['username'] ?? 'Conversation';
              final message = last?['content'] ?? '';
              return Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[700],
                      child: const Icon(Icons.person, color: Colors.white70),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message.toString(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------- Placeholder Screens ----------
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Explore', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Text(
          'Explore Screen',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Community', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Text(
          'Community Screen',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Text(
          'Profile Screen',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}

// ---------- Home Screen (Server-backed feed) ----------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isDrawerOpen = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Future<List<Map<String, dynamic>>> _futureTopAdvertisers;

  // Inline advertiser search state
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _searchDebounce;
  bool _showAdvSuggestions = false;
  List<Map<String, dynamic>> _advSuggestions = [];

  // User profile data (loaded from session after init)
  UserProfile userProfile = UserProfile(
    name: 'User',
    username: '@user',
    profileImageUrl: '',
    location: '',
  );

  // Server-backed feed
  late Future<List<FeedPost>> _futureFeed;

  // Fallback demo posts if network fails or not authenticated
  final List<Map<String, dynamic>> _fallbackPosts = [
    {
      'name': 'Kriston Watson',
      'username': '@kriston_w',
      'location': 'New York, NY',
      'image':
          'https://images.unsplash.com/photo-1481214110143-ed630356e1bb?q=80&w=387&auto=format&fit=crop&ixlib=rb-4.1.0',
      'profileImage':
          'https://images.unsplash.com/photo-1481214110143-ed630356e1bb?q=80&w=387&auto=format&fit=crop&ixlib=rb-4.1.0',
      'caption': 'Beautiful sunset today! 🌅',
    },
    {
      'name': 'Smith Johnson',
      'username': '@smith_j',
      'location': 'Los Angeles, CA',
      'image':
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop',
      'profileImage':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face',
      'caption': 'New adventures await! ✈️',
    },
    {
      'name': 'Emma Wilson',
      'username': '@emma_w',
      'location': 'Miami, FL',
      'image':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&h=300&fit=crop',
      'profileImage':
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop&crop=face',
      'caption': 'Beach vibes 🏖️',
    },
    {
      'name': 'Alex Chen',
      'username': '@alex_c',
      'location': 'San Francisco, CA',
      'image':
          'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=400&h=300&fit=crop',
      'profileImage':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
      'caption': 'City lights never get old 🌃',
    },
    {
      'name': 'Sarah Davis',
      'username': '@sarah_d',
      'location': 'Chicago, IL',
      'image':
          'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&h=300&fit=crop',
      'profileImage':
          'https://images.unsplash.com/photo-1494790108755-2616b612b789?w=150&h=150&fit=crop&crop=face',
      'caption': 'Nature therapy 🌲',
    },
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _futureFeed = _fetchFeed();
    _futureTopAdvertisers = AdvertiserService.fetchAdvertisers(
      page: 1,
      perPage: 10,
    );

    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        setState(() => _showAdvSuggestions = false);
      }
    });

    // Load current user's profile from session
    _loadCurrentUserFromSession();
  }

  Future<List<FeedPost>> _fetchFeed() async {
    try {
      // Uses PostService which handles auth + response shape
      final List<ModelPost.Post> posts = await PostService.fetchFeed(
        page: 1,
        perPage: 12,
      );
      return posts
          .map(
            (p) => FeedPost(
              id: p.id,
              imageUrl: p.imageUrl,
              caption: p.caption,
              advertiser: FeedAdvertiser(
                id: p.advertiser.id,
                name: p.advertiser.name,
                username: p.advertiser.username,
                profileImage: null,
              ),
              createdAt: p.createdAt,
              location: null,
              likeCount: p.likeCount,
              likedByMe: p.likedByMe,
            ),
          )
          .toList();
    } catch (_) {
      // Swallow and fallback to demo
      return [];
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserFromSession() async {
    try {
      final data = await UserSession.getCurrentUserData();
      if (data != null) {
        final displayName =
            (data['name']?.toString() ?? data['username']?.toString() ?? 'User')
                .trim();
        String uname = (data['username']?.toString() ?? 'user').trim();
        if (uname.isNotEmpty && !uname.startsWith('@')) uname = '@' + uname;
        final imageUrl = (data['profile_image_url']?.toString() ?? '').trim();
        final loc = (data['location']?.toString() ?? '').trim();
        setState(() {
          userProfile = UserProfile(
            name: displayName.isEmpty ? 'User' : displayName,
            username: uname.isEmpty ? '@user' : uname,
            profileImageUrl: imageUrl,
            location: loc,
          );
        });
      }
    } catch (_) {
      // keep defaults if session not ready
    }
  }

  // Build user avatar: network image or initials if none (WhatsApp-style)
  Widget _buildUserAvatar({required double radius}) {
    final img = (userProfile.profileImageUrl).trim();
    if (img.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(img),
        backgroundColor: Colors.grey[700],
      );
    }
    final initials = _initialsFor(userProfile.name);
    final color = _avatarColorFor(userProfile.name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _initialsFor(String name) {
    final parts = name
        .trim()
        .split(RegExp(r"\s+"))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    final first = parts.first[0].toUpperCase();
    final second = parts.length > 1 ? parts[1][0].toUpperCase() : '';
    return (first + second);
  }

  Color _avatarColorFor(String name) {
    const palette = [
      Color(0xFF1ABC9C), // turquoise
      Color(0xFF3498DB), // peter river
      Color(0xFFF39C12), // orange
      Color(0xFFE74C3C), // alizarin
      Color(0xFF9B59B6), // amethyst
      Color(0xFF2ECC71), // emerald
      Color(0xFF16A085), // green sea
      Color(0xFF2980B9), // belize hole
    ];
    final code = name.isEmpty
        ? 0
        : name.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[code % palette.length];
  }

  void _toggleDrawer() {
    setState(() => _isDrawerOpen = !_isDrawerOpen);
    if (_isDrawerOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _navigateToEditProfile() async {
    final updatedProfile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userProfile: userProfile),
      ),
    );

    if (updatedProfile != null) {
      setState(() => userProfile = updatedProfile);
    }
  }

  Future<void> _refresh() async {
    setState(() => _futureFeed = _fetchFeed());
  }

  void _onSearchChanged(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final query = q.trim();
      if (query.isEmpty) {
        setState(() {
          _advSuggestions = [];
          _showAdvSuggestions = false;
        });
        return;
      }
      final results = await AdvertiserService.search(
        query,
        page: 1,
        perPage: 8,
      );
      if (!mounted) return;
      setState(() {
        _advSuggestions = results;
        _showAdvSuggestions = true;
      });
    });
  }

  Widget _buildAdvertiserSuggestionsPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 280),
      child: _advSuggestions.isEmpty
          ? const SizedBox(height: 0)
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _advSuggestions.length,
              separatorBuilder: (_, __) =>
                  Divider(color: Colors.grey[800], height: 1),
              itemBuilder: (context, i) {
                final a = _advSuggestions[i];
                final id = int.tryParse(a['id']?.toString() ?? '') ?? 0;
                final name = (a['name'] ?? a['username'] ?? 'Advertiser')
                    .toString();
                final username = (a['username'] ?? '').toString();
                final location = (a['location'] ?? '').toString();
                final avatar = (a['profile_image_url'] ?? '').toString();
                final validAvatar = (avatar.isNotEmpty &&
                        !avatar.contains('via.placeholder.com') &&
                        !avatar.contains('placeholder.com') &&
                        !avatar.contains('picsum.photos'))
                    ? avatar
                    : '';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        validAvatar.isNotEmpty ? NetworkImage(validAvatar) : null,
                    backgroundColor: Colors.grey[800],
                    child: validAvatar.isEmpty
                        ? const Icon(Icons.person, color: Colors.white70)
                        : null,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${username.isNotEmpty ? '@$username • ' : ''}$location',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  onTap: () async {
                    setState(() {
                      _showAdvSuggestions = false;
                      _searchController.clear();
                      _searchFocus.unfocus();
                    });
                    if (id > 0) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AdvertiserPublicProfileScreen(advertiserId: id),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMainContent(),
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _toggleDrawer,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          if (_isDrawerOpen)
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_slideAnimation.value * 300, 0),
                  child: _buildSidePanel(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'VipGalz',
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            tooltip: 'Messages',
            onPressed: () => Navigator.of(context).pushNamed('/messages'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: _toggleDrawer,
              borderRadius: BorderRadius.circular(16),
              child: _buildUserAvatar(radius: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Inline advertiser search with suggestions
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                _buildUserAvatar(radius: 16),
                const SizedBox(width: 12),
                const Icon(Icons.search, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    cursorColor: Colors.yellow,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: "What's on your mind ?",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                    onTap: () {
                      if (_searchController.text.isNotEmpty &&
                          _advSuggestions.isNotEmpty) {
                        setState(() => _showAdvSuggestions = true);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          if (_showAdvSuggestions) _buildAdvertiserSuggestionsPanel(),

          // Top advertisers strip (dynamic)
          SizedBox(
            height: 100,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Top Advertisers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _futureTopAdvertisers,
                      builder: (context, snapshot) {
                        final items = snapshot.data ?? [];
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (items.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final a = items[index];
                            final name = (a['name'] ?? a['username'] ?? 'Adv')
                                .toString();
                            final raw = (a['profile_image_url'] ?? '').toString();
                            final image = (raw.isNotEmpty &&
                                    !raw.contains('via.placeholder.com') &&
                                    !raw.contains('placeholder.com') &&
                                    !raw.contains('picsum.photos'))
                                ? raw
                                : '';
                            return _buildStoryItem(name, image);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Feed
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<FeedPost>>(
                future: _futureFeed,
                builder: (context, snapshot) {
                  final isLoading =
                      snapshot.connectionState == ConnectionState.waiting;
                  final hasError = snapshot.hasError;
                  final posts = snapshot.data ?? [];

                  if (isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.yellow,
                        ),
                      ),
                    );
                  }

                  // If server returned empty (not logged in, error, etc.), show fallback demo posts
                  if (hasError || posts.isEmpty) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _fallbackPosts.length,
                      itemBuilder: (context, index) {
                        final post = _fallbackPosts[index];
                        return _buildPostCard(
                          postId: index, // Use index as dummy postId
                          advertiserId:
                              index, // Use index as dummy advertiserId
                          name: post['name'],
                          username: post['username'],
                          location: post['location'],
                          profileImage: post['profileImage'],
                          image: post['image'],
                          caption: post['caption'],
                        );
                      },
                    );
                  }

                  // Render server posts
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final p = posts[index];
                      return _buildPostCard(
                        postId: p.id,
                        name: p.advertiser.name,
                        username: '@${p.advertiser.username}',
                        location: p.location ?? '—',
                        profileImage: p.advertiser.profileImage ?? '',
                        image: p.imageUrl,
                        caption: p.caption ?? '',
                        advertiserId: p.advertiser.id,
                        likeCount: p.likeCount,
                        likedByMe: p.likedByMe,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // (Legacy search delegate methods removed; inline search now used.)

  // Local UI state for likes per post
  final Set<int> _likedPostIds = <int>{};
  final Map<int, int> _postLikeCounts = <int, int>{};

  void _startChatWithAdvertiser(int advertiserId) async {
    try {
      final res = await ConversationsService.getOrCreateWithAdvertiser(advertiserId);
      final cid = int.tryParse('${res['id'] ?? res['conversation_id'] ?? 0}') ?? 0;
      if (cid > 0 && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(conversationId: cid)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open chat: $e')),
      );
    }
  }

  void _openCommentsForPost(int postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _CommentsSheet(postId: postId),
      ),
    );
  }

  Widget _buildPostCard({
    required int postId,
    required String name,
    required String username,
    required String location,
    required String profileImage,
    required String image,
    required String caption,
    required int advertiserId,
    int likeCount = 0,
    bool likedByMe = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Builder(builder: (_) {
                  final hasImg = profileImage.isNotEmpty &&
                      !profileImage.contains('via.placeholder.com') &&
                      !profileImage.contains('placeholder.com') &&
                      !profileImage.contains('picsum.photos');
                  return CircleAvatar(
                    radius: 20,
                    backgroundImage: hasImg ? NetworkImage(profileImage) : null,
                    backgroundColor: Colors.grey[700],
                    child: hasImg
                        ? null
                        : const Icon(Icons.person, color: Colors.white70),
                  );
                }),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.grey[400],
                          size: 14,
                        ),
                        Text(
                          location,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Message',
                  icon: const Icon(Icons.send, color: Colors.white70),
                  onPressed: () => _startChatWithAdvertiser(advertiserId),
                ),
              ],
            ),
          ),

          // Image
          Container(
            height: 300,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(image),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Actions + caption
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        (_likedPostIds.contains(postId) || likedByMe)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: (_likedPostIds.contains(postId) || likedByMe)
                            ? Colors.redAccent
                            : Colors.white,
                      ),
                      onPressed: () async {
                        final currentlyLiked =
                            _likedPostIds.contains(postId) || likedByMe;
                        try {
                          if (currentlyLiked) {
                            final res = await PostLikesService.unlike(postId);
                            final cnt =
                                int.tryParse('${res['likes_count'] ?? 0}') ?? 0;
                            setState(() {
                              _likedPostIds.remove(postId);
                              _postLikeCounts[postId] = cnt;
                            });
                          } else {
                            final res = await PostLikesService.like(postId);
                            final cnt =
                                int.tryParse('${res['likes_count'] ?? 0}') ?? 0;
                            setState(() {
                              _likedPostIds.add(postId);
                              _postLikeCounts[postId] = cnt;
                            });
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update like: $e'),
                            ),
                          );
                        }
                      },
                    ),
                    Text(
                      '${_postLikeCounts[postId] ?? likeCount}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
                      onPressed: () => _openCommentsForPost(postId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {},
                    ),
                    const Spacer(),
                    const Icon(Icons.bookmark_border, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(String name, String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.yellow, width: 2),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              backgroundColor: Colors.grey[700],
              child: imageUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white70)
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return Container(
      width: 300,
      height: double.infinity,
      color: Colors.grey[900],
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _toggleDrawer,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildUserAvatar(radius: 40),
                const SizedBox(height: 12),
                Text(
                  userProfile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  userProfile.username,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[400], size: 16),
                    Text(
                      userProfile.location,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _navigateToEditProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSidePanelItem(
                  Icons.person_outline,
                  'My Profile',
                  _navigateToEditProfile,
                ),
                _buildSidePanelItem(Icons.settings, 'Settings', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                }),
                _buildSidePanelItem(
                  Icons.help_outline,
                  'Help & Support',
                  () {},
                ),
                _buildSidePanelItem(
                  Icons.privacy_tip_outlined,
                  'Privacy Policy',
                  () {},
                ),
                _buildSidePanelItem(
                  Icons.description_outlined,
                  'Terms & Conditions',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsAndConditionsScreen(),
                      ),
                    );
                  },
                ),
                _buildSidePanelItem(Icons.info_outline, 'About', () {}),
                Divider(color: Colors.grey[700]),
                _buildSidePanelItem(
                  Icons.logout,
                  'Logout',
                  _confirmAndLogout,
                  isLogout: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanelItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.red : Colors.white),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? Colors.red : Colors.white,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _confirmAndLogout() async {
    // Confirm
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      // Clear session and tokens
      await UserSession.clearSession();
      try {
        await TokenStorage.clearTokens();
      } catch (_) {}

      if (!mounted) return;
      // Go to login screen
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      // Feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout: $e')),
      );
    }
  }
}

// ---------- Edit Profile ----------
class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  const EditProfileScreen({Key? key, required this.userProfile})
    : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _locationController;
  late String _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile.name);
    _usernameController = TextEditingController(
      text: widget.userProfile.username,
    );
    _locationController = TextEditingController(
      text: widget.userProfile.location,
    );
    _profileImageUrl = widget.userProfile.profileImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(_profileImageUrl),
                    backgroundColor: Colors.grey[700],
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildTextField(
              controller: _nameController,
              label: 'Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _usernameController,
              label: 'Username',
              icon: Icons.alternate_email,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _locationController,
              label: 'Location',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Profile Options',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  _ProfileOption(
                    title: 'Change Password',
                    icon: Icons.lock_outline,
                  ),
                  _ProfileOption(
                    title: 'Privacy Settings',
                    icon: Icons.privacy_tip_outlined,
                  ),
                  _ProfileOption(
                    title: 'Account Settings',
                    icon: Icons.settings_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  void _saveProfile() {
    final updatedProfile = UserProfile(
      name: _nameController.text,
      username: _usernameController.text,
      profileImageUrl: _profileImageUrl,
      location: _locationController.text,
    );
    Navigator.pop(context, updatedProfile);
  }
}

class _ProfileOption extends StatelessWidget {
  final String title;
  final IconData icon;
  const _ProfileOption({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}

// ===== Comments Bottom Sheet =====
class _CommentsSheet extends StatefulWidget {
  final int postId;
  const _CommentsSheet({required this.postId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  bool loading = true;
  List<Map<String, dynamic>> comments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await CommentsService.fetchPostComments(
      widget.postId,
      page: 1,
      perPage: 50,
    );
    if (!mounted) return;
    setState(() {
      comments = data;
      loading = false;
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await CommentsService.addPostComment(postId: widget.postId, content: text);
    _controller.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const Text(
                'Comments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.grey[800], height: 1),
                    itemBuilder: (context, i) {
                      final c = comments[i];
                      final user = c['user'] as Map<String, dynamic>?;
                      final name = user != null
                          ? (user['name'] ?? user['username'] ?? 'User')
                                .toString()
                          : 'User';
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.grey[800],
                          child: const Icon(
                            Icons.person,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          (c['content'] ?? '').toString(),
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add a comment',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            borderSide: BorderSide(color: Colors.yellow),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.yellow),
                      onPressed: _send,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
