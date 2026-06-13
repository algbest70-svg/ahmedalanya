// ignore_for_file: avoid_print
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final client = SupabaseClient(
    'https://korgzfxrqnseglrfieud.supabase.co',
    'sb_publishable_kRVqvJHncCza2EcmFw2wnA_Ulw9Ghsn',
  );

  try {
    // تحديث العقار رقم 7 (شقة غرفتين وصالة)
    // سنضع الروابط في شكل مصفوفة JSON بدلاً من نص مفصول بفاصلة
    final images = [
      "https://i.imgur.com/LiTq5ON.jpeg",
      "https://i.imgur.com/herjVMk.jpeg",
      "https://i.imgur.com/czlIK4o.jpeg",
      "https://i.imgur.com/dsCFOZf.jpeg",
      "https://i.imgur.com/fydAAWa.jpeg"
    ];

    await client
        .from('properties')
        .update({'images': images.join(',')}) // سنحاول أولاً التأكد من أن النص نظيف جداً
        .eq('id', 7);
        
    print('✅ Property updated successfully');
  } catch (e) {
    print('❌ Error: $e');
  }
}
