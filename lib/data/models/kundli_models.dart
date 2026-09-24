/// Models mirror the EXACT shape returned by `POST /api/kundli/generate`
/// and `PATCH /api/kundli/:kundliId` as verified directly against the
/// backend source (`astrology.service.js`, `kundli.service.js`) — not
/// assumed. Every field read defensively (null-safe with fallbacks) since
/// a schema is still just a contract; a resilient client shouldn't crash
/// if a field is ever missing or the backend adds new ones.
library;

class KundliData {
  final String? kundliId;
  final bool stored;
  final BirthDetails birthDetails;
  final TimeAccuracy? timeAccuracy;
  final KundliLocation? location;
  final CalculationSettings? calculationSettings;
  final LagnaInfo? lagna;
  final List<HouseInfo> houses;
  final List<PlanetInfo> planets;
  final String? generatedAt;
  final Map<String, dynamic> raw;

  KundliData({
    required this.kundliId,
    required this.stored,
    required this.birthDetails,
    required this.timeAccuracy,
    required this.location,
    required this.calculationSettings,
    required this.lagna,
    required this.houses,
    required this.planets,
    required this.generatedAt,
    required this.raw,
  });

  factory KundliData.fromJson(Map<String, dynamic> json) {
    return KundliData(
      kundliId: json['kundliId'] as String?,
      stored: json['stored'] == true,
      birthDetails: BirthDetails.fromJson(
        (json['birthDetails'] as Map<String, dynamic>?) ?? const {},
      ),
      timeAccuracy: json['timeAccuracy'] is Map<String, dynamic>
          ? TimeAccuracy.fromJson(json['timeAccuracy'] as Map<String, dynamic>)
          : null,
      location: json['location'] is Map<String, dynamic>
          ? KundliLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      calculationSettings: json['calculationSettings'] is Map<String, dynamic>
          ? CalculationSettings.fromJson(json['calculationSettings'] as Map<String, dynamic>)
          : null,
      lagna: json['lagna'] is Map<String, dynamic>
          ? LagnaInfo.fromJson(json['lagna'] as Map<String, dynamic>)
          : null,
      houses: (json['houses'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(HouseInfo.fromJson)
          .toList(),
      planets: (json['planets'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PlanetInfo.fromJson)
          .toList(),
      generatedAt: json['generatedAt'] as String?,
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

class BirthDetails {
  final String name;
  final String dateOfBirth;
  final String? timeOfBirth;
  final String birthPlace;

  BirthDetails({
    required this.name,
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.birthPlace,
  });

  factory BirthDetails.fromJson(Map<String, dynamic> json) => BirthDetails(
        name: (json['name'] as String?) ?? '',
        dateOfBirth: (json['dateOfBirth'] as String?) ?? '',
        timeOfBirth: json['timeOfBirth'] as String?,
        birthPlace: (json['birthPlace'] as String?) ?? '',
      );
}

class TimeAccuracy {
  final bool isExact;
  final String timeUsedForCalculation;
  final String note;

  TimeAccuracy({required this.isExact, required this.timeUsedForCalculation, required this.note});

  factory TimeAccuracy.fromJson(Map<String, dynamic> json) => TimeAccuracy(
        isExact: json['isExact'] == true,
        timeUsedForCalculation: (json['timeUsedForCalculation'] as String?) ?? '',
        note: (json['note'] as String?) ?? '',
      );
}

class KundliLocation {
  final String city;
  final String? state;
  final String country;
  final double? latitude;
  final double? longitude;
  final String timezone;

  KundliLocation({
    required this.city,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

  factory KundliLocation.fromJson(Map<String, dynamic> json) => KundliLocation(
        city: (json['city'] as String?) ?? '',
        state: json['state'] as String?,
        country: (json['country'] as String?) ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        timezone: (json['timezone'] as String?) ?? '',
      );

  String get displayString => [city, if (state != null && state!.isNotEmpty) state!, country]
      .where((s) => s.isNotEmpty)
      .join(', ');
}

class CalculationSettings {
  final String zodiac;
  final String ayanamsa;
  final double? ayanamsaValue;
  final String? houseSystem;
  final String? ephemeris;

  CalculationSettings({
    required this.zodiac,
    required this.ayanamsa,
    required this.ayanamsaValue,
    required this.houseSystem,
    required this.ephemeris,
  });

  factory CalculationSettings.fromJson(Map<String, dynamic> json) => CalculationSettings(
        zodiac: (json['zodiac'] as String?) ?? 'sidereal',
        ayanamsa: (json['ayanamsa'] as String?) ?? '',
        ayanamsaValue: (json['ayanamsaValue'] as num?)?.toDouble(),
        houseSystem: json['houseSystem'] as String?,
        ephemeris: json['ephemeris'] as String?,
      );
}

class LagnaInfo {
  final double longitude;
  final String rashi;
  final String rashiEnglish;
  final String rashiLord;
  final double degreeInRashi;
  final String nakshatra;
  final String nakshatraLord;
  final int pada;

  LagnaInfo({
    required this.longitude,
    required this.rashi,
    required this.rashiEnglish,
    required this.rashiLord,
    required this.degreeInRashi,
    required this.nakshatra,
    required this.nakshatraLord,
    required this.pada,
  });

  factory LagnaInfo.fromJson(Map<String, dynamic> json) => LagnaInfo(
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        rashi: (json['rashi'] as String?) ?? '',
        rashiEnglish: (json['rashiEnglish'] as String?) ?? '',
        rashiLord: (json['rashiLord'] as String?) ?? '',
        degreeInRashi: (json['degreeInRashi'] as num?)?.toDouble() ?? 0,
        nakshatra: (json['nakshatra'] as String?) ?? '',
        nakshatraLord: (json['nakshatraLord'] as String?) ?? '',
        pada: (json['pada'] as num?)?.toInt() ?? 0,
      );
}

class HouseInfo {
  final int houseNumber;
  final String rashi;
  final String rashiEnglish;
  final String rashiLord;

  HouseInfo({
    required this.houseNumber,
    required this.rashi,
    required this.rashiEnglish,
    required this.rashiLord,
  });

  factory HouseInfo.fromJson(Map<String, dynamic> json) => HouseInfo(
        houseNumber: (json['houseNumber'] as num?)?.toInt() ?? 0,
        rashi: (json['rashi'] as String?) ?? '',
        rashiEnglish: (json['rashiEnglish'] as String?) ?? '',
        rashiLord: (json['rashiLord'] as String?) ?? '',
      );
}

class PlanetInfo {
  final String key;
  final String name;
  final double degreeInRashi;
  final bool isRetrograde;
  final String rashi;
  final String rashiEnglish;
  final String nakshatra;
  final int pada;
  final int houseNumber;

  PlanetInfo({
    required this.key,
    required this.name,
    required this.degreeInRashi,
    required this.isRetrograde,
    required this.rashi,
    required this.rashiEnglish,
    required this.nakshatra,
    required this.pada,
    required this.houseNumber,
  });

  factory PlanetInfo.fromJson(Map<String, dynamic> json) => PlanetInfo(
        key: (json['key'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        degreeInRashi: (json['degreeInRashi'] as num?)?.toDouble() ?? 0,
        isRetrograde: json['isRetrograde'] == true,
        rashi: (json['rashi'] as String?) ?? '',
        rashiEnglish: (json['rashiEnglish'] as String?) ?? '',
        nakshatra: (json['nakshatra'] as String?) ?? '',
        pada: (json['pada'] as num?)?.toInt() ?? 0,
        houseNumber: (json['houseNumber'] as num?)?.toInt() ?? 0,
      );
}
