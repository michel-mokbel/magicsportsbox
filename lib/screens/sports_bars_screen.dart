import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SportsBarScreen extends StatefulWidget {
  const SportsBarScreen({super.key});

  @override
  _SportsBarScreenState createState() => _SportsBarScreenState();
}

class _SportsBarScreenState extends State<SportsBarScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<Map<String, dynamic>> _nearbyBars = [];
  bool _isLoading = true;
  Set<Marker> _markers = {};
  final String _apiKey = 'AIzaSyCsiw4EUdPsStONc7B3rLOh9gwxdP6IE7U';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
    _searchNearbyBars();
  }

  Future<void> _searchNearbyBars() async {
    if (_currentPosition == null) return;

    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'location=${_currentPosition!.latitude},${_currentPosition!.longitude}'
        '&radius=5000'
        '&type=bar'
        '&keyword=sports'
        '&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        setState(() {
          _nearbyBars = List<Map<String, dynamic>>.from(data['results']);
          _markers = _nearbyBars.map((bar) {
            final location = bar['geometry']['location'];
            return Marker(
              markerId: MarkerId(bar['place_id']),
              position: LatLng(location['lat'], location['lng']),
              infoWindow: InfoWindow(
                title: bar['name'],
                snippet: bar['vicinity'],
              ),
            );
          }).toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching nearby bars: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchMaps(double lat, double lng, String name) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/Second.png',
              fit: BoxFit.cover,
            ),
          ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'Nearby Sports Bars',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
              ),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_currentPosition == null)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Location access required to find nearby bars',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            zoom: 13,
                          ),
                          markers: _markers,
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _nearbyBars.length,
                          itemBuilder: (context, index) {
                            final bar = _nearbyBars[index];
                            final location = bar['geometry']['location'];
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              color: Colors.white.withOpacity(0.9),
                              child: ListTile(
                                leading: bar['photos'] != null && bar['photos'].isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: 'https://maps.googleapis.com/maps/api/place/photo'
                                            '?maxwidth=100'
                                            '&photo_reference=${bar['photos'][0]['photo_reference']}'
                                            '&key=$_apiKey',
                                        height: 40,
                                        width: 40,
                                        placeholder: (context, url) => const Icon(
                                          Icons.sports_bar,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                        errorWidget: (context, url, error) => const Icon(
                                          Icons.sports_bar,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                        memCacheHeight: 80,
                                        memCacheWidth: 80,
                                        maxWidthDiskCache: 80,
                                        maxHeightDiskCache: 80,
                                        useOldImageOnUrlChange: true,
                                      )
                                    : const Icon(
                                        Icons.sports_bar,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                title: Text(
                                  bar['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(bar['vicinity'] ?? ''),
                                    if (bar['rating'] != null)
                                      Row(
                                        children: [
                                          Icon(Icons.star, size: 16, color: Colors.amber),
                                          Text(' ${bar['rating']}'),
                                          if (bar['user_ratings_total'] != null)
                                            Text(' (${bar['user_ratings_total']} reviews)'),
                                        ],
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.directions),
                                  onPressed: () => _launchMaps(
                                    location['lat'],
                                    location['lng'],
                                    bar['place_id'],
                                  ),
                                ),
                                onTap: () {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLng(
                                      LatLng(location['lat'], location['lng']),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
} 