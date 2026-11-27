import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/supabase_service.dart';
import 'data/services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase when configured via --dart-define
  await SupabaseService.initialize();

  // Preserve fallback service status check
  await FirebaseService.initialize();

  runApp(
    const ProviderScope(
      child: GymApp(),
    ),
  );
}
