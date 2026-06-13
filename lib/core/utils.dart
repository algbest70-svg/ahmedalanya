import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove all non-digit characters
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final formatter = NumberFormat('#,###');
    String formattedText = formatter.format(int.parse(newText));

    // Calculate cursor position
    int cursorPosition = formattedText.length;
    
    // Attempt to maintain cursor position (simple approach)
    // If the user is typing at the end, keep it at the end.
    // If they are editing in the middle, this might need more logic, 
    // but for price fields, end-of-text or simple formatting is usually enough.

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
