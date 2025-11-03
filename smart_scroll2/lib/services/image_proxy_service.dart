import 'package:http/http.dart' as http;

class ImageProxyService {
  static const String _proxyUrl = 'https://images.weserv.nl/?url=';
  
  /// Получает изображение через прокси для обхода CORS и блокировок
  static String getProxiedImageUrl(String originalUrl) {
    // Обрабатываем различные типы Reddit изображений
    if (originalUrl.contains('redd.it') || 
        originalUrl.contains('preview.redd.it') ||
        originalUrl.contains('i.redd.it') ||
        originalUrl.contains('external-preview.redd.it')) {
      
      // Очищаем URL от параметров
      final uri = Uri.parse(originalUrl);
      final cleanUrl = uri.replace(queryParameters: {}).toString();
      
      // Используем прокси сервис с оптимизацией для Reddit
      return '$_proxyUrl${Uri.encodeComponent(cleanUrl)}&output=webp&q=85&n=-1&w=800';
    }
    
    // Для других изображений также используем прокси для надежности
    if (originalUrl.startsWith('http')) {
      return '$_proxyUrl${Uri.encodeComponent(originalUrl)}&output=webp&q=80&n=-1';
    }
    
    return originalUrl;
  }
  
  /// Проверяет доступность изображения
  static Future<bool> isImageAccessible(String url) async {
    try {
      final response = await http.head(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Получает изображение с fallback на прокси
  static Future<String> getImageUrlWithFallback(String originalUrl) async {
    // Сначала пробуем оригинальный URL
    if (await isImageAccessible(originalUrl)) {
      return originalUrl;
    }
    
    // Если не работает, используем прокси
    final proxiedUrl = getProxiedImageUrl(originalUrl);
    
    // Проверяем доступность прокси URL
    if (await isImageAccessible(proxiedUrl)) {
      return proxiedUrl;
    }
    
    // Если и прокси не работает, возвращаем оригинальный URL
    // (пусть Image.network сам обработает ошибку)
    return originalUrl;
  }
}
