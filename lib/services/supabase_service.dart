import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property_model.dart';

typedef PropertiesCallback = void Function(List<PropertyModel>);

class SupabaseService {
  // الوصول إلى client الخاص بـ Supabase
  SupabaseClient get _client => Supabase.instance.client;

  static const String _tableName = 'properties';

  /// جلب العقارات من Supabase مع دعم الفلترة والتحميل التدريجي (Pagination)
  Future<List<PropertyModel>> fetchProperties({
    int from = 0,
    int to = 19,
    String? country,
    String? category,
    String? searchQuery,
  }) async {
    try {
      var query = _client.from(_tableName).select();

      // فلترة حسب الدولة
      if (country != null && country.isNotEmpty) {
        query = query.eq('country', country);
      }

      // فلترة حسب النوع
      if (category != null && category.isNotEmpty) {
        query = query.eq('type', category); // العمود في Supabase اسمه type
      }



      // بحث نصي (في العنوان أو الوصف)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => PropertyModel.fromSupabase(json)).toList();
    } catch (e) {
      log('❌ Error fetching properties from Supabase: $e');
      return [];
    }
  }

  /// إضافة عقار جديد إلى Supabase
  Future<bool> addProperty(PropertyModel property) async {
    try {
      log('📤 Sending property to Supabase: ${property.id}');

      await _client.from(_tableName).insert(property.toSupabaseJson());

      log('✅ Property added successfully to Supabase');
      return true;
    } on PostgrestException catch (e) {
      log('❌ Supabase DB Error: ${e.message}');
      return false;
    } catch (e) {
      log('❌ Unknown error adding property: $e');
      return false;
    }
  }

  /// تعديل عقار موجود في Supabase
  Future<bool> updateProperty(PropertyModel property) async {
    try {
      log('✏️ Updating property: ${property.id}');
      await _client
          .from(_tableName)
          .update(property.toSupabaseJson())
          .eq('proerty_id', property.id);
      log('✅ Property updated successfully');
      return true;
    } on PostgrestException catch (e) {
      log('❌ Supabase update error: ${e.message}');
      return false;
    } catch (e) {
      log('❌ Unknown error updating property: $e');
      return false;
    }
  }

  /// حذف عقار بواسطة الـ proerty_id (كما هو مكتوب في قاعدة البيانات)
  Future<bool> deleteProperty(String propertyId) async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .eq('proerty_id', propertyId);
      log('🗑️ Property deleted: $propertyId');
      return true;
    } catch (e) {
      log('❌ Error deleting property: $e');
      return false;
    }
  }

  /// الاشتراك في التحديثات الفورية (Realtime)
  RealtimeChannel subscribeToProperties(PropertiesCallback onUpdate) {
    return _client
        .channel('properties-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _tableName,
          callback: (payload) async {
            log('🔔 Realtime update received: ${payload.eventType}');
            // نعيد جلب القائمة كاملة عند أي تغيير
            final updated = await fetchProperties();
            onUpdate(updated);
          },
        )
        .subscribe();
  }
}
