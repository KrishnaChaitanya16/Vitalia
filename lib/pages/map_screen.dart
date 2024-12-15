import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  final double lat;
  final double lng;
  final List hospitals;

  const MapScreen({
    Key? key,
    required this.lat,
    required this.lng,
    required this.hospitals,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _addMarkers();
  }

  void _addMarkers() {
    markers.add(Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(widget.lat, widget.lng),
      infoWindow: const InfoWindow(title: 'Your Location'),
    ));

    for (var hospital in widget.hospitals) {
      markers.add(Marker(
        markerId: MarkerId(hospital['place_id']),
        position: LatLng(
          hospital['geometry']['location']['lat'],
          hospital['geometry']['location']['lng'],
        ),
        infoWindow: InfoWindow(
          title: hospital['name'],
          snippet: hospital['vicinity'],
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Hospitals')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.lat, widget.lng),
                zoom: 14.0,
              ),
              markers: markers,
              onMapCreated: (controller) => mapController = controller,
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: widget.hospitals.length,
              itemBuilder: (context, index) {
                final hospital = widget.hospitals[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Icon(Icons.local_hospital, color: Colors.red),
                    title: Text(hospital['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hospital['vicinity']),
                        if (hospital.containsKey('rating'))
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16.0),
                              Text(' ${hospital['rating']} (${hospital['user_ratings_total']} reviews)'),
                            ],
                          ),
                        if (hospital['opening_hours']?['open_now'] != null)
                          Text(
                            hospital['opening_hours']['open_now']
                                ? 'Open Now'
                                : 'Closed',
                            style: TextStyle(
                              color: hospital['opening_hours']['open_now']
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
