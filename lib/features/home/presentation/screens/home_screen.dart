/// Feature: Home
/// Screen: HomeScreen (feed and search panel)
///
/// Note: This file is still large; next pass will extract feed cards,
/// search widgets, and side panel into components.
library;

// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:escort/screens/advertisers_screens/advertiser_public_profile.dart';
import 'dart:convert';

import 'package:escort/config/api_config.dart';
import 'package:escort/features/home/presentation/screens/location_screen.dart';
import 'package:escort/services/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:escort/l10n/app_localizations.dart';
import 'dart:async';
// import 'package:http/http.dart' as http;
import 'package:escort/services/post_service.dart';
// ignore: library_prefixes
import 'package:escort/models/post.dart' as ModelPost;
import 'package:escort/features/home/domain/models/user_profile.dart';
import 'package:escort/features/home/presentation/screens/placeholder_screens.dart';
// EditProfileScreen kept inline for now to avoid duplication

import 'package:escort/features/settings/presentation/screens/settings_screen.dart';
import 'package:escort/features/settings/presentation/screens/terms_and_conditions_screen.dart';
import 'package:escort/services/advertiser_service.dart'
    hide ConversationsService;
// import 'package:escort/screens/advertisers_screens/advertiser_public_profile.dart';

import 'package:escort/services/user_session.dart';
import 'package:escort/services/conversations_service.dart';

import 'package:escort/features/messages/presentation/screens/chat_screen.dart';
import 'package:escort/features/messages/presentation/screens/message.dart';

import 'package:escort/features/advertisers/presentation/screens/advertiser_public.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// import 'package:escort/screens/advertiser_public.dart'
// Helper extension for string capitalization
extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

// ---------- Models ----------

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

// ---------- App Shell ----------
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VipGalz',
      theme: ThemeData(colorScheme: const ColorScheme.light()),
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
      routes: {'/messages': (context) => Message()},
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
    Message(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor:
            theme.bottomAppBarTheme.color ?? scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
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
/* class LocationScreen extends StatefulWidget {
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
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
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
                              final hasImage =
                                  image.isNotEmpty &&
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
                                      backgroundImage: hasImage
                                          ? NetworkImage(image)
                                          : null,
                                      backgroundColor: Colors.grey[700],
                                      child: hasImage
                                          ? null
                                          : const Icon(
                                              Icons.person,
                                              color: Colors.white70,
                                            ),
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
*/

// MessagesScreen moved to lib/features/messages/presentation/screens/messages_screen.dart

// ---------- Placeholder Screens ----------
// Explore, Community, Profile screens moved to
// lib/features/home/presentation/screens/placeholder_screens.dart

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

  // Filter state variables
  String? _selectedGender;
  String? _selectedLocation;
  bool _showFilters = false;

  // User profile data (loaded from session after init)
  UserProfile userProfile = UserProfile(
    name: 'User',
    username: '@user',
    profileImageUrl: '',
    location: '',
  );

  // Server-backed feed
  late Future<List<FeedPost>> _futureFeed;

  // No local demo posts; feed uses backend only

  ColorScheme get _scheme => Theme.of(context).colorScheme;
  ThemeData get _theme => Theme.of(context);
  TextTheme get _textTheme => Theme.of(context).textTheme;
  bool get _isDark => _theme.brightness == Brightness.dark;

  Color get _primaryColor => _scheme.primary;
  Color get _onPrimaryColor => _scheme.onPrimary;
  Color get _surfaceColor => _theme.scaffoldBackgroundColor;
  Color get _surfaceVariantColor => _scheme.surface;
  Color get _onSurfaceColor => _scheme.onSurface;
  Color get _onSurfaceVariantColor => _scheme.onSurfaceVariant;
  Color get _dividerColor => _theme.dividerColor;

  Color get _panelBackgroundColor =>
      _isDark ? const Color(0xFF111315) : _surfaceColor;
  Color get _panelSurfaceColor =>
      _isDark ? const Color(0xFF1F2426) : _surfaceVariantColor;
  Color get _panelCardColor =>
      _isDark ? const Color(0xFF1C1F20) : _theme.cardColor;
  Color get _textPrimaryColor =>
      _isDark ? Colors.white : _onSurfaceColor;
  Color get _textSecondaryColor =>
      _isDark ? Colors.white70 : _onSurfaceVariantColor;
  Color get _borderNeutralColor =>
      _isDark ? Colors.white24 : _dividerColor;
  Color get _chipBackgroundColor =>
      _primaryColor.withValues(alpha: _isDark ? 0.18 : 0.08);
  Color get _chipBorderColor =>
      _primaryColor.withValues(alpha: _isDark ? 0.35 : 0.2);

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
    _futureTopAdvertisers =  _fetchTopAdvertisersByLikes();

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
      return posts.map((p) {
        final city = (p.advertiser.city ?? '').trim();
        final country = (p.advertiser.country ?? '').trim();
        final loc = [city, country]
            .where((s) => s.isNotEmpty)
            .join(city.isNotEmpty && country.isNotEmpty ? ', ' : '');
        return FeedPost(
          id: p.id,
          imageUrl: p.imageUrl,
          caption: p.caption,
          advertiser: FeedAdvertiser(
            id: p.advertiser.id,
            name: p.advertiser.name,
            username: p.advertiser.username,
            profileImage: p.advertiser.profileImageUrl,
          ),
          createdAt: p.createdAt,
          location: loc.isNotEmpty ? loc : null,
          likeCount: p.likeCount,
          likedByMe: p.likedByMe,
        );
      }).toList();
    } catch (_) {
      // Swallow and fallback to demo
      return [];
    }
  }
  // Add this method to fetch top advertisers by likes
