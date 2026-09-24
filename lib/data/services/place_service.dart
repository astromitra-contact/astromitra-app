import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../models/place_suggestion.dart';

class PlaceService {
  final http.Client _client;

  PlaceService({http.Client? client}) : _client = client ?? http.Client();

  static const List<PlaceSuggestion> popularCities = [
    PlaceSuggestion(displayName: 'Surat, Gujarat, India', city: 'Surat', state: 'Gujarat', country: 'India'),
    PlaceSuggestion(displayName: 'Mumbai, Maharashtra, India', city: 'Mumbai', state: 'Maharashtra', country: 'India'),
    PlaceSuggestion(displayName: 'Delhi, India', city: 'Delhi', state: 'Delhi', country: 'India'),
    PlaceSuggestion(displayName: 'Bengaluru, Karnataka, India', city: 'Bengaluru', state: 'Karnataka', country: 'India'),
    PlaceSuggestion(displayName: 'Ahmedabad, Gujarat, India', city: 'Ahmedabad', state: 'Gujarat', country: 'India'),
    PlaceSuggestion(displayName: 'Pune, Maharashtra, India', city: 'Pune', state: 'Maharashtra', country: 'India'),
    PlaceSuggestion(displayName: 'Jaipur, Rajasthan, India', city: 'Jaipur', state: 'Rajasthan', country: 'India'),
    PlaceSuggestion(displayName: 'Hyderabad, Telangana, India', city: 'Hyderabad', state: 'Telangana', country: 'India'),
    PlaceSuggestion(displayName: 'Kolkata, West Bengal, India', city: 'Kolkata', state: 'West Bengal', country: 'India'),
    PlaceSuggestion(displayName: 'Chennai, Tamil Nadu, India', city: 'Chennai', state: 'Tamil Nadu', country: 'India'),
    PlaceSuggestion(displayName: 'Varanasi, Uttar Pradesh, India', city: 'Varanasi', state: 'Uttar Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Lucknow, Uttar Pradesh, India', city: 'Lucknow', state: 'Uttar Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Indore, Madhya Pradesh, India', city: 'Indore', state: 'Madhya Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'London, United Kingdom', city: 'London', country: 'United Kingdom'),
    PlaceSuggestion(displayName: 'New York, United States', city: 'New York', country: 'United States'),
    PlaceSuggestion(displayName: 'Dubai, United Arab Emirates', city: 'Dubai', country: 'United Arab Emirates'),
  ];

  static const List<PlaceSuggestion> _curatedDataset = [
    ...popularCities,
    PlaceSuggestion(displayName: 'Agra, Uttar Pradesh, India', city: 'Agra', state: 'Uttar Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Ajmer, Rajasthan, India', city: 'Ajmer', state: 'Rajasthan', country: 'India'),
    PlaceSuggestion(displayName: 'Aligarh, Uttar Pradesh, India', city: 'Aligarh', state: 'Uttar Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Amravati, Maharashtra, India', city: 'Amravati', state: 'Maharashtra', country: 'India'),
    PlaceSuggestion(displayName: 'Amritsar, Punjab, India', city: 'Amritsar', state: 'Punjab', country: 'India'),
    PlaceSuggestion(displayName: 'Asansol, West Bengal, India', city: 'Asansol', state: 'West Bengal', country: 'India'),
    PlaceSuggestion(displayName: 'Aurangabad, Maharashtra, India', city: 'Aurangabad', state: 'Maharashtra', country: 'India'),
    PlaceSuggestion(displayName: 'Ayodhya, Uttar Pradesh, India', city: 'Ayodhya', state: 'Uttar Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Bareilly, Uttar Pradesh, India', city: 'Bareilly', state: 'Uttar Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Belgaum, Karnataka, India', city: 'Belgaum', state: 'Karnataka', country: 'India'),
    PlaceSuggestion(displayName: 'Bhavnagar, Gujarat, India', city: 'Bhavnagar', state: 'Gujarat', country: 'India'),
    PlaceSuggestion(displayName: 'Bhilai, Chhattisgarh, India', city: 'Bhilai', state: 'Chhattisgarh', country: 'India'),
    PlaceSuggestion(displayName: 'Bhopal, Madhya Pradesh, India', city: 'Bhopal', state: 'Madhya Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Bhubaneswar, Odisha, India', city: 'Bhubaneswar', state: 'Odisha', country: 'India'),
    PlaceSuggestion(displayName: 'Bikaner, Rajasthan, India', city: 'Bikaner', state: 'Rajasthan', country: 'India'),
    PlaceSuggestion(displayName: 'Chandigarh, India', city: 'Chandigarh', state: 'Chandigarh', country: 'India'),
    PlaceSuggestion(displayName: 'Coimbatore, Tamil Nadu, India', city: 'Coimbatore', state: 'Tamil Nadu', country: 'India'),
    PlaceSuggestion(displayName: 'Cuttack, Odisha, India', city: 'Cuttack', state: 'Odisha', country: 'India'),
    PlaceSuggestion(displayName: 'Dehradun, Uttarakhand, India', city: 'Dehradun', state: 'Uttarakhand', country: 'India'),
    PlaceSuggestion(displayName: 'Dhanbad, Jharkhand, India', city: 'Dhanbad', state: 'Jharkhand', country: 'India'),
    PlaceSuggestion(displayName: 'Faridabad, Haryana, India', city: 'Faridabad', state: 'Haryana', country: 'India'),
    PlaceSuggestion(displayName: 'Gandhinagar, Gujarat, India', city: 'Gandhinagar', state: 'Gujarat', country: 'India'),
    PlaceSuggestion(displayName: 'Ghaziabad, Uttar Pradesh, India', city: 'Ghaziabad', state: 'Uttar Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Gorakhpur, Uttar Pradesh, India', city: 'Gorakhpur', state: 'Uttar Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Gurgaon, Haryana, India', city: 'Gurgaon', state: 'Haryana', country: 'India'),
    PlaceSuggestion(displayName: 'Guwahati, Assam, India', city: 'Guwahati', state: 'Assam', country: 'India'),
    PlaceSuggestion(displayName: 'Gwalior, Madhya Pradesh, India', city: 'Gwalior', state: 'Madhya Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Haridwar, Uttarakhand, India', city: 'Haridwar', state: 'Uttarakhand', country: 'India'),
    PlaceSuggestion(displayName: 'Howrah, West Bengal, India', city: 'Howrah', state: 'West Bengal', country: 'India'),
    PlaceSuggestion(displayName: 'Hubballi, Karnataka, India', city: 'Hubballi', state: 'Karnataka', country: 'India'),
    PlaceSuggestion(displayName: 'Jabalpur, Madhya Pradesh, India', city: 'Jabalpur', state: 'Madhya Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Jalandhar, Punjab, India', city: 'Jalandhar', state: 'Punjab', country: 'India'),
    PlaceSuggestion(displayName: 'Jamnagar, Gujarat, India', city: 'Jamnagar', state: 'Gujarat', country: 'India'),
    PlaceSuggestion(displayName: 'Jamshedpur, Jharkhand, India', city: 'Jamshedpur', state: 'Jharkhand', country: 'India'),
    PlaceSuggestion(displayName: 'Jhansi, Uttar Pradesh, India', city: 'Jhansi', state: 'Uttar Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Jodhpur, Rajasthan, India', city: 'Jodhpur', state: 'Rajasthan', country: 'India'),
    PlaceSuggestion(displayName: 'Kanpur, Uttar Pradesh, India', city: 'Kanpur', state: 'Uttar Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Kochi, Kerala, India', city: 'Kochi', state: 'Kerala', country: 'India'),
    PlaceSuggestion(displayName: 'Kolhapur, Maharashtra, India', city: 'Kolhapur', state: 'Maharashtra', country: 'India'),
    PlaceSuggestion(displayName: 'Kota, Rajasthan, India', city: 'Kota', state: 'Rajasthan', country: 'India'),
    PlaceSuggestion(displayName: 'Ludhiana, Punjab, India', city: 'Ludhiana', state: 'Punjab', country: 'India'),
    PlaceSuggestion(displayName: 'Madurai, Tamil Nadu, India', city: 'Madurai', state: 'Tamil Nadu', country: 'India'),
    PlaceSuggestion(displayName: 'Mangalore, Karnataka, India', city: 'Mangalore', state: 'Karnataka', country: 'India'),
    PlaceSuggestion(displayName: 'Mathura, Uttar Pradesh, India', city: 'Mathura', state: 'Uttar Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Meerut, Uttar Pradesh, India', city: 'Meerut', state: 'Uttar Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Moradabad, Uttar Pradesh, India', city: 'Moradabad', state: 'Uttar Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Mysore, Karnataka, India', city: 'Mysore', state: 'Karnataka', country: 'India'),
    PlaceSuggestion(displayName: 'Nagpur, Maharashtra, India', city: 'Nagpur', state: 'Maharashtra', country: 'India'),
    PlaceSuggestion(displayName: 'Nashik, Maharashtra, India', city: 'Nashik', state: 'Maharashtra', country: 'India'),
    PlaceSuggestion(displayName: 'Navi Mumbai, Maharashtra, India', city: 'Navi Mumbai', state: 'Maharashtra', country: 'India'),
    PlaceSuggestion(displayName: 'Noida, Uttar Pradesh, India', city: 'Noida', state: 'Uttar Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Patna, Bihar, India', city: 'Patna', state: 'Bihar', country: 'India'),
    PlaceSuggestion(displayName: 'Prayagraj, Uttar Pradesh, India', city: 'Prayagraj', state: 'Uttar Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Raipur, Chhattisgarh, India', city: 'Raipur', state: 'Chhattisgarh', country: 'India'),
    PlaceSuggestion(displayName: 'Rajkot, Gujarat, India', city: 'Rajkot', state: 'Gujarat', country: 'India'),
    PlaceSuggestion(displayName: 'Ranchi, Jharkhand, India', city: 'Ranchi', state: 'Jharkhand', country: 'India'),
    PlaceSuggestion(displayName: 'Rishikesh, Uttarakhand, India', city: 'Rishikesh', state: 'Uttarakhand', country: 'India'),
    PlaceSuggestion(displayName: 'Rourkela, Odisha, India', city: 'Rourkela', state: 'Odisha', country: 'India'),
    PlaceSuggestion(displayName: 'Salem, Tamil Nadu, India', city: 'Salem', state: 'Tamil Nadu', country: 'India'),
    PlaceSuggestion(displayName: 'Shirdi, Maharashtra, India', city: 'Shirdi', state: 'Maharashtra', country: 'India'),
    PlaceSuggestion(displayName: 'Srinagar, Jammu & Kashmir, India', city: 'Srinagar', state: 'Jammu & Kashmir', country: 'India'),
    PlaceSuggestion(displayName: 'Thane, Maharashtra, India', city: 'Thane', state: 'Maharashtra', country: 'India'),
    PlaceSuggestion(displayName: 'Thiruvananthapuram, Kerala, India', city: 'Thiruvananthapuram', state: 'Kerala', country: 'India'),
    PlaceSuggestion(displayName: 'Tirupati, Andhra Pradesh, India', city: 'Tirupati', state: 'Andhra Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Udaipur, Rajasthan, India', city: 'Udaipur', state: 'Rajasthan', country: 'India'),
    PlaceSuggestion(displayName: 'Ujjain, Madhya Pradesh, India', city: 'Ujjain', state: 'Madhya Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Vadodara, Gujarat, India', city: 'Vadodara', state: 'Gujarat', country: 'India'),
    PlaceSuggestion(displayName: 'Vijayawada, Andhra Pradesh, India', city: 'Vijayawada', state: 'Andhra Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Visakhapatnam, Andhra Pradesh, India', city: 'Visakhapatnam', state: 'Andhra Pradesh', country: 'India'),
    PlaceSuggestion(displayName: 'Warangal, Telangana, India', city: 'Warangal', state: 'Telangana', country: 'India'),
    // International Major Cities
    PlaceSuggestion(displayName: 'Auckland, New Zealand', city: 'Auckland', country: 'New Zealand'),
    PlaceSuggestion(displayName: 'Austin, Texas, United States', city: 'Austin', state: 'Texas', country: 'United States'),
    PlaceSuggestion(displayName: 'Bangkok, Thailand', city: 'Bangkok', country: 'Thailand'),
    PlaceSuggestion(displayName: 'Berlin, Germany', city: 'Berlin', country: 'Germany'),
    PlaceSuggestion(displayName: 'Boston, Massachusetts, United States', city: 'Boston', state: 'Massachusetts', country: 'United States'),
    PlaceSuggestion(displayName: 'Calgary, Canada', city: 'Calgary', country: 'Canada'),
    PlaceSuggestion(displayName: 'Chicago, Illinois, United States', city: 'Chicago', state: 'Illinois', country: 'United States'),
    PlaceSuggestion(displayName: 'Colombo, Sri Lanka', city: 'Colombo', country: 'Sri Lanka'),
    PlaceSuggestion(displayName: 'Dallas, Texas, United States', city: 'Dallas', state: 'Texas', country: 'United States'),
    PlaceSuggestion(displayName: 'Dhaka, Bangladesh', city: 'Dhaka', country: 'Bangladesh'),
    PlaceSuggestion(displayName: 'Dubai, United Arab Emirates', city: 'Dubai', country: 'United Arab Emirates'),
    PlaceSuggestion(displayName: 'Dublin, Ireland', city: 'Dublin', country: 'Ireland'),
    PlaceSuggestion(displayName: 'Frankfurt, Germany', city: 'Frankfurt', country: 'Germany'),
    PlaceSuggestion(displayName: 'Houston, Texas, United States', city: 'Houston', state: 'Texas', country: 'United States'),
    PlaceSuggestion(displayName: 'Johannesburg, South Africa', city: 'Johannesburg', country: 'South Africa'),
    PlaceSuggestion(displayName: 'Kathmandu, Nepal', city: 'Kathmandu', country: 'Nepal'),
    PlaceSuggestion(displayName: 'Kuala Lumpur, Malaysia', city: 'Kuala Lumpur', country: 'Malaysia'),
    PlaceSuggestion(displayName: 'London, United Kingdom', city: 'London', country: 'United Kingdom'),
    PlaceSuggestion(displayName: 'Los Angeles, California, United States', city: 'Los Angeles', state: 'California', country: 'United States'),
    PlaceSuggestion(displayName: 'Melbourne, Australia', city: 'Melbourne', country: 'Australia'),
    PlaceSuggestion(displayName: 'Miami, Florida, United States', city: 'Miami', state: 'Florida', country: 'United States'),
    PlaceSuggestion(displayName: 'Montreal, Canada', city: 'Montreal', country: 'Canada'),
    PlaceSuggestion(displayName: 'New York, United States', city: 'New York', country: 'United States'),
    PlaceSuggestion(displayName: 'Paris, France', city: 'Paris', country: 'France'),
    PlaceSuggestion(displayName: 'Perth, Australia', city: 'Perth', country: 'Australia'),
    PlaceSuggestion(displayName: 'Rome, Italy', city: 'Rome', country: 'Italy'),
    PlaceSuggestion(displayName: 'San Francisco, California, United States', city: 'San Francisco', state: 'California', country: 'United States'),
    PlaceSuggestion(displayName: 'Seattle, Washington, United States', city: 'Seattle', state: 'Washington', country: 'United States'),
    PlaceSuggestion(displayName: 'Singapore', city: 'Singapore', country: 'Singapore'),
    PlaceSuggestion(displayName: 'Sydney, Australia', city: 'Sydney', country: 'Australia'),
    PlaceSuggestion(displayName: 'Tokyo, Japan', city: 'Tokyo', country: 'Japan'),
    PlaceSuggestion(displayName: 'Toronto, Canada', city: 'Toronto', country: 'Canada'),
    PlaceSuggestion(displayName: 'Vancouver, Canada', city: 'Vancouver', country: 'Canada'),
  ];

  Future<List<PlaceSuggestion>> search(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return popularCities;
    }

    final localMatches = _curatedDataset.where((p) {
      return p.displayName.toLowerCase().contains(cleanQuery) ||
          p.city.toLowerCase().contains(cleanQuery) ||
          (p.state?.toLowerCase().contains(cleanQuery) ?? false);
    }).toList();

    // If query is very short (< 2 chars), local matches are sufficient and fastest
    if (cleanQuery.length < 2) {
      return localMatches;
    }

    // Try Backend API places endpoint first
    try {
      final backendResults = await _searchBackend(cleanQuery);
      if (backendResults.isNotEmpty) {
        return _mergeUnique(backendResults, localMatches);
      }
    } catch (_) {
      // Ignore backend failures and fallback
    }

    // Try OpenStreetMap Nominatim
    try {
      final osmResults = await _searchNominatim(cleanQuery);
      if (osmResults.isNotEmpty) {
        return _mergeUnique(osmResults, localMatches);
      }
    } catch (_) {
      // Ignore network errors
    }

    return localMatches;
  }

