// ignore_for_file: avoid_print
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final client = SupabaseClient(
    'https://korgzfxrqnseglrfieud.supabase.co',
    'sb_publishable_kRVqvJHncCza2EcmFw2wnA_Ulw9Ghsn',
  );

  try {
    // استخدام بروكسي جوجل مباشرة في الروابط لضمان تخطي أي حجب في النسخة الحالية
    final images = [
      "https://images2-focus-opensocial.googleusercontent.com/gadgets/proxy?container=focus&url=https://i.imgur.com/LiTq5ON.jpeg",
      "https://images2-focus-opensocial.googleusercontent.com/gadgets/proxy?container=focus&url=https://i.imgur.com/herjVMk.jpeg"
    ];

    await client
        .from('properties')
        .update({'images': images.join(',')})
        .eq('id', 7);
        
    print('✅ Google Proxy links applied to property 7');
  } catch (e) {
    print('❌ Error: $e');
  }
}
