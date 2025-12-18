import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lppl_93fm_suara_madiun/config.dart';

class YoutubeApi {
  Future<List<dynamic>> getVideos(String channelId) async {
    final url = Uri.parse(
      "https://www.googleapis.com/youtube/v3/search"
          "?key=$YOUTUBE_API_KEY"
          "&channelId=$channelId"
          "&part=snippet"
          "&order=date"
          "&maxResults=20",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["items"];
    } else {
      throw Exception(
          "Gagal mengambil data YouTube: ${response.statusCode} → ${response.body}"
      );
    }
  }
}
