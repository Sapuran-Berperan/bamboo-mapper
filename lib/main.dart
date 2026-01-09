import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/core/network/api_client.dart';
import 'src/core/network/network_monitor.dart';
import 'src/core/storage/token_storage.dart';
import 'src/core/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  // Initialize Supabase (still used for markers/images)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize API client and restore auth token if exists
  final accessToken = await TokenStorage.instance.getAccessToken();
  if (accessToken != null) {
    ApiClient.instance.setAuthToken(accessToken);
  }

  // Initialize offline services
  await NetworkMonitor.instance.initialize();

  // Initialize database (lazy initialization)
  AppDatabase();

  runApp(const MyApp());
}
