import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanat/core/config/app_environment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    baseUrl: AppEnvironment.apiBaseUrl,
    accessToken: () =>
        Supabase.instance.client.auth.currentSession?.accessToken,
  );
  ref.onDispose(client.close);
  return client;
});
