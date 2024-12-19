import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '/pages/api_service.dart';
import '/providers/Location_provider.dart';
import '/pages/ResultsDisplayPage.dart';
import 'dart:math';

class Specialistspage extends StatefulWidget {
  final String specialistType;

  const Specialistspage({Key? key, required this.specialistType}) : super(key: key);

  @override
  _SpecialistspageState createState() => _SpecialistspageState();
}

class _SpecialistspageState extends State<Specialistspage> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  List specialists = [];
  bool isLoading = true;
  double userLat = 0.0;
  double userLng = 0.0;
  Set<Polyline> polylines = {};
  final PanelController panelController = PanelController();
  String googleApiKey = "AIzaSyBL4yd55ZMxeZ-_tOYY_jQeIF0Gbr5zIUc"; // Replace with your actual API key

  late String _mapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _fetchLocationAndSpecialists();
  }

  void _loadMapStyle() async {
    try {
      _mapStyle = await DefaultAssetBundle.of(context).loadString('assets/map_style.json');
      print("Map Style Loaded Successfully");
    } catch (e) {
      print("Error Loading Map Style: $e");
    }
  }

  Future<void> _fetchLocationAndSpecialists() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.getCurrentLocation();

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      userLat = position.latitude;
      userLng = position.longitude;

      final fetchedSpecialists = await ApiService.fetchNearbySpecialists(userLat, userLng, widget.specialistType);
      setState(() {
        specialists = fetchedSpecialists;
        markers.clear();
        _addMarkers();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching location: $e');
    }
  }

  void _addMarkers() {
    markers.add(Marker(
      markerId: MarkerId("user_location"),
      position: LatLng(userLat, userLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(title: 'Your Location'),
    ));

    for (var specialist in specialists) {
      final lat = specialist['geometry']['location']['lat'];
      final lng = specialist['geometry']['location']['lng'];
      markers.add(Marker(
        markerId: MarkerId(specialist['place_id']),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: specialist['name'],
          snippet: specialist['vicinity'],
        ),
        onTap: () => _showRouteToSpecialist(LatLng(lat, lng)), // Add this line to show route when marker tapped
      ));
    }
  }

  Future<void> _showRouteToSpecialist(LatLng specialistLocation) async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=$userLat,$userLng&destination=${specialistLocation.latitude},${specialistLocation.longitude}&mode=driving&key=$googleApiKey";

    print("Directions API URL: $url");

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Log the entire response for debugging
        print("Directions API Response: $data");

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0]['overview_polyline']['points'];

          // Check if polyline data is not empty
          if (route.isNotEmpty) {
            final decodedPolyline = _decodePolyline(route);

            setState(() {
              polylines.clear();
              polylines.add(
                Polyline(
                  polylineId: PolylineId("route_to_specialist"),
                  points: decodedPolyline,
                  color: Colors.blue,
                  width: 5,
                ),
              );
            });

            mapController.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(
                    userLat < specialistLocation.latitude ? userLat : specialistLocation.latitude,
                    userLng < specialistLocation.longitude ? userLng : specialistLocation.longitude,
                  ),
                  northeast: LatLng(
                    userLat > specialistLocation.latitude ? userLat : specialistLocation.latitude,
                    userLng > specialistLocation.longitude ? userLng : specialistLocation.longitude,
                  ),
                ),
                50.0,
              ),
            );
          } else {
            print("Polyline data is empty.");
          }
        } else {
          print("No routes found in the response.");
        }
      } else {
        print("Error fetching route: ${response.statusCode}, ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error fetching route: $e");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0;
      int b;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }
  String _calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    const double earthRadius = 6371.0; // Radius of the Earth in kilometers

    final double dLat = _degToRad(endLat - startLat);
    final double dLng = _degToRad(endLng - startLng);

    final double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
            cos(_degToRad(startLat)) * cos(_degToRad(endLat)) *
                (sin(dLng / 2) * sin(dLng / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return (earthRadius * c).toStringAsFixed(1); // Return as a String
  }


  double _degToRad(double degree) {
    return degree * pi / 180.0;
  }


  Widget _buildSpecialistList() {
    return ListView.builder(
      itemCount: specialists.length,
      itemBuilder: (context, index) {
        final specialist = specialists[index];
        final lat = specialist['geometry']['location']['lat'];
        final lng = specialist['geometry']['location']['lng'];
        final distance = _calculateDistance(userLat, userLng, lat, lng); // Distance is a string now
        final rating = specialist['rating'] ?? 0.0; // Default to 0.0 if no rating

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white, // Set the background color to white
            borderRadius: BorderRadius.circular(10), // Rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3), // Light shadow color
                spreadRadius: 2, // Spread radius of the shadow
                blurRadius: 5, // Blur effect of the shadow
                offset: Offset(0, 2), // Offset of the shadow (vertical)
              ),
            ],
          ),
          child: ListTile(
            leading: const Icon(Icons.local_hospital, color: Colors.red),
            title: Text(specialist['name']),
            subtitle: Text(specialist['vicinity']),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$distance km'), // Display the distance as a string
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rating.toString(), // Display the rating
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Icon(
                      Icons.star,
                      color: Colors.amber, // Gold color for the star
                      size: 16.0,
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultsDisplayPage(specialist: specialist),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.specialistType),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SlidingUpPanel(
        controller: panelController,
        panel: Column(
          children: [
            GestureDetector(
              onTap: () {
                if (panelController.isPanelOpen) {
                  panelController.close();
                } else {
                  panelController.open();
                }
              },
              child: Container(
                width: 50,
                height: 8,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Expanded(child: _buildSpecialistList()),
          ],
        ),
        body: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(userLat, userLng),
            zoom: 12.0,
          ),
          markers: markers,
          polylines: polylines,
          onMapCreated: (controller) {
            mapController = controller;
            mapController.setMapStyle(_mapStyle); // Apply the map style here
          },
        ),
        minHeight: 300.0,
        maxHeight: MediaQuery.of(context).size.height * 0.6,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
    );
  }
}
