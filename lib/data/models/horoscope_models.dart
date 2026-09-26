/// Models representing Daily Horoscope and Zodiac information returned by
/// the AstroMitra backend (`/api/horoscope/daily`).
library;

class DailyHoroscope {
  final String date;
  final String dayName;
  final String sign;
  final String rashi;
  final String symbol;
  final String element;
  final String quality;
  final String rashiLord;
  final String dates;
  final bool isPersonalized;
  final String? userName;
  final String? userMoonRashi;
  final String? userLagna;
  final String theme;
  final String overview;
  final String love;
  final String career;
  final String finance;
  final String health;
  final String cosmicTip;
  final String luckyColor;
  final dynamic luckyNumber;
  final String luckyTime;
  final HoroscopeScores scores;
  final TransitDetails transitDetails;
  final List<ZodiacSignInfo> allSigns;

  DailyHoroscope({
    required this.date,
    required this.dayName,
    required this.sign,
    required this.rashi,
    required this.symbol,
    required this.element,
    required this.quality,
    required this.rashiLord,
    required this.dates,
    required this.isPersonalized,
    required this.userName,
    required this.userMoonRashi,
    required this.userLagna,
    required this.theme,
    required this.overview,
    required this.love,
    required this.career,
    required this.finance,
    required this.health,
    required this.cosmicTip,
    required this.luckyColor,
    required this.luckyNumber,
    required this.luckyTime,
    required this.scores,
    required this.transitDetails,
    required this.allSigns,
  });

  factory DailyHoroscope.fromJson(Map<String, dynamic> json) {
    return DailyHoroscope(
      date: (json['date'] as String?) ?? '',
      dayName: (json['dayName'] as String?) ?? '',
      sign: (json['sign'] as String?) ?? '',
      rashi: (json['rashi'] as String?) ?? '',
      symbol: (json['symbol'] as String?) ?? '♈',
      element: (json['element'] as String?) ?? '',
      quality: (json['quality'] as String?) ?? '',
      rashiLord: (json['rashiLord'] as String?) ?? '',
      dates: (json['dates'] as String?) ?? '',
      isPersonalized: json['isPersonalized'] == true,
      userName: json['userName'] as String?,
      userMoonRashi: json['userMoonRashi'] as String?,
      userLagna: json['userLagna'] as String?,
      theme: (json['theme'] as String?) ?? 'Cosmic Guidance & Reflection',
      overview: (json['overview'] as String?) ?? '',
      love: (json['love'] as String?) ?? '',
      career: (json['career'] as String?) ?? '',
      finance: (json['finance'] as String?) ?? '',
      health: (json['health'] as String?) ?? '',
      cosmicTip: (json['cosmicTip'] as String?) ?? '',
      luckyColor: (json['luckyColor'] as String?) ?? 'Gold',
      luckyNumber: json['luckyNumber'] ?? 7,
      luckyTime: (json['luckyTime'] as String?) ?? '10:00 AM - 11:30 AM',
      scores: HoroscopeScores.fromJson(
        (json['scores'] as Map<String, dynamic>?) ?? const {},
      ),
      transitDetails: TransitDetails.fromJson(
        (json['transitDetails'] as Map<String, dynamic>?) ?? const {},
      ),
      allSigns: (json['allSigns'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ZodiacSignInfo.fromJson)
          .toList(),
    );
  }
}

class HoroscopeScores {
  final int overall;
  final int love;
  final int career;
  final int health;
  final int finance;

  HoroscopeScores({
    required this.overall,
    required this.love,
    required this.career,
    required this.health,
    required this.finance,
  });

  factory HoroscopeScores.fromJson(Map<String, dynamic> json) => HoroscopeScores(
        overall: (json['overall'] as num?)?.toInt() ?? 85,
        love: (json['love'] as num?)?.toInt() ?? 80,
        career: (json['career'] as num?)?.toInt() ?? 85,
        health: (json['health'] as num?)?.toInt() ?? 80,
        finance: (json['finance'] as num?)?.toInt() ?? 80,
      );
}

class TransitDetails {
  final int moonHouse;
  final String moonSign;
  final String moonNakshatra;
  final String tithi;
  final String dayLord;
  final String transitSummary;

  TransitDetails({
    required this.moonHouse,
    required this.moonSign,
    required this.moonNakshatra,
    required this.tithi,
    required this.dayLord,
    required this.transitSummary,
  });

  factory TransitDetails.fromJson(Map<String, dynamic> json) => TransitDetails(
        moonHouse: (json['moonHouse'] as num?)?.toInt() ?? 1,
        moonSign: (json['moonSign'] as String?) ?? '',
        moonNakshatra: (json['moonNakshatra'] as String?) ?? '',
        tithi: (json['tithi'] as String?) ?? '',
        dayLord: (json['dayLord'] as String?) ?? '',
        transitSummary: (json['transitSummary'] as String?) ?? '',
      );
}

class ZodiacSignInfo {
  final int index;
  final String rashi;
  final String english;
  final String symbol;
  final String element;
  final String lord;
  final String dates;

  ZodiacSignInfo({
    required this.index,
    required this.rashi,
    required this.english,
    required this.symbol,
    required this.element,
    required this.lord,
    required this.dates,
  });

  factory ZodiacSignInfo.fromJson(Map<String, dynamic> json) => ZodiacSignInfo(
        index: (json['index'] as num?)?.toInt() ?? 0,
        rashi: (json['rashi'] as String?) ?? '',
        english: (json['english'] as String?) ?? '',
        symbol: (json['symbol'] as String?) ?? '♈',
        element: (json['element'] as String?) ?? '',
        lord: (json['lord'] as String?) ?? '',
        dates: (json['dates'] as String?) ?? '',
      );
}
