import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = "7efb402ec72224ba316879d679b99211";

  static Future<Map<String, dynamic>?> getWeatherByLocation({
    required double lat,
    required double lon,
  }) async {
    try {
      final url =
          "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Weather API Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Weather Exception: $e");
      return null;
    }
  }
}
