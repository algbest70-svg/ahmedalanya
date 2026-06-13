// ignore_for_file: avoid_print
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final client = SupabaseClient(
    'https://korgzfxrqnseglrfieud.supabase.co',
    'sb_publishable_kRVqvJHncCza2EcmFw2wnA_Ulw9Ghsn',
  );

  try {
    final response = await client.from('properties').select();
    final List<dynamic> data = response as List<dynamic>;
    
    print('Total properties: ${data.length}');
    for (var i = 0; i < data.length; i++) {
      final p = data[i];
      print('Property ${i+1}: ID=${p['proerty_id'] ?? p['id']}, Title=${p['title']}, Images=${p['images']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
