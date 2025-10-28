import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart'; // o donde esté tu pantalla inicial
import 'services/notidication_services/Firebase_notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  // Asegurarse de que dotenv se cargue antes de correr la app
  await dotenv.load(fileName: ".env");
  FirebaseService.initialize();
   await initializeDateFormatting('es', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoluVa',
      debugShowCheckedModeBanner: false,
      home: const HomePage(), // o tu LoginScreen, etc.
    );
  }
}
