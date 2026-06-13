import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = false;
  String _currencyCode = 'USD';
  String? _languageCode;

  bool get isDarkMode => _isDarkMode;
  String get currencyCode => _currencyCode;
  String? get languageCode => _languageCode;

  // Static conversion rates for demo/zero-cost purposes
  static const Map<String, double> exchangeRates = {
    'USD': 1.0,
    'EUR': 0.92,
  };

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _currencyCode = prefs.getString('currencyCode') ?? 'USD';
    _languageCode = prefs.getString('languageCode');
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setCurrency(String newCurrency) async {
    if (exchangeRates.containsKey(newCurrency)) {
      _currencyCode = newCurrency;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currencyCode', _currencyCode);
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', code);
    notifyListeners();
  }

  // Helper method to convert price
  double convertPrice(double priceInUSD) {
    double rate = exchangeRates[_currencyCode] ?? 1.0;
    return priceInUSD * rate;
  }
}
