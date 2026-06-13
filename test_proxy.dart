// ignore_for_file: avoid_print
import 'package:http/http.dart' as http;

void main() async {
  final cleanUrl = "https://i.imgur.com/vI8kiZp.jpeg";
  final proxyUrl = "https://wsrv.nl/?url=${Uri.encodeComponent(cleanUrl)}&w=800";
  final proxyUrl2 = "https://images.weserv.nl/?url=${Uri.encodeComponent(cleanUrl)}&w=800";
  final wpProxy = "https://i0.wp.com/${cleanUrl.replaceFirst('https://', '')}";

  print('Testing: $proxyUrl');
  try {
    final res = await http.get(Uri.parse(proxyUrl));
    print('Status: ${res.statusCode}');
    print('Content-Type: ${res.headers['content-type']}');
    print('Content-Length: ${res.headers['content-length']}');
  } catch (e) {
    print('Error: $e');
  }

  print('\nTesting: $proxyUrl2');
  try {
    final res = await http.get(Uri.parse(proxyUrl2));
    print('Status: ${res.statusCode}');
  } catch (e) {
    print('Error: $e');
  }

  print('\nTesting: $wpProxy');
  try {
    final res = await http.get(Uri.parse(wpProxy));
    print('Status: ${res.statusCode}');
  } catch (e) {
    print('Error: $e');
  }

  final googleProxy = "https://images2-focus-opensocial.googleusercontent.com/gadgets/proxy?container=focus&url=$cleanUrl";
  print('\nTesting: $googleProxy');
  try {
    final res = await http.get(Uri.parse(googleProxy));
    print('Status: ${res.statusCode}');
  } catch (e) {
    print('Error: $e');
  }

  print('\nTesting Direct: $cleanUrl');
  try {
    final res = await http.get(Uri.parse(cleanUrl));
    print('Status: ${res.statusCode}');
  } catch (e) {
    print('Error: $e');
  }
}
