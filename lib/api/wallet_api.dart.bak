import 'dart:convert';
import 'package:http/http.dart' as http;

class WalletApi {
  final String baseUrl;

  WalletApi({required this.baseUrl});

  Future<Map<String, dynamic>> createWallet(String userId) async {
    final url = Uri.parse('$baseUrl/wallet/create');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create wallet: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getWallet(String userId) async {
    final url = Uri.parse('$baseUrl/wallet/$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch wallet: ${response.body}');
    }
  }
}

