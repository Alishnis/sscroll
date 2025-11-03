import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Сервис для извлечения РЕАЛЬНЫХ изображений из Reddit API
/// Решает проблему ложных/скриптованных ссылок
class RedditRealImageService {
  static const String _userAgent = 'SmartScroll/1.0 by tmimpalish';
  
  /// Извлекает РЕАЛЬНЫЕ URL изображений из поста Reddit
  static Future<RedditImageInfo?> extractRealImageUrl(Map<String, dynamic> postData) async {
    debugPrint('Извлекаем реальное изображение для поста: ${postData['title']}');
    
    // 1. Проверяем preview изображения (часто содержат реальные ссылки)
    String? realUrl = _extractFromPreview(postData);
    if (realUrl != null) {
      debugPrint('Найдено изображение в preview: $realUrl');
      // Не проверяем валидность сразу, чтобы не замедлять
      return RedditImageInfo(
        url: realUrl,
        type: 'preview_source',
        isValid: true, // Предполагаем валидным
        source: 'preview',
      );
    }
    
    // 2. Проверяем media_metadata для галерей
    realUrl = _extractFromMediaMetadata(postData);
    if (realUrl != null) {
      debugPrint('Найдено изображение в галерее: $realUrl');
      return RedditImageInfo(
        url: realUrl,
        type: 'gallery',
        isValid: true,
        source: 'media_metadata',
      );
    }
    
    // 3. Проверяем прямые ссылки на изображения
    realUrl = _extractFromDirectUrl(postData);
    if (realUrl != null) {
      debugPrint('Найдено изображение в прямой ссылке: $realUrl');
      return RedditImageInfo(
        url: realUrl,
        type: 'direct_url',
        isValid: true,
        source: 'direct_url',
      );
    }
    
    // 4. Пробуем извлечь из thumbnail
    realUrl = _extractFromThumbnail(postData);
    if (realUrl != null) {
      debugPrint('Найдено изображение в thumbnail: $realUrl');
      return RedditImageInfo(
        url: realUrl,
        type: 'thumbnail',
        isValid: true,
        source: 'thumbnail',
      );
    }
    
    // 5. НОВОЕ: Пробуем извлечь из url_overridden_by_dest
    realUrl = _extractFromUrlOverridden(postData);
    if (realUrl != null) {
      debugPrint('Найдено изображение в url_overridden_by_dest: $realUrl');
      return RedditImageInfo(
        url: realUrl,
        type: 'url_overridden',
        isValid: true,
        source: 'url_overridden',
      );
    }
    
    debugPrint('Реальное изображение не найдено для поста: ${postData['title']}');
    return null;
  }
  
  /// Извлечение из preview (приоритет 1)
  static String? _extractFromPreview(Map<String, dynamic> postData) {
    try {
      final preview = postData['preview'];
      if (preview == null) return null;
      
      final images = preview['images'] as List?;
      if (images == null || images.isEmpty) return null;
      
      final firstImage = images[0] as Map<String, dynamic>;
      
      // Пробуем source (оригинал) - НЕ очищаем URL, оставляем как есть
      final source = firstImage['source'] as Map<String, dynamic>?;
      if (source != null && source['url'] != null) {
        String url = source['url'].toString();
        url = url.replaceAll('&amp;', '&');
        
        // Возвращаем URL как есть, не очищаем
        return url;
      }
      
      // Пробуем resolutions
      final resolutions = firstImage['resolutions'] as List?;
      if (resolutions != null && resolutions.isNotEmpty) {
        // Берем самое большое разрешение
        final largest = resolutions.last as Map<String, dynamic>;
        if (largest['url'] != null) {
          String url = largest['url'].toString();
          url = url.replaceAll('&amp;', '&');
          
          return url;
        }
      }
    } catch (e) {
      debugPrint('Ошибка извлечения из preview: $e');
    }
    
    return null;
  }
  
  /// Извлечение из media_metadata (галереи)
  static String? _extractFromMediaMetadata(Map<String, dynamic> postData) {
    try {
      final mediaMetadata = postData['media_metadata'] as Map<String, dynamic>?;
      if (mediaMetadata == null) return null;
      
      // Берем первое изображение из галереи
      final firstKey = mediaMetadata.keys.first;
      final media = mediaMetadata[firstKey] as Map<String, dynamic>?;
      
      if (media != null) {
        final s = media['s'] as Map<String, dynamic>?;
        if (s != null && s['u'] != null) {
          String url = s['u'].toString();
          url = url.replaceAll('&amp;', '&');
          
          final uri = Uri.parse(url);
          final cleanUrl = '${uri.scheme}://${uri.host}${uri.path}';
          
          return cleanUrl;
        }
      }
    } catch (e) {
      debugPrint('Ошибка извлечения из media_metadata: $e');
    }
    
    return null;
  }
  
  /// Извлечение из прямых ссылок
  static String? _extractFromDirectUrl(Map<String, dynamic> postData) {
    try {
      // Проверяем обычный url
      String? url = postData['url']?.toString();
      
      if (url != null && _isImageUrl(url)) {
        return url;
      }
    } catch (e) {
      debugPrint('Ошибка извлечения из прямых ссылок: $e');
    }
    
    return null;
  }
  
