
// ignore_for_file: avoid_print
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final client = SupabaseClient(
    'https://korgzfxrqnseglrfieud.supabase.co',
    'sb_publishable_kRVqvJHncCza2EcmFw2wnA_Ulw9Ghsn',
  );

  try {
    final response = await client.from('properties').select('country');
    final List<dynamic> data = response as List<dynamic>;
    
    final countries = data.map((e) => e['country'].toString()).toSet();
    print('Unique countries in DB: $countries');
  } catch (e) {
    print('Error: $e');
  }
}
