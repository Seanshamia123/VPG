// import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
import 'package:escort/services/post_service.dart';
import 'package:escort/models/post.dart' as ModelPost;
import 'search/search_delegate.dart';

import 'settings_screen.dart';
import 'terms_and_conditions_screen.dart';
import 'package:escort/services/advertiser_service.dart';
import 'package:escort/services/messages_service.dart';
// Uses your existing token helpers (no direct use here)
// import 'package:escort/services/user_session.dart';

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

  FeedPost({
    required this.id,
    required this.imageUrl,
    required this.advertiser,
    required this.createdAt,
    this.caption,
    this.location,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: json['id'] as int,
      imageUrl: json['image_url'] as String,
      caption: json['caption'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      advertiser: FeedAdvertiser.fromJson(json['advertiser'] ?? const {}),
      location: json['location'] as String?,
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
                              final image = adv.imageUrl.isNotEmpty
                                  ? adv.imageUrl
                                  : 'https://via.placeholder.com/100x100.png?text=A';
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
                                      backgroundImage: NetworkImage(image),
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
              final image = 'https://via.placeholder.com/100x100.png?text=U';
              return Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(image),
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

  // User profile data
  UserProfile userProfile = UserProfile(
    name: 'Roster_123',
    username: '@roster123',
    profileImageUrl:
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
    location: 'New York, NY',
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
    super.dispose();
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
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () async {
              final delegate = await _loadSearchDelegate();
              // ignore: use_build_context_synchronously
              showSearch(context: context, delegate: delegate);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: _toggleDrawer,
              borderRadius: BorderRadius.circular(16),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(userProfile.profileImageUrl),
                backgroundColor: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Composer placeholder
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(userProfile.profileImageUrl),
                  backgroundColor: Colors.grey[700],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "What's on your mind ?",
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

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
                            final image =
                                (a['profile_image_url'] ??
                                        'https://via.placeholder.com/100x100.png?text=A')
                                    .toString();
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
                        name: p.advertiser.name,
                        username: '@${p.advertiser.username}',
                        location: p.location ?? '—',
                        profileImage:
                            p.advertiser.profileImage ??
                            'https://via.placeholder.com/100x100.png?text=AD',
                        image: p.imageUrl,
                        caption: p.caption ?? '',
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

  Future<dynamic> _loadSearchDelegate() async {
    // Lazy import to avoid cyc deps
    // ignore: unused_local_variable
    return AppSearchDelegate();
  }

  Widget _buildPostCard({
    required String name,
    required String username,
    required String location,
    required String profileImage,
    required String image,
    required String caption,
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
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(profileImage),
                  backgroundColor: Colors.grey[700],
                ),
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
                Icon(Icons.more_vert, color: Colors.grey[400]),
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
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
                      onPressed: () {},
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
              backgroundImage: NetworkImage(imageUrl),
              backgroundColor: Colors.grey[700],
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
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(userProfile.profileImageUrl),
                  backgroundColor: Colors.grey[700],
                ),
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
                  () {},
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
