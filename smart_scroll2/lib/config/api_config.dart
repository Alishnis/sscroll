/// API Configuration
/// 
/// Хранит все API ключи и конфигурацию для внешних сервисов.
/// В продакшене используйте flutter_dotenv для загрузки из .env файла
class ApiConfig {
  // Singleton pattern
  static final ApiConfig _instance = ApiConfig._internal();
  factory ApiConfig() => _instance;
  ApiConfig._internal();

  // YouTube API
  static const String youtubeApiKey = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: '',
  );

  // OpenAI API
  static const String openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  // Coursera API
  static const String courseraApiKey = String.fromEnvironment(
    'COURSERA_API_KEY',
    defaultValue: '',
  );

  // Reddit API
  static const String redditClientId = String.fromEnvironment(
    'REDDIT_CLIENT_ID',
    defaultValue: '',
  );

  static const String redditClientSecret = String.fromEnvironment(
    'REDDIT_CLIENT_SECRET',
    defaultValue: '',
  );

  static const String redditUserAgent = String.fromEnvironment(
    'REDDIT_USER_AGENT',
    defaultValue: 'SmartScroll/1.0',
  );

  // Firebase Configuration
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );

  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );

  // Backend API
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://api.smartscroll.com',
  );

  static const String backendApiKey = String.fromEnvironment(
    'BACKEND_API_KEY',
    defaultValue: '',
  );

  // Analytics
  static const String googleAnalyticsId = String.fromEnvironment(
    'GOOGLE_ANALYTICS_ID',
    defaultValue: '',
  );

  static const String mixpanelToken = String.fromEnvironment(
    'MIXPANEL_TOKEN',
    defaultValue: '',
  );

  // Error tracking
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  // Проверка наличия необходимых ключей
  static bool get hasYoutubeKey => youtubeApiKey.isNotEmpty;
  static bool get hasOpenAiKey => openAiApiKey.isNotEmpty;
  static bool get hasFirebaseConfig => 
      firebaseApiKey.isNotEmpty && 
      firebaseProjectId.isNotEmpty;
  static bool get hasBackendConfig => 
      backendBaseUrl.isNotEmpty && 
      backendApiKey.isNotEmpty;

  static bool get hasRedditConfig => 
      redditClientId.isNotEmpty && 
      redditClientSecret.isNotEmpty;

  static bool get hasYouTubeConfig => 
      const String.fromEnvironment('YOUTUBE_API_KEY', defaultValue: '').isNotEmpty;

  // Debug информация (НЕ логировать в продакшене!)
  static void printDebugInfo() {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return; // Не показывать в release
    }
    
    // ignore: avoid_print
    print('=== API Configuration ===');
    // ignore: avoid_print
    print('YouTube API: ${hasYoutubeKey ? "✓" : "✗"}');
    // ignore: avoid_print
    print('OpenAI API: ${hasOpenAiKey ? "✓" : "✗"}');
    // ignore: avoid_print
    print('Firebase: ${hasFirebaseConfig ? "✓" : "✗"}');
    // ignore: avoid_print
    print('Backend: ${hasBackendConfig ? "✓" : "✗"}');
    // ignore: avoid_print
    print('Reddit: ${hasRedditConfig ? "✓" : "✗"}');
    // ignore: avoid_print
    print('YouTube: ${hasYouTubeConfig ? "✓" : "✗"}');
    // ignore: avoid_print
    print('========================');
  }
}

