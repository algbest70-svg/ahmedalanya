// ignore_for_file: avoid_print
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

void main() async {
  final client = SupabaseClient(
    'https://korgzfxrqnseglrfieud.supabase.co',
    'sb_publishable_kRVqvJHncCza2EcmFw2wnA_Ulw9Ghsn',
  );

  try {
    final response = await client.from('properties').select();
    final List<dynamic> data = response as List<dynamic>;
    
    final buffer = StringBuffer();
    buffer.writeln('Total properties: ${data.length}');
    for (var i = 0; i < data.length; i++) {
      final p = data[i];
      buffer.writeln('Property ${i+1}: ID=${p['proerty_id'] ?? p['id']}, Title=${p['title']}, Images=${p['images']}');
    }
    
    File('data_dump.txt').writeAsStringSync(buffer.toString());
    print('✅ Data dumped to data_dump.txt');
    exit(0);
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
