import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/horoscope_models.dart';
import '../../data/repositories/horoscope_repository.dart';

enum HoroscopeState { idle, loading, loaded, error }

class HoroscopeProvider extends ChangeNotifier {
  final HoroscopeRepository _repository;

  HoroscopeProvider({HoroscopeRepository? repository})
      : _repository = repository ?? HoroscopeRepository();

  HoroscopeState state = HoroscopeState.idle;
  String? errorMessage;
  DailyHoroscope? horoscope;
  List<ZodiacSignInfo> signs = [];

  int selectedSignIndex = 0;

  String? _activeKundliId;
  String? _userMoonRashi;

  String? get userMoonRashi => _userMoonRashi;
  String? get activeKundliId => _activeKundliId;

  bool get isLoading => state == HoroscopeState.loading;

  static const List<Map<String, String>> defaultSigns = [
    {'rashi': 'Mesha', 'english': 'Aries', 'symbol': '♈'},
    {'rashi': 'Vrishabha', 'english': 'Taurus', 'symbol': '♉'},
    {'rashi': 'Mithuna', 'english': 'Gemini', 'symbol': '♊'},
    {'rashi': 'Karka', 'english': 'Cancer', 'symbol': '♋'},
    {'rashi': 'Simha', 'english': 'Leo', 'symbol': '♌'},
    {'rashi': 'Kanya', 'english': 'Virgo', 'symbol': '♍'},
    {'rashi': 'Tula', 'english': 'Libra', 'symbol': '♎'},
    {'rashi': 'Vrishchika', 'english': 'Scorpio', 'symbol': '♏'},
    {'rashi': 'Dhanu', 'english': 'Sagittarius', 'symbol': '♐'},
    {'rashi': 'Makara', 'english': 'Capricorn', 'symbol': '♑'},
    {'rashi': 'Kumbha', 'english': 'Aquarius', 'symbol': '♒'},
    {'rashi': 'Meena', 'english': 'Pisces', 'symbol': '♓'},
  ];

  DateTime get selectedDate => DateTime.now();

  String get selectedDateFormatted => DateFormat('yyyy-MM-dd').format(selectedDate);
  String get displayDateHeader => DateFormat('EEEE, MMM d').format(selectedDate);

  Future<void> initialize({String? kundliId, String? moonRashi}) async {
    _activeKundliId = kundliId;
    _userMoonRashi = moonRashi;

    // If user has a moon sign in Kundli, set the selected sign to that index
    if (moonRashi != null && moonRashi.isNotEmpty) {
      final found = defaultSigns.indexWhere(
        (s) =>
            s['english']!.toLowerCase() == moonRashi.toLowerCase() ||
            s['rashi']!.toLowerCase() == moonRashi.toLowerCase(),
      );
      if (found >= 0) {
        selectedSignIndex = found;
      }
    }

    await loadHoroscope();
  }

  Future<void> selectSignIndex(int index) async {
    if (index < 0 || index >= defaultSigns.length) return;
    if (selectedSignIndex == index && horoscope != null) return;
    selectedSignIndex = index;
    notifyListeners();
    await loadHoroscope();
  }

  Future<void> loadHoroscope() async {
    state = HoroscopeState.loading;
    errorMessage = null;
    notifyListeners();

    final targetSign = defaultSigns[selectedSignIndex];
    final targetSignName = targetSign['english']!;
    final targetSignRashi = targetSign['rashi']!;

    final isUserOwnRashi = _userMoonRashi != null &&
        (_userMoonRashi!.toLowerCase() == targetSignName.toLowerCase() ||
         _userMoonRashi!.toLowerCase() == targetSignRashi.toLowerCase());

    try {
      final result = await _repository.getDailyHoroscope(
        sign: targetSignName,
        kundliId: isUserOwnRashi ? _activeKundliId : null,
        date: selectedDateFormatted,
      );

      horoscope = result;
      if (result.allSigns.isNotEmpty) {
        signs = result.allSigns;
      }
      state = HoroscopeState.loaded;
    } on ApiException catch (e) {
      errorMessage = e.message;
      state = HoroscopeState.error;
    } catch (e) {
      errorMessage = 'Could not load today\'s horoscope. Please check your connection.';
      state = HoroscopeState.error;
    }

    notifyListeners();
  }
}
