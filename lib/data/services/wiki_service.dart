import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Fetches a place's photo from the public Wikipedia REST API (client-server
/// call) and caches the URL on the device.
class WikiService {
  WikiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, String?> _memory = {};
  final Map<String, Future<String?>> _inFlight = {};

  Future<String?> imageUrl(String wikiTitle) {
    if (_memory.containsKey(wikiTitle)) return Future.value(_memory[wikiTitle]);
    return _inFlight[wikiTitle] ??= _load(wikiTitle).whenComplete(() => _inFlight.remove(wikiTitle));
  }

  Future<String?> _load(String title) async {
    final key = 'wiki_img_$title';
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      if (cached != null) return _memory[title] = cached.isEmpty ? null : cached;

      final res = await _client
          .get(Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/$title'))
          .timeout(const Duration(seconds: 8));
      String? url;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        url = (body['originalimage'] as Map?)?['source'] as String? ?? (body['thumbnail'] as Map?)?['source'] as String?;
        // Large originals are slow on mobile data; ask for a 640px rendition.
        final thumb = (body['thumbnail'] as Map?)?['source'] as String?;
        if (thumb != null) url = thumb.replaceFirst(RegExp(r'/\d+px-'), '/640px-');
      }
      await prefs.setString(key, url ?? '');
      return _memory[title] = url;
    } catch (_) {
      // Offline: show the category artwork instead and retry next launch.
      return null;
    }
  }
}
