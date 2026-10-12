import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanat/app/qanat_app.dart';
import 'package:qanat/core/config/app_environment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppEnvironment.isPartiallyConfigured) {
    throw StateError(
      'SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY and API_BASE_URL must be set together.',
    );
  }
  if (AppEnvironment.isConfigured) {
    await Supabase.initialize(
      url: AppEnvironment.supabaseUrl,
      publishableKey: AppEnvironment.publishableKey,
    );
  }
  runApp(const ProviderScope(child: QanatApp()));
}
