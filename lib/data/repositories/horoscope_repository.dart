import '../../core/network/api_client.dart';
import '../models/horoscope_models.dart';

class HoroscopeRepository {
  final ApiClient _client;

  HoroscopeRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<DailyHoroscope> getDailyHoroscope({
    String? sign,
    String? kundliId,
    String? date,
  }) async {
    final queryParams = <String, String>{};
    if (sign != null && sign.isNotEmpty) queryParams['sign'] = sign;
    if (kundliId != null && kundliId.isNotEmpty) queryParams['kundliId'] = kundliId;
    if (date != null && date.isNotEmpty) queryParams['date'] = date;

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    final json = await _client.get('/api/horoscope/daily$queryString');
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return DailyHoroscope.fromJson(data);
  }

  Future<List<ZodiacSignInfo>> getSigns() async {
    final json = await _client.get('/api/horoscope/signs');
    final list = json['signs'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ZodiacSignInfo.fromJson)
        .toList();
  }
}
