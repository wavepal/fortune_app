import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://api.example.com'; // Замените на ваш URL

  Future<Map<String, dynamic>> getRandomFact() async {
    final response = await http.get(Uri.parse('$baseUrl/random-fact'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load random fact');
    }
  }

  // Добавьте здесь другие методы API по мере необходимости
}
