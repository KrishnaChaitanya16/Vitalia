import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '/pages/api_service.dart';
import '/providers/Location_provider.dart';

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

  Widget _buildSpecialistList() {
    return ListView.builder(
      itemCount: specialists.length,
      itemBuilder: (context, index) {
        final specialist = specialists[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: Icon(Icons.local_hospital, color: Colors.red),
            title: Text(specialist['name']),
            subtitle: Text(specialist['vicinity']),
            onTap: () => _showRouteToSpecialist(LatLng(
              specialist['geometry']['location']['lat'],
              specialist['geometry']['location']['lng'],
            )),
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
