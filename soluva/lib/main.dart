import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soluva/screens/delete_account_confirm_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Error cargando .env: $e');
  }

  await initializeDateFormatting('es', null);
  await AuthService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Link inicial (app abierta desde enlace cuando estaba cerrada)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (_) {}

    // Links recibidos mientras la app está en primer o segundo plano
    _linkSub = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (_) {},
    );
  }

  void _handleDeepLink(Uri uri) {
    if (uri.path == '/confirm-delete') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => DeleteAccountConfirmScreen(token: token),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoluVa',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      home: const HomePage(),
    );
  }
}
