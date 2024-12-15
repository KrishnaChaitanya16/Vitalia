import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String apiKey = 'AIzaSyBL4yd55ZMxeZ-_tOYY_jQeIF0Gbr5zIUc';

  static Future<List> fetchNearbyHospitals(double lat, double lng) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&type=hospital&key=$apiKey';
    print('Fetching hospitals from URL: $url'); // Debug statement
    final response = await http.get(Uri.parse(url));
    print('Response status code: ${response.statusCode}'); // Debug statement
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Response data: $data'); // Debug the API response
      if (data['status'] == 'OK') {
        print('Fetched ${data['results'].length} hospitals'); // Debug the number of results
        return data['results'];
      } else {
        print('API returned error: ${data['status']}'); // Debug API error status
        throw Exception('Error from API: ${data['status']}');
      }
    } else {
      throw Exception('Failed to load nearby hospitals');
    }
  }
  static Future<List> fetchNearbySpecialists(double lat, double lng, String specialistType) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&type=doctor&keyword=$specialistType&key=$apiKey';
    print('Fetching specialists from URL: $url'); // Debug statement
    final response = await http.get(Uri.parse(url));
    print('Response status code: ${response.statusCode}'); // Debug statement
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Response data: $data'); // Debug the API response
      if (data['status'] == 'OK') {
        print('Fetched ${data['results'].length} specialists'); // Debug the number of results
        return data['results'];
      } else {
        print('API returned error: ${data['status']}'); // Debug API error status
        throw Exception('Error from API: ${data['status']}');
      }
    } else {
      throw Exception('Failed to load nearby specialists');
    }
  }
}
