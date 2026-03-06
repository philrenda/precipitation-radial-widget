import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _nominatimUrl =
      'https://nominatim.openstreetmap.org/reverse';

  /// Reverse geocodes a lat/lon into a short location name.
  /// Returns city/town/village name, or "lat, lon" as fallback.
  Future<String> reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        '$_nominatimUrl?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'PrecipitationRadialWidget/1.0',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final address = json['address'] as Map<String, dynamic>?;
      if (address == null) {
        return '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';
      }

      // Try city, town, village, hamlet, suburb in order
      for (final key in [
        'city',
        'town',
        'village',
        'hamlet',
        'suburb',
        'county'
      ]) {
        if (address.containsKey(key)) {
          return address[key] as String;
        }
      }

      return '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';
    } catch (_) {
      return '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';
    }
  }
}
