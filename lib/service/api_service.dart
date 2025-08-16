import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/proposal.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({
    String? baseUrl,
    http.Client? client,
  }) : baseUrl = baseUrl ?? ApiConfig.baseUrl,
       _client = client ?? http.Client();

  // Headers with authentication
  Map<String, String> _getHeaders({String? authToken}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    
    return headers;
  }

  // Generic HTTP methods
  Future<Map<String, dynamic>> _get(String endpoint, {String? authToken}) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(authToken: authToken),
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> _post(
    String endpoint, 
    Map<String, dynamic> data, {
    String? authToken,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> _put(
    String endpoint, 
    Map<String, dynamic> data, {
    String? authToken,
  }) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> _delete(String endpoint, {String? authToken}) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(authToken: authToken),
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw ApiException(
          data['message'] ?? 'API error',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Invalid response format');
    }
  }

  // Proposal related methods
  Future<List<Proposal>> getProposals({
    String? status,
    String? authToken,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    
    final query = queryParams.isEmpty 
        ? '' 
        : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    
    final response = await _get('/proposals$query', authToken: authToken);
    
    final proposalsData = response['proposals'] as List<dynamic>? ?? [];
    return proposalsData
        .map((p) => Proposal.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<Proposal> getProposal(String id, {String? authToken}) async {
    final response = await _get('/proposals/$id', authToken: authToken);
    return Proposal.fromJson(response['proposal'] as Map<String, dynamic>);
  }

  Future<Proposal> createProposal(
    Map<String, dynamic> proposalData, {
    required String authToken,
  }) async {
    final response = await _post(
      '/proposals',
      proposalData,
      authToken: authToken,
    );
    return Proposal.fromJson(response['proposal'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> submitVote(
    String proposalId,
    Map<String, dynamic> voteData, {
    required String authToken,
  }) async {
    return await _post(
      '/proposals/$proposalId/votes',
      voteData,
      authToken: authToken,
    );
  }

  // User authentication methods
  Future<Map<String, dynamic>> checkUsernameAvailability(String username) async {
    return await _get('/auth/check-username?username=$username');
  }

  Future<Map<String, dynamic>> signUp(Map<String, dynamic> userData) async {
    return await _post('/auth/signup', userData);
  }

  Future<Map<String, dynamic>> signIn(Map<String, dynamic> credentials) async {
    return await _post('/auth/signin', credentials);
  }

  // Goodwill actions
  Future<Map<String, dynamic>> submitGoodwillAction(
    Map<String, dynamic> actionData, {
    required String authToken,
  }) async {
    return await _post(
      '/goodwill-actions',
      actionData,
      authToken: authToken,
    );
  }

  Future<List<Map<String, dynamic>>> getUserGoodwillActions({
    required String authToken,
    String? userId,
  }) async {
    final endpoint = userId != null 
        ? '/goodwill-actions?userId=$userId'
        : '/goodwill-actions/me';
    
    final response = await _get(endpoint, authToken: authToken);
    return List<Map<String, dynamic>>.from(response['actions'] ?? []);
  }

  // Ledger operations
  Future<List<Map<String, dynamic>>> getLedgerEntries({
    String? authToken,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();
    
    final query = queryParams.isEmpty 
        ? '' 
        : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    
    final response = await _get('/ledger$query', authToken: authToken);
    return List<Map<String, dynamic>>.from(response['entries'] ?? []);
  }

  Future<List<Map<String, dynamic>>> searchLedger({
    String? query,
    String? authToken,
  }) async {
    final endpoint = query != null 
        ? '/ledger/search?q=${Uri.encodeComponent(query)}'
        : '/ledger/search';
    
    final response = await _get(endpoint, authToken: authToken);
    return List<Map<String, dynamic>>.from(response['entries'] ?? []);
  }

  Future<Map<String, dynamic>> sendLoves(
    Map<String, dynamic> transactionData, {
    required String authToken,
  }) async {
    return await _post(
      '/ledger/send-loves',
      transactionData,
      authToken: authToken,
    );
  }

  // User account methods
  Future<Map<String, dynamic>> getAuthenticatedUserProfile({
    required String idToken,
  }) async {
    return await _get('/users/me', authToken: idToken);
  }

  Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> userData, {
    required String authToken,
  }) async {
    return await _put('/users/me', userData, authToken: authToken);
  }

  // Cleanup
  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException(
    this.message, {
    this.statusCode,
    this.details,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException($statusCode): $message';
    }
    return 'ApiException: $message';
  }
}

// Response wrapper classes
class ApiResponse<T> {
  final T data;
  final String? message;
  final bool success;

  const ApiResponse({
    required this.data,
    this.message,
    this.success = true,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    return ApiResponse(
      data: fromJson(json['data']),
      message: json['message'] as String?,
      success: json['success'] as bool? ?? true,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final itemsData = json['items'] as List<dynamic>? ?? [];
    final items = itemsData
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedResponse(
      items: items,
      totalCount: json['totalCount'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrevious: json['hasPrevious'] as bool? ?? false,
    );
  }
}
