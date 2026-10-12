abstract final class AppEnvironment {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      publishableKey.isNotEmpty &&
      apiBaseUrl.isNotEmpty;

  static bool get isPartiallyConfigured =>
      (supabaseUrl.isNotEmpty ||
          publishableKey.isNotEmpty ||
          apiBaseUrl.isNotEmpty) &&
      !isConfigured;
}