Future<List<Map<String, dynamic>>> _fetchTopAdvertisersByLikes() async {
  try {
    final token = await TokenStorage.getAccessToken();
    if (token == null) {
      throw Exception('No access token');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.api}/posts/top-advertisers-by-likes?limit=10'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['advertisers'] ?? []);
    } else {
      throw Exception('Failed to load top advertisers: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching top advertisers by likes: $e');
    return [];
  }
}

// Update the initState to use the new method

// Update the _buildStoryItem to accept advertiser ID and make it clickable
Widget _buildStoryItem(String name, String imageUrl, int advertiserId) {
  return GestureDetector(
    onTap: () async {
      if (advertiserId > 0) {
        await _navigateToAdvertiserProfile(advertiserId);
      }
    },
    child: Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _primaryColor, width: 2),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
              backgroundColor: _surfaceVariantColor,
              child: imageUrl.isEmpty
                  ? Icon(Icons.person, color: _textSecondaryColor)
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              name,
              style: _textTheme.bodySmall?.copyWith(
                    color: _textPrimaryColor,
                    fontSize: 12,
                  ) ??
                  TextStyle(color: _textPrimaryColor, fontSize: 12),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    ),
  );
}

  @override
  void dispose() {
    _animationController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  

  Future<void> _navigateToAdvertiserProfile(int advertiserId) async {
    if (advertiserId <= 0) {
      print('Invalid advertiser ID: $advertiserId');
      return;
    }

    try {
      // Use Navigator.pushNamed if you have routes set up
      // Or use the direct approach:
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              AdvertiserPublicProfileScreen(advertiserId: advertiserId),
        ),
      );
    } catch (e, stackTrace) {
      print('Navigation failed: $e');
      print('StackTrace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        final city =
            (data['city']?.toString() ??
                    data['location_city']?.toString() ??
                    '')
                .trim();
        final country =
            (data['country']?.toString() ??
                    data['location_country']?.toString() ??
                    '')
                .trim();
        final loc = [city, country]
            .where((s) => s.isNotEmpty)
            .join(city.isNotEmpty && country.isNotEmpty ? ', ' : '');
        setState(() {
          userProfile = UserProfile(
            name: displayName.isEmpty ? 'User' : displayName,
            username: uname.isEmpty ? '@user' : uname,
            profileImageUrl: imageUrl,
            location: loc.isNotEmpty
                ? loc
                : (data['location']?.toString() ?? ''),
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
        backgroundColor: _surfaceVariantColor,
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
          color: _onSurfaceColor,
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

  // Updated search method with filters
  // Improved search method for your home_screen.dart

  void _onSearchChanged(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      final query = q.trim();

      try {
        List<Map<String, dynamic>> results = [];

        // Determine search strategy based on input and filters
        if (query.isEmpty &&
            _selectedGender == null &&
            _selectedLocation == null) {
          // No query and no filters - hide suggestions
          setState(() {
            _advSuggestions = [];
            _showAdvSuggestions = false;
          });
          return;
        }

        // Use filtered search if filters are applied
        if (_selectedGender != null || _selectedLocation != null) {
          results = await AdvertiserService.searchWithFilters(
            query: query.isEmpty ? null : query,
            gender: _selectedGender,
            location: _selectedLocation,
            page: 1,
            perPage: 8,
          );
        } else if (query.isNotEmpty) {
          // Use regular search for query-only searches
          results = await AdvertiserService.search(query, page: 1, perPage: 8);
        }

        if (!mounted) return;

        setState(() {
          _advSuggestions = results;
          _showAdvSuggestions = results.isNotEmpty;
        });
      } catch (e) {
        print('Search error: $e');
        if (!mounted) return;

        setState(() {
          _advSuggestions = [];
          _showAdvSuggestions = false;
        });

        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    });
  }

  // Add this getter to check if filters are active
  bool get _hasActiveFilters =>
      _selectedGender != null ||
      (_selectedLocation != null && _selectedLocation!.isNotEmpty);

  // Enhanced search widget with filters
  Widget _buildSearchWithFilters() {
    final hintStyle = _textTheme.bodyMedium?.copyWith(
          color: _textSecondaryColor,
          fontSize: 16,
        ) ??
        TextStyle(color: _textSecondaryColor, fontSize: 16);

    return Column(
      children: [
        // Main search bar
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _panelSurfaceColor,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              _buildUserAvatar(radius: 16),
              const SizedBox(width: 12),
              Icon(Icons.search, color: _textSecondaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  style: _textTheme.bodyMedium?.copyWith(
                        color: _textPrimaryColor,
                        fontSize: 16,
                      ) ??
                      TextStyle(color: _textPrimaryColor, fontSize: 16),
                  cursorColor: _primaryColor,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Search people...',
                    hintStyle: hintStyle,
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
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_list : Icons.tune,
                  color: _showFilters ? _primaryColor : _textSecondaryColor,
                ),
                onPressed: () {
                  setState(() => _showFilters = !_showFilters);
                },
              ),
            ],
          ),
        ),

        // Filter options (expandable)
        if (_showFilters)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _panelCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderNeutralColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: _textTheme.titleSmall?.copyWith(
                        color: _textPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ) ??
                      TextStyle(
                        color: _textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),

                // Gender filter
                Row(
                  children: [
                    Icon(Icons.person, color: _textSecondaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Gender:',
                      style: _textTheme.bodySmall?.copyWith(
                            color: _textSecondaryColor,
                            fontSize: 14,
                          ) ??
                          TextStyle(color: _textSecondaryColor, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String?>(
                        value: _selectedGender,
                        hint: Text('Any', style: hintStyle),
                        dropdownColor: _panelSurfaceColor,
                        style: _textTheme.bodyMedium?.copyWith(
                              color: _textPrimaryColor,
                            ) ??
                            TextStyle(color: _textPrimaryColor),
                        iconEnabledColor: _textSecondaryColor,
                        iconDisabledColor: _textSecondaryColor,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Any'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'male',
                            child: Text('Male'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedGender = value);
                          _onSearchChanged(_searchController.text);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Location filter
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: _textSecondaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Location:',
                      style: _textTheme.bodySmall?.copyWith(
                            color: _textSecondaryColor,
                            fontSize: 14,
                          ) ??
                          TextStyle(color: _textSecondaryColor, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        style: _textTheme.bodyMedium?.copyWith(
                              color: _textPrimaryColor,
                              fontSize: 14,
                            ) ??
                            TextStyle(color: _textPrimaryColor, fontSize: 14),
                        cursorColor: _primaryColor,
                        decoration: InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _borderNeutralColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _primaryColor),
                          ),
                          hintText: 'Enter location',
                          hintStyle: hintStyle.copyWith(fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          setState(
                            () => _selectedLocation = value.trim().isEmpty
                                ? null
                                : value.trim(),
                          );
                          _onSearchChanged(_searchController.text);
                        },
                      ),
                    ),
                  ],
                ),

                // Clear filters button
                if (_selectedGender != null || _selectedLocation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedGender = null;
                            _selectedLocation = null;
                          });
                          _onSearchChanged(_searchController.text);
                        },
                        icon: Icon(
                          Icons.clear,
                          color: _primaryColor,
                          size: 16,
                        ),
                        label: Text(
                          'Clear Filters',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _buildFilterSummary() {
    final List<String> activeFilters = [];

    if (_selectedGender != null) {
      activeFilters.add(_selectedGender!.capitalize());
    }

    if (_selectedLocation != null) {
      activeFilters.add(_selectedLocation!);
    }

    return activeFilters.join(', ');
  }

  Widget _buildAdvertiserSuggestionsPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: _panelSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.3 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 320),
      child: _advSuggestions.isEmpty
          ? const SizedBox(height: 0)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with results count and filter indicator
                if (_advSuggestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${_advSuggestions.length} result${_advSuggestions.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: _textSecondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_hasActiveFilters) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _chipBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _chipBorderColor,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.filter_alt,
                                  color: _primaryColor,
                                  size: 10,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Filtered',
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (_hasActiveFilters)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedGender = null;
                                _selectedLocation = null;
                              });
                              _onSearchChanged(_searchController.text);
                            },
                            child: Text(
                              'Clear filters',
                              style: TextStyle(
                                color: _primaryColor,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _advSuggestions.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: _borderNeutralColor, height: 1),
                    itemBuilder: (context, i) {
                      final a = _advSuggestions[i];
                      final id = int.tryParse(a['id']?.toString() ?? '') ?? 0;
                      final name = (a['name'] ?? a['username'] ?? 'Advertiser')
                          .toString();
                      final username = (a['username'] ?? '').toString();
                      final location = (a['location'] ?? '').toString();
                      final avatar = (a['profile_image_url'] ?? '').toString();
                      final gender = (a['gender'] ?? '').toString();
                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundImage: avatar.isNotEmpty
                                  ? NetworkImage(avatar)
                                  : null,
                              backgroundColor: _surfaceVariantColor,
                              child: avatar.isEmpty
                                  ? Icon(
                                      Icons.person,
                                      color: _textSecondaryColor,
                                    )
                                  : null,
                            ),
                            // Online indicator
                            if (a['is_online'] == true)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _panelSurfaceColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: _textTheme.bodyMedium?.copyWith(
                                      color: _textPrimaryColor,
                                      fontWeight: FontWeight.w600,
                                    ) ??
                                    TextStyle(color: _textPrimaryColor),
                              ),
                            ),
                            if (a['is_verified'] == true)
                              Icon(
                                Icons.verified,
                                color: _primaryColor,
                                size: 16,
                              ),
                            if (a['is_online'] == true)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text(
                                '${username.isNotEmpty ? '@$username' : ''}${location.isNotEmpty && username.isNotEmpty ? ' • $location' : location}',
                                style: TextStyle(
                                color: _textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                            if (gender.isNotEmpty ||
                                a['distance']?.toString().isNotEmpty == true)
                              Text(
                                '${gender.isNotEmpty ? gender.capitalize() : ''}${gender.isNotEmpty && a['distance']?.toString().isNotEmpty == true ? ' • ' : ''}${a['distance']?.toString() ?? ''}',
                                style: TextStyle(
                                  color: _textSecondaryColor,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),

                        // Replace your ListTile onTap in _buildAdvertiserSuggestionsPanel with this:
                        // Replace the onTap handler in your _buildAdvertiserSuggestionsPanel method
                        // with this corrected version:
                        onTap: () async {
                          setState(() {
                            _showAdvSuggestions = false;
                          });
                          _searchController.clear();
                          _searchFocus.unfocus();

                          await _navigateToAdvertiserProfile(id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildMainContent(),
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _toggleDrawer,
              child: Container(
                color: Colors.black.withValues(alpha: _isDark ? 0.5 : 0.25),
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
    final theme = _theme;
    final scheme = _scheme;
    final textTheme = _textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? scheme.surface,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.appName,
          style: textTheme.titleLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ) ??
              TextStyle(
                color: scheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: scheme.onSurface,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline,
              color: scheme.onSurface,
            ),
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
          // Enhanced search with filters
          _buildSearchWithFilters(),

          // Active filters indicator
          if (_selectedGender != null || _selectedLocation != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _chipBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _chipBorderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, color: _primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Filters: ${_buildFilterSummary()}',
                    style: TextStyle(color: _primaryColor, fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedGender = null;
                        _selectedLocation = null;
                      });
                      _onSearchChanged(_searchController.text);
                    },
                    child: Icon(
                      Icons.close,
                      color: _primaryColor,
                      size: 16,
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
                  Text(
                    'Top Advertisers',
                    style: _textTheme.titleMedium?.copyWith(
                          color: _textPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ) ??
                        TextStyle(
                          color: _textPrimaryColor,
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
                        return // FIND THIS in your FutureBuilder (around line 1637):
ListView.builder(
  scrollDirection: Axis.horizontal,
  itemCount: items.length,
  itemBuilder: (context, index) {
    final a = items[index];
    final name = (a['name'] ?? a['username'] ?? 'Adv')
        .toString();
    final raw = (a['profile_image_url'] ?? '')
        .toString();
    final image =
        (raw.isNotEmpty &&
            !raw.contains('via.placeholder.com') &&
            !raw.contains('placeholder.com') &&
            !raw.contains('picsum.photos'))
        ? raw
        : '';
    
    // ADD THIS LINE - extract the advertiser ID:
    final advertiserId = int.tryParse(a['id']?.toString() ?? '') ?? 0;
    
    // CHANGE THIS LINE - pass all 3 arguments:
    return _buildStoryItem(name, image, advertiserId);
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
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _primaryColor,
                        ),
                      ),
                    );
                  }

                  // If server returned empty or error, show an empty state
                  if (hasError || posts.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(32),
                      children: [
                        const SizedBox(height: 80),
                        Icon(
                          Icons.photo_library_outlined,
                          color: _textSecondaryColor,
                          size: 64,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'No posts available',
                            style: _textTheme.bodyMedium?.copyWith(
                                  color: _textSecondaryColor,
                                  fontSize: 16,
                                ) ??
                                TextStyle(
                                  color: _textSecondaryColor,
                                  fontSize: 16,
                                ),
                          ),
                        ),
                      ],
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

  // Local UI state for likes per post
  final Set<int> _likedPostIds = <int>{};
  final Map<int, int> _postLikeCounts = <int, int>{};

  // get _hasActiveFilters => null;

    void _startChatWithAdvertiser(int advertiserId) async {
    try {
      if (advertiserId <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid advertiser ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('[HomeScreen] Starting chat with advertiser $advertiserId');

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
          ),
        ),
      );

      try {
        // Get or create conversation with advertiser
        final res =
            await ConversationsService.getOrCreateWithAdvertiser(advertiserId);

        print('[HomeScreen] Conversation response: $res');

        // Extract conversation ID from response
        final conversationId = int.tryParse(
          (res['id'] ?? res['conversation_id'] ?? 0).toString(),
        );

        if (!mounted) return;

        // Close loading dialog
        Navigator.pop(context);

        if (conversationId == null || conversationId <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create conversation'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        print('[HomeScreen] Navigating to chat screen with ID: $conversationId');

        // Navigate to chat screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              title: 'Chat',
            ),
          ),
        );
      } catch (innerError) {
        if (!mounted) return;

        // Close loading dialog
        Navigator.pop(context);

        print('[HomeScreen] Inner error: $innerError');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $innerError'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      print('[HomeScreen] Outer error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add this helper method to your _HomeScreenState class:

  void _openCommentsForPost(int postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _panelSurfaceColor,
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

   Widget _buildPostCardHeader({
    required String name,
    required String location,
    required String profileImage,
    required int advertiserId,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              print('[HomeScreen] Navigating to advertiser profile: $advertiserId');
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdvertiserPublicProfileScreen(
                    advertiserId: advertiserId,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : null,
                  backgroundColor: _surfaceVariantColor,
                  child: profileImage.isEmpty
                      ? Icon(
                          Icons.person,
                          color: _textSecondaryColor,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: _textTheme.titleSmall?.copyWith(
                            color: _textPrimaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ) ??
                          TextStyle(
                            color: _textPrimaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: _textSecondaryColor,
                          size: 14,
                        ),
                        Text(
                          location,
                          style: TextStyle(
                            color: _textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Tooltip(
            message: 'Message advertiser',
            child: IconButton(
              tooltip: 'Message',
              icon: Icon(Icons.send, color: _textSecondaryColor),
              onPressed: () {
                print('[HomeScreen] Message button pressed for advertiser: $advertiserId');
                _startChatWithAdvertiser(advertiserId);
              },
            ),
          ),
        ],
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
        color: _panelSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          // Replace your existing header section in _buildPostCard with this:
          // Header with clickable profile
           _buildPostCardHeader(
    name: name,
    location: location,
    profileImage: profileImage,
    advertiserId: advertiserId,
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
                  style: _textTheme.bodyMedium?.copyWith(
                        color: _textPrimaryColor,
                        fontSize: 14,
                      ) ??
                      TextStyle(color: _textPrimaryColor, fontSize: 14),
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
                            : _textSecondaryColor,
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
                      style: TextStyle(color: _textSecondaryColor),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        color: _textSecondaryColor,
                      ),
                      onPressed: () => _openCommentsForPost(postId),
                    ),
                    IconButton(
                      icon: Icon(Icons.share, color: _textSecondaryColor),
                      onPressed: () {},
                    ),
                    const Spacer(),
                    Icon(Icons.bookmark_border, color: _textSecondaryColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildSidePanel() {
    return Container(
      width: 300,
      height: double.infinity,
      color: _panelBackgroundColor,
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
              color: _panelSurfaceColor,
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
                    Text(
                      'Profile',
                      style: _textTheme.titleMedium?.copyWith(
                            color: _textPrimaryColor,
                            fontWeight: FontWeight.w600,
                          ) ??
                          TextStyle(
                            color: _textPrimaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: _textPrimaryColor),
                      onPressed: _toggleDrawer,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildUserAvatar(radius: 40),
                const SizedBox(height: 12),
                Text(
                  userProfile.name,
                  style: _textTheme.titleMedium?.copyWith(
                        color: _textPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ) ??
                      TextStyle(
                        color: _textPrimaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  userProfile.username,
                  style: _textTheme.bodySmall?.copyWith(
                        color: _textSecondaryColor,
                        fontSize: 14,
                      ) ??
                      TextStyle(color: _textSecondaryColor, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, color: _textSecondaryColor, size: 16),
                    Text(
                      userProfile.location,
                      style: _textTheme.bodySmall?.copyWith(
                            color: _textSecondaryColor,
                            fontSize: 12,
                          ) ??
                          TextStyle(color: _textSecondaryColor, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _navigateToEditProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: _onPrimaryColor,
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
                Divider(color: _borderNeutralColor),
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
        leading: Icon(
          icon,
          color: isLogout ? Colors.red : _textPrimaryColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? Colors.red : _textPrimaryColor,
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
        backgroundColor: _panelSurfaceColor,
        title: Text(
          'Logout',
          style: _textTheme.titleMedium?.copyWith(color: _textPrimaryColor) ??
              TextStyle(color: _textPrimaryColor),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: _textTheme.bodyMedium?.copyWith(color: _textSecondaryColor) ??
              TextStyle(color: _textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: _textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Logout',
              style: TextStyle(color: _primaryColor),
            ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to logout: $e')));
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final onSurface = scheme.onSurface;
    final cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? scheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.foregroundColor ?? onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: textTheme.titleMedium?.copyWith(
                color: theme.appBarTheme.foregroundColor ?? onSurface,
                fontWeight: FontWeight.w600,
              ) ??
              TextStyle(
                color: theme.appBarTheme.foregroundColor ?? onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              'Save',
              style: textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ) ??
                  TextStyle(
                    color: scheme.primary,
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
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(_profileImageUrl),
                    backgroundColor: scheme.surface,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: scheme.onPrimary,
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
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor.withValues(
                        alpha: theme.brightness == Brightness.dark ? 0.25 : 0.35,
                      ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Options',
                    style: textTheme.titleMedium?.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w600,
                        ) ??
                        TextStyle(
                          color: onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: TextField(
        controller: controller,
        style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface) ??
            TextStyle(color: scheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
        labelStyle: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ) ??
            TextStyle(color: scheme.onSurfaceVariant),
        prefixIcon: Icon(icon, color: scheme.onSurfaceVariant),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            title,
            style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontSize: 16,
                ) ??
                TextStyle(color: scheme.onSurface, fontSize: 16),
          ),
          const Spacer(),
          Icon(Icons.arrow_forward_ios,
              color: scheme.onSurfaceVariant, size: 16),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onSurface = scheme.onSurface;
    final onSurfaceVariant = scheme.onSurfaceVariant;
    final divider = theme.dividerColor;
    final surfaceVariant = scheme.surface;
    final primary = scheme.primary;

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
                  color: divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Text(
                'Comments',
                style: theme.textTheme.titleSmall?.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w600,
                    ) ??
                    TextStyle(
                      color: onSurface,
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
                        Divider(color: divider, height: 1),
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
                          backgroundColor: surfaceVariant,
                          child: Icon(
                            Icons.person,
                            color: onSurfaceVariant,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: onSurface,
                                fontSize: 14,
                              ) ??
                              TextStyle(color: onSurface, fontSize: 14),
                        ),
                        subtitle: Text(
                          (c['content'] ?? '').toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: onSurfaceVariant,
                              ) ??
                              TextStyle(color: onSurfaceVariant),
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                              color: onSurface,
                            ) ??
                            TextStyle(color: onSurface),
                        decoration: InputDecoration(
                          hintText: 'Add a comment',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: onSurfaceVariant,
                              ) ??
                              TextStyle(color: onSurfaceVariant),
                          filled: true,
                          fillColor: surfaceVariant.withValues(
                            alpha:
                                theme.brightness == Brightness.dark ? 0.4 : 0.6,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20),
                            ),
                            borderSide: BorderSide(color: primary),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: primary),
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
