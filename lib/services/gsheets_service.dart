import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/property_model.dart';

class GSheetsService {
  // We no longer use the complex 'gsheets' library for better user experience.
  // Instead, we use simple HTTP calls.

  Future<List<PropertyModel>> fetchProperties() async {
    final sheetId = AppConstants.googleSheetId;
    if (sheetId.contains('ضع_هنا')) {
      log('Google Sheet ID not configured.');
      return [];
    }

    // Reading via Public CSV Export (Fast & No Auth needed)
    final url = 'https://docs.google.com/spreadsheets/d/$sheetId/export?format=csv&gid=0';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return _parseCsv(response.body);
      } else {
        log('Error fetching CSV: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('Error fetching properties: $e');
      return [];
    }
  }

  Future<bool> addProperty(PropertyModel property) async {
    final webAppUrl = AppConstants.googleWebAppUrl;
    if (webAppUrl.contains('ضع_هنا')) {
      log('Google Web App URL not configured.');
      return false;
    }

    try {
      log('Sending property to Google Sheets: ${property.id}');
      
      final response = await http.post(
        Uri.parse(webAppUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(property.toJson()),
      );

      log('Initial Response Code: ${response.statusCode}');

      if (response.statusCode == 302) {
        final newUrl = response.headers['location'];
        if (newUrl != null) {
          log('Following redirect to: $newUrl');
          // For Google Apps Script, we follow the 302 with a GET request
          // to verify the execution result (usually "Success")
          final retryResponse = await http.get(Uri.parse(newUrl));
          log('Redirect Response Code: ${retryResponse.statusCode}');
          log('Response Body: ${retryResponse.body}');
          
          return retryResponse.statusCode == 200 || retryResponse.body.contains('Success');
        }
      }

      if (response.statusCode == 200) {
        log('Success response: ${response.body}');
        return true;
      }

      log('Failed to add property. Status: ${response.statusCode}, Body: ${response.body}');
      return false;
    } catch (e) {
      log('Error appending property: $e');
      return false;
    }
  }

  List<PropertyModel> _parseCsv(String csvData) {
    List<PropertyModel> properties = [];
    List<String> lines = csvData.split('\n');
    
    // Skip header row (index 0)
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      
      // Simple CSV parsing (handling basic cases)
      List<String> row = _splitCsvLine(lines[i]);
      if (row.length < 9) continue;

      properties.add(
        PropertyModel(
          id: row[0].trim(),
          title: row[1].trim(),
          country: row[2].trim(),
          category: row[3].trim(),
          price: double.tryParse(row[5]) ?? 0.0,
          description: row[6].trim(),
          images: row[7].isNotEmpty ? row[7].split(',').map((e) => e.trim()).toList() : [],
          youtubeLink: row[8].trim().isNotEmpty ? row[8].trim() : null,
        ),
      );
    }
    return properties;
  }

  // Basic CSV splitter that handles quotes if necessary (simplified)
  List<String> _splitCsvLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    StringBuffer currentField = StringBuffer();

    for (int i = 0; i < line.length; i++) {
        String char = line[i];
        if (char == '"') {
            inQuotes = !inQuotes;
        } else if (char == ',' && !inQuotes) {
            result.add(currentField.toString());
            currentField.clear();
        } else {
            currentField.write(char);
        }
    }
    result.add(currentField.toString());
    return result;
  }
}
