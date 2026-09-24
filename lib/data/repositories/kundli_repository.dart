import '../../core/network/api_client.dart';
import '../models/kundli_models.dart';

/// Talks only to `POST /api/kundli/generate` and
/// `PATCH /api/kundli/:kundliId` — the two existing Kundli endpoints this
/// app is scoped to use. No Swiss Ephemeris/GeoNames logic lives here or
/// anywhere in this app; the backend owns all of that.
class KundliRepository {
  final ApiClient _client;

  KundliRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<KundliData> generateKundli({
    required String name,
    required String dateOfBirth,
    String? timeOfBirth,
    required String birthPlace,
  }) async {
    final json = await _client.post('/api/kundli/generate', body: {
      'name': name,
      'dateOfBirth': dateOfBirth,
      if (timeOfBirth != null && timeOfBirth.isNotEmpty) 'timeOfBirth': timeOfBirth,
      'birthPlace': birthPlace,
    });
    return KundliData.fromJson((json['data'] as Map<String, dynamic>?) ?? const {});
  }

  /// Not currently wired into any screen (the spec's screens are
  /// Create/View/Delete, not Edit) — included for completeness of the
  /// repository layer against the existing backend contract, and ready to
  /// use if an edit flow is added later without touching the network
  /// layer again.
  Future<KundliData> updateKundli({
    required String kundliId,
    String? name,
    String? dateOfBirth,
    String? timeOfBirth,
    String? birthPlace,
  }) async {
    final json = await _client.patch('/api/kundli/$kundliId', body: {
      if (name != null) 'name': name,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (timeOfBirth != null) 'timeOfBirth': timeOfBirth,
      if (birthPlace != null) 'birthPlace': birthPlace,
    });
    return KundliData.fromJson((json['data'] as Map<String, dynamic>?) ?? const {});
  }

  Future<bool> deleteAccountData(String kundliId) async {
    try {
      final json = await _client.delete('/api/kundli/$kundliId');
      return json['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
