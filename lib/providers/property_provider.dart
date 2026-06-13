import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property_model.dart';
import '../services/supabase_service.dart';
import '../services/translation_service.dart';

class PropertyProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final TranslationService _translationService = TranslationService();
  RealtimeChannel? _realtimeChannel;

  List<PropertyModel> _properties = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 15;

  // Filters
  String _searchQuery = '';
  String _selectedCountry = '';
  String _selectedCategory = '';

  List<PropertyModel> get properties => _properties;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String _currentLang = 'ar';
  String get currentLang => _currentLang;

  PropertyProvider() {
    fetchProperties(refresh: true);
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    _realtimeChannel = _supabaseService.subscribeToProperties((updatedList) {
      // عند حدوث تغيير في قاعدة البيانات، نفضل إعادة تحميل الصفحة الأولى لضمان التزامن
      fetchProperties(refresh: true);
    });
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> setLanguage(String targetLang) async {
    if (_currentLang == targetLang) return;
    _currentLang = targetLang;
    notifyListeners();
  }

  Future<void> translateProperty(PropertyModel prop) async {
    if (prop.hasTranslation(_currentLang) || _currentLang == 'ar' || prop.isTranslating) return;

    prop.isTranslating = true;
    try {
      final translatedData = await Future.wait([
        _translationService.translate(prop.title, _currentLang),
        _translationService.translate(prop.description, _currentLang),
      ]);
      prop.setTranslation(_currentLang, translatedData[0], translatedData[1]);
    } catch (e) {
      debugPrint('Translation failed for property ${prop.id}');
    } finally {
      prop.isTranslating = false;
      notifyListeners();
    }
  }

  /// جلب العقارات مع دعم الفلترة والتحميل التدريجي
  Future<void> fetchProperties({bool refresh = false}) async {
    if (refresh) {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
      _properties = [];
    } else {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
    }
    
    notifyListeners();

    final from = _currentPage * _pageSize;
    final to = from + _pageSize - 1;

    final newProperties = await _supabaseService.fetchProperties(
      from: from,
      to: to,
      country: _selectedCountry,
      category: _selectedCategory,
      searchQuery: _searchQuery,
    );

    if (refresh) {
      _properties = newProperties;
      _isLoading = false;
    } else {
      _properties.addAll(newProperties);
      _isLoadingMore = false;
    }

    if (newProperties.length < _pageSize) {
      _hasMore = false;
    } else {
      _currentPage++;
    }

    notifyListeners();
  }

  // طرق الفلترة (تؤدي دائماً لإعادة التحميل من البداية)
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    fetchProperties(refresh: true);
  }

  void setFilter({String? country, String? category}) {
    bool changed = false;
    if (country != null && _selectedCountry != country) {
      _selectedCountry = country;
      changed = true;
    }
    if (category != null && _selectedCategory != category) {
      _selectedCategory = category;
      changed = true;
    }

    if (changed) {
      fetchProperties(refresh: true);
    }
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCountry = '';
    _selectedCategory = '';
    fetchProperties(refresh: true);
  }

  Future<bool> addProperty(PropertyModel property) async {
    bool success = await _supabaseService.addProperty(property);
    if (success) {
      await fetchProperties(refresh: true);
    }
    return success;
  }

  Future<bool> deleteProperty(String propertyId) async {
    bool success = await _supabaseService.deleteProperty(propertyId);
    if (success) {
      _properties.removeWhere((p) => p.id == propertyId);
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateProperty(PropertyModel property) async {
    bool success = await _supabaseService.updateProperty(property);
    if (success) {
      await fetchProperties(refresh: true);
    }
    return success;
  }
}
