import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/app/app.dart';
import 'package:schoolify_app/core/config/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes optional Supabase client; app runs without it (demo mode).
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.hasSupabaseConfig) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  runApp(const ProviderScope(child: SchoolifyApp()));
}