  /// Извлечение из url_overridden_by_dest
  static String? _extractFromUrlOverridden(Map<String, dynamic> postData) {
    try {
      String? url = postData['url_overridden_by_dest']?.toString();
      
      if (url != null && url.isNotEmpty && _isImageUrl(url)) {
        return url;
      }
    } catch (e) {
      debugPrint('Ошибка извлечения из url_overridden_by_dest: $e');
    }
    
    return null;
  }
  
  /// Извлечение из thumbnail
  static String? _extractFromThumbnail(Map<String, dynamic> postData) {
    try {
      final thumbnail = postData['thumbnail']?.toString();
      if (thumbnail != null && 
          thumbnail != 'self' && 
          thumbnail != 'default' &&
          thumbnail != 'nsfw' &&
          thumbnail.startsWith('http')) {
        return thumbnail;
      }
    } catch (e) {
      debugPrint('Ошибка извлечения из thumbnail: $e');
    }
    
    return null;
  }
  
  /// Проверка, является ли URL изображением
  static bool _isImageUrl(String url) {
    if (url.isEmpty) return false;
    
    final urlLower = url.toLowerCase();
    
    // Проверяем расширения файлов
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg'];
    if (imageExtensions.any((ext) => urlLower.endsWith(ext))) {
      return true;
    }
    
    // Проверяем хостинги изображений
    final imageHosts = [
      'i.redd.it', 'preview.redd.it', 'external-preview.redd.it',
      'i.redditmedia.com', 'preview.redditmedia.com',
      'i.imgur.com', 'imgur.com', 'gyazo.com',
      'cdn.reddit.com', 'images.reddit.com'
    ];
    
    return imageHosts.any((host) => urlLower.contains(host));
  }
  
  /// Проверка валидности URL изображения
  static Future<bool> _isValidImageUrl(String url) async {
    try {
      final response = await http.head(
        Uri.parse(url),
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'image/*',
        },
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Получение прокси URL для обхода блокировок
  static String getProxiedImageUrl(String originalUrl) {
    // Список прокси сервисов
    final proxies = [
      'https://images.weserv.nl/?url=',
      'https://cors-anywhere.herokuapp.com/',
      'https://api.allorigins.win/raw?url=',
      'https://thingproxy.freeboard.io/fetch/',
    ];
    
    // Используем первый прокси
    final proxy = proxies[0];
    return '$proxy${Uri.encodeComponent(originalUrl)}&output=webp&q=85&n=-1&w=800';
  }
  
  /// Получение изображения с fallback через несколько прокси
  static Future<String> getImageUrlWithFallback(String originalUrl) async {
    // Сначала пробуем оригинальный URL
    if (await _isValidImageUrl(originalUrl)) {
      return originalUrl;
    }
    
    // Пробуем разные прокси
    final proxies = [
      'https://images.weserv.nl/?url=',
      'https://cors-anywhere.herokuapp.com/',
      'https://api.allorigins.win/raw?url=',
    ];
    
    for (final proxy in proxies) {
      try {
        String proxiedUrl;
        if (proxy.contains('images.weserv.nl')) {
          proxiedUrl = '$proxy${Uri.encodeComponent(originalUrl)}&output=webp&q=85&n=-1&w=800';
        } else {
          proxiedUrl = proxy + originalUrl;
        }
        
        if (await _isValidImageUrl(proxiedUrl)) {
          return proxiedUrl;
        }
      } catch (e) {
        continue;
      }
    }
    
    // Если ничего не работает, возвращаем оригинальный URL
    return originalUrl;
  }
  
  /// Получение всех возможных URL изображений из поста
  static Future<List<RedditImageInfo>> getAllPossibleImages(Map<String, dynamic> postData) async {
    final images = <RedditImageInfo>[];
    
    // 1. Preview изображения
    final previewUrl = _extractFromPreview(postData);
    if (previewUrl != null) {
      final isValid = await _isValidImageUrl(previewUrl);
      images.add(RedditImageInfo(
        url: previewUrl,
        type: 'preview_source',
        isValid: isValid,
        source: 'preview',
      ));
    }
    
    // 2. Media metadata
    final metadataUrl = _extractFromMediaMetadata(postData);
    if (metadataUrl != null) {
      final isValid = await _isValidImageUrl(metadataUrl);
      images.add(RedditImageInfo(
        url: metadataUrl,
        type: 'gallery',
        isValid: isValid,
        source: 'media_metadata',
      ));
    }
    
    // 3. Прямые ссылки
    final directUrl = _extractFromDirectUrl(postData);
    if (directUrl != null) {
      final isValid = await _isValidImageUrl(directUrl);
      images.add(RedditImageInfo(
        url: directUrl,
        type: 'direct_url',
        isValid: isValid,
        source: 'direct_url',
      ));
    }
    
    // 4. Thumbnail
    final thumbnailUrl = _extractFromThumbnail(postData);
    if (thumbnailUrl != null) {
      final isValid = await _isValidImageUrl(thumbnailUrl);
      images.add(RedditImageInfo(
        url: thumbnailUrl,
        type: 'thumbnail',
        isValid: isValid,
        source: 'thumbnail',
      ));
    }
    
    return images;
  }
}

/// Информация об изображении Reddit
class RedditImageInfo {
  final String url;
  final String type;
  final bool isValid;
  final String source;
  
  RedditImageInfo({
    required this.url,
    required this.type,
    required this.isValid,
    required this.source,
  });
  
  @override
  String toString() {
    return 'RedditImageInfo(url: $url, type: $type, isValid: $isValid, source: $source)';
  }
}
