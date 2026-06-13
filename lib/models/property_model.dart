import 'dart:convert';
class PropertyModel {
  final String id;
  String title;
  final String country;
  final String category;
  final double price;
  String description;
  final List<String> images;
  final String? youtubeLink;

  // Cached translations map (LanguageCode -> Translated String)
  final Map<String, String> _titleTranslations = {};
  final Map<String, String> _descriptionTranslations = {};

  bool isTranslating = false;

  PropertyModel({
    required this.id,
    required this.title,
    required this.country,
    required this.category,
    required this.price,
    required this.description,
    required this.images,
    this.youtubeLink,
  });

  /// من JSON عام (للاستخدام القديم إن احتجناه)
  factory PropertyModel.fromJson(Map<dynamic, dynamic> json, String id) {
    return PropertyModel(
      id: id,
      title: json['title'] ?? '',
      country: json['country'] ?? '',
      category: json['type'] ?? json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      youtubeLink: json['youtube'] ?? json['youtubeLink'],
    );
  }

  /// من Supabase - يتطابق مع أعمدة الجدول تماماً
  /// ملاحظة: الحقل مكتوب "proerty_id" (بدون حرف p) كما هو في Supabase
  factory PropertyModel.fromSupabase(Map<String, dynamic> json) {
    // التعامل مع حقل الصور بمرونة (سواء كان نصاً مفصولاً بفاصلة أو قائمة JSON أو نص JSON)
    final dynamic imagesData = json['images'];
    List<String> imagesList = [];
    
    if (imagesData is List) {
      imagesList = imagesData.map((e) => e.toString()).toList();
    } else if (imagesData is String && imagesData.isNotEmpty) {
      final String trimmed = imagesData.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final List<dynamic> decoded = jsonDecode(trimmed);
          imagesList = decoded.map((e) => e.toString()).toList();
        } catch (e) {
          // Fallback to comma split
          imagesList = trimmed.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
      } else {
        imagesList = trimmed.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }

    return PropertyModel(
      id: json['proerty_id'] as String? ?? json['id'].toString(),
      title: json['title'] as String? ?? '',
      country: json['country'] as String? ?? '',
      category: json['type'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      images: imagesList,
      // نحول النص الفارغ إلى null لتجنب مشاكل مشغل اليوتيوب
      youtubeLink: (json['youtube'] as String? ?? '').isEmpty
          ? null
          : json['youtube'] as String,
    );
  }

  /// إلى Supabase - يتطابق مع أعمدة الجدول تماماً
  Map<String, dynamic> toSupabaseJson() {
    return {
      'proerty_id': id,      // نفس الإملاء في Supabase (بدون p)
      'title': title,
      'country': country,
      'type': category,      // العمود اسمه "type" في Supabase
      'price': price,
      'description': description,
      'images': images.join(','), // نحوله لنص مفصول بفاصلة
      'youtube': youtubeLink ?? '',
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'country': country,
      'category': category,
      'price': price,
      'description': description,
      'images': images,
      'youtubeLink': youtubeLink,
    };
  }

  String getTranslatedTitle(String langCode) {
    if (langCode == 'ar') return title;
    return _titleTranslations[langCode] ?? title;
  }

  String getTranslatedDescription(String langCode) {
    if (langCode == 'ar') return description;
    return _descriptionTranslations[langCode] ?? description;
  }

  void setTranslation(String langCode, String transTitle, String transDesc) {
    _titleTranslations[langCode] = transTitle;
    _descriptionTranslations[langCode] = transDesc;
  }

  bool hasTranslation(String langCode) {
    if (langCode == 'ar') return true;
    return _titleTranslations.containsKey(langCode) &&
        _descriptionTranslations.containsKey(langCode);
  }
}

