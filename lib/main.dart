import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'data/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inspect and initialize Firebase (falls back to mock repository mode when unconfigured)
  await FirebaseService.initialize();

  runApp(
    const ProviderScope(
      child: GymApp(),
    ),
  );
}
