import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF0B1D3A); // Royal Navy
  static const Color primaryGold = Color(0xFFCBA135); // Matte Gold
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  static const Color greyBackground = Color(0xFFF1F5F9);
}

class AppConstants {
  static const String appName = 'Ahmed Alanya Real Estate';
  static const String contactPhone = '+905383155351'; // Ahmed Alanya Number
  static const String adminPassword = 'ahmed@2026';

  static const List<String> countries = [
    'ألانيا',
    'الإمارات',
    'العراق',
  ];

  static const List<String> categories = [
    'أراضي',
    'شقق',
    'فيلات',
    'محلات تجارية',
  ];

  static const List<String> apartmentSubCategories = [
    'عادي',
    'دوبلكس',
    'بنتهاوس',
    'استوديو',
  ];

  static const Map<String, String> languages = {
    'ar': 'العربية',
    'en': 'English',
    'tr': 'Türkçe',
    'ru': 'Русский',
    'de': 'Deutsch',
    'fr': 'Français',
    'fa': 'فارسی',
    'uk': 'Українська',
    'kk': 'Қазақ тілі',
    'sv': 'Svenska',
  };

  // --- إعدادات قاعدة البيانات (Google Sheets) ---
  // سيتم وضع معرف الملف والرابط هنا ليعمل التزامن في كل الهواتف
  static const String googleSheetId = '1HyG2P25OpooNYj9oSytTnwHlUE02XQ6ABeqxqhz0Z3A'; 
  static const String googleWebAppUrl = 'https://script.google.com/macros/s/AKfycbwe7pkQc5kd3tSI0moPq4jQx2EG-W_Ol8uBjka1Lznel5eqoOELxfx7_cSSxcqMiECP-A/exec';
}
