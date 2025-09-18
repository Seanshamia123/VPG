/// Feature: Home
/// Screen: LocationScreen (map + nearby advertisers)
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:escort/services/advertiser_service.dart';

// Advertiser model used on Location screen
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
            .map((item) {
              final city = (item['city']?.toString() ?? item['location_city']?.toString() ?? '').trim();
              final country = (item['country']?.toString() ?? item['location_country']?.toString() ?? '').trim();
              final locationLabel = [city, country]
                  .where((s) => s.isNotEmpty)
                  .join(city.isNotEmpty && country.isNotEmpty ? ', ' : '');
              return Advertiser(
                name: item['name'] ?? '',
                imageUrl: item['imageUrl'] ?? '',
                latitude: item['latitude']?.toDouble() ?? 0.0,
                longitude: item['longitude']?.toDouble() ?? 0.0,
                distance: locationLabel.isNotEmpty
                    ? locationLabel
                    : (item['location'] ?? item['distance'] ?? '').toString(),
              );
            })
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final onSurface = scheme.onSurface;
    final onSurfaceVariant = scheme.onSurfaceVariant;
    final divider = theme.dividerColor;
    final surface = scheme.surface;
    final cardColor = theme.cardColor;
    final primary = scheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? surface,
        elevation: 0,
        title: Text(
          'Locations',
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
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primary),
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
                      color: surface,
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
                            color: divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: primary),
                              const SizedBox(width: 8),
                              Text(
                                'Nearby Advertisers',
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
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundImage: hasImage ? NetworkImage(image) : null,
                                      backgroundColor: scheme.surfaceVariant,
                                      child: hasImage
                                          ? null
                                          : Icon(Icons.person, color: onSurfaceVariant),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: textTheme.titleSmall?.copyWith(
                                                  color: onSurface,
                                                  fontWeight: FontWeight.w600,
                                                ) ??
                                                TextStyle(
                                                  color: onSurface,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            location,
                                            style: textTheme.bodySmall?.copyWith(
                                                  color: onSurfaceVariant,
                                                  fontSize: 14,
                                                ) ??
                                                TextStyle(
                                                  color: onSurfaceVariant,
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
                                        color: primary,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'View',
                                        style: textTheme.labelLarge?.copyWith(
                                              color: scheme.onPrimary,
                                              fontWeight: FontWeight.w600,
                                            ) ??
                                            TextStyle(
                                              color: scheme.onPrimary,
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