  Future<List<PlaceSuggestion>> _searchBackend(String query) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/kundli/places?q=${Uri.encodeComponent(query)}');
    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['places'] is List) {
        return (data['places'] as List)
            .map((item) => PlaceSuggestion.fromJson(item as Map<String, dynamic>))
            .where((p) => p.displayName.isNotEmpty)
            .toList();
      }
    }
    return [];
  }

  Future<List<PlaceSuggestion>> _searchNominatim(String query) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=6&featuretype=settlement',
    );
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'AstroMitraApp/1.0 (contact@astromitra.com)',
      },
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      final results = <PlaceSuggestion>[];
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final addr = item['address'] as Map<String, dynamic>? ?? {};
          final city = addr['city'] as String? ??
              addr['town'] as String? ??
              addr['village'] as String? ??
              addr['municipality'] as String? ??
              item['name'] as String? ??
              '';
          final state = addr['state'] as String?;
          final country = addr['country'] as String?;
          final parts = [city, state, country].where((s) => s != null && s.isNotEmpty).toList();
          final displayName = parts.isNotEmpty ? parts.join(', ') : (item['display_name'] as String? ?? '');

          if (displayName.isNotEmpty) {
            results.add(PlaceSuggestion(
              displayName: displayName,
              city: city,
              state: state,
              country: country,
            ));
          }
        }
      }
      return results;
    }
    return [];
  }

  List<PlaceSuggestion> _mergeUnique(List<PlaceSuggestion> primary, List<PlaceSuggestion> secondary) {
    final seen = <String>{};
    final list = <PlaceSuggestion>[];

    for (final item in [...primary, ...secondary]) {
      final key = item.displayName.toLowerCase().trim();
      if (!seen.contains(key)) {
        seen.add(key);
        list.add(item);
      }
    }
    return list;
  }
}
