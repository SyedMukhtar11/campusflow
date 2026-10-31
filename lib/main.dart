import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/api_config.dart';
import 'providers/auth_provider.dart';
import 'providers/program_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_gate.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/program_service.dart';
import 'services/session_storage.dart';
import 'utils/app_theme.dart';

void main() {
  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        // Authentication session & logged in user profile
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Programs, registrations, notifications and feedback.
        ChangeNotifierProvider(
          create: (_) => ProgramProvider(service: ProgramService(api: apiClient)),
          lazy: false,
        ),
        // Light / dark mode.
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Login state. Demo login unless the app is run with USE_API=true.
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            service: ApiConfig.useApi
                ? ApiAuthService(apiClient)
                : const MockAuthService(),
            storage: SharedPrefsSessionStorage(),
            client: apiClient,
          ),
        ),
      ],
      child: const CampusFlowApp(),
    ),
  );
}

/// Root widget: sets the app title, the light and dark themes and the first screen.
class CampusFlowApp extends StatelessWidget {
  /// Set to false in tests, where Google Fonts cannot be downloaded.
  final bool useGoogleFonts;

  const CampusFlowApp({super.key, this.useGoogleFonts = true});

  @override
  Widget build(BuildContext context) {
    // Rebuild only when the user switches between light and dark mode.
    final themeMode = context.select<ThemeProvider, ThemeMode>((t) => t.mode);

    return MaterialApp(
      title: 'CampusFlow',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(useGoogleFonts: useGoogleFonts),
      darkTheme: buildDarkTheme(useGoogleFonts: useGoogleFonts),
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}
