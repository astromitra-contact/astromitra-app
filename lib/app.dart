import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/credit_provider.dart';
import 'presentation/providers/horoscope_provider.dart';
import 'presentation/providers/kundli_provider.dart';
import 'presentation/screens/splash_screen.dart';

class AstroMitraApp extends StatelessWidget {
  const AstroMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => KundliProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CreditProvider()),
        ChangeNotifierProvider(create: (_) => HoroscopeProvider()),
      ],
      child: MaterialApp(
        title: 'AstroMitra',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
      ),
    );
  }
}
