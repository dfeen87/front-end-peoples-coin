import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/proposal.dart';
import '../models/vote.dart';
import '../models/user_account.dart';

class ApiService {
  static final ApiService _singleton = ApiService._internal();
  factory ApiService() => _singleton;

  ApiService._internal();

  final String baseUrl = ApiConfig.baseUrl;
  final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 15);

  Map<String, String> _headers({String? authToken}) {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (authToken != null) headers['Authorization'] = 'Bearer $authToken';
    return headers;
  }

  Uri _uri(String endpoint, [Map<String, dynamic>? queryParams]) {
    if (queryParams == null || queryParams?.isEmpty == true) return Uri.parse('$baseUrl$endpoint');
    final query = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent('${e.value}')}')
        .join('&');
    return Uri.parse('$baseUrl$endpoint?$query');
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
    String? authToken,
  }) async {
    try {
      late http.Response response;
      final uri = _uri(endpoint, queryParams);
      final headers = _headers(authToken: authToken);

      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          response = await _client.post(uri, headers: headers, body: json.encode(data)).timeout(_timeout);
          break;
        case 'PUT':
          response = await _client.put(uri, headers: headers, body: json.encode(data)).timeout(_timeout);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers).timeout(_timeout);
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }

      final jsonBody = (response.body.isNotEmpty ? json.decode(response.body) : {}) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) return jsonBody;
      throw ApiException(jsonBody['message'] ?? 'API error', statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network or parsing error: $e');
    }
  }

  // --- Proposal Methods ---
  Future<List<Proposal>> getProposals({String? status, String? authToken}) async {
    final response = await _request('GET', '/proposals', queryParams: status != null ? {'status': status} : null, authToken: authToken);
    final data = response['data'] ?? response['proposals'] ?? [];
    return (data as List).map((e) => Proposal.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Proposal> createProposal(Map<String, dynamic> proposalData, {String? authToken}) async {
    final response = await _request('POST', '/proposals', data: proposalData, authToken: authToken);
    return Proposal.fromJson(response['data'] ?? response);
  }

  Future<Proposal> updateProposal(String proposalId, Map<String, dynamic> data, {String? authToken}) async {
    final response = await _request('PUT', '/proposals/$proposalId', data: data, authToken: authToken);
    return Proposal.fromJson(response['data'] ?? response);
  }

  Future<void> deleteProposal(String proposalId, {String? authToken}) async {
    await _request('DELETE', '/proposals/$proposalId', authToken: authToken);
  }

  // --- Vote Methods ---
  Future<Vote> submitVote(String proposalId, Map<String, dynamic> voteData, {String? authToken}) async {
    final response = await _request('POST', '/proposals/$proposalId/votes', data: voteData, authToken: authToken);
    return Vote.fromJson(response['data'] ?? response);
  }

  Future<List<Vote>> getVotes(String proposalId, {String? authToken}) async {
    final response = await _request('GET', '/proposals/$proposalId/votes', authToken: authToken);
    final data = response['data'] ?? response['votes'] ?? [];
    return (data as List).map((e) => Vote.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- User Methods ---
  Future<UserAccount> getUserAccount(String userId, {String? authToken}) async {
    final response = await _request('GET', '/users/$userId', authToken: authToken);
    return UserAccount.fromJson(response['data'] ?? response);
  }

  Future<UserAccount> updateUserAccount(String userId, Map<String, dynamic> data, {String? authToken}) async {
    final response = await _request('PUT', '/users/$userId', data: data, authToken: authToken);
    return UserAccount.fromJson(response['data'] ?? response);
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
  @override
  String toString() => statusCode != null ? 'ApiException($statusCode): $message' : 'ApiException: $message';
}

