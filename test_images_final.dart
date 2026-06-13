// ignore_for_file: avoid_print
import 'package:http/http.dart' as http;

void main() async {
  final List<String> images = [
    "https://i.imgur.com/LiTq5ON.jpeg",
    "https://i.imgur.com/herjVMk.jpeg",
    "https://i.imgur.com/czlIK4o.jpeg",
    "https://i.imgur.com/dsCFOZf.jpeg",
    "https://i.imgur.com/fydAAWa.jpeg"
  ];

  for (final url in images) {
    print('\nTesting Image: $url');
    
    // Test Photon (The one I just added)
    final photonUrl = "https://i0.wp.com/${url.replaceFirst('https://', '')}";
    try {
      final res = await http.get(Uri.parse(photonUrl));
      print('  Photon (i0.wp.com): ${res.statusCode}');
    } catch (e) {
      print('  Photon Error: $e');
    }

    // Test Google
    final googleUrl = "https://images2-focus-opensocial.googleusercontent.com/gadgets/proxy?container=focus&url=${Uri.encodeComponent(url)}";
    try {
      final res = await http.get(Uri.parse(googleUrl));
      print('  Google: ${res.statusCode}');
    } catch (e) {
      print('  Google Error: $e');
    }

    // Test Weserv (The old Tier 1)
    final weservUrl = "https://wsrv.nl/?url=${Uri.encodeComponent(url)}";
    try {
      final res = await http.get(Uri.parse(weservUrl));
      print('  Weserv (wsrv.nl): ${res.statusCode}');
    } catch (e) {
      print('  Weserv Error: $e');
    }

    // Test Direct
    try {
      final res = await http.get(Uri.parse(url));
      print('  Direct: ${res.statusCode}');
    } catch (e) {
      print('  Direct Error: $e');
    }
  }
}
