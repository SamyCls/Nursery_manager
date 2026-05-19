import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/login.dart';
import 'screens/dashboard.dart';
import 'db/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop SQLite initialization — must happen first
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Open/create database
  await DatabaseHelper.instance.database;

  // Initialize French date formatting
  await initializeDateFormatting('fr_FR', null);
  runApp(const CrecheManagerApp());
}

class CrecheManagerApp extends StatelessWidget {
  const CrecheManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crèche Manager',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: "/login",
      routes: {
        "/login": (context) => const LoginScreen(),
        "/dashboard": (context) => DashboardPage(),
      },
    );
  }
}