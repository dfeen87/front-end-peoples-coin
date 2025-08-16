import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/goodwill_action.dart';

class GoodwillActionService {
  final http.Client client;
  final String baseUrl;

  GoodwillActionService(this.client, {String? baseUrl}) 
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Map<String, String> _getHeaders({String? authToken}) {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      
      if (ApiConfig.isSuccessStatusCode(response.statusCode)) {
        return data;
      } else {
        throw GoodwillActionException(
          data['message'] ?? ApiConfig.getErrorMessage(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is GoodwillActionException) rethrow;
      throw GoodwillActionException('Invalid response format');
    }
  }

  // Submit a new goodwill action
  Future<GoodwillAction> submitGoodwillAction({
    required GoodwillAction action,
    required String authToken,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl${ApiConfig.goodwillActionsEndpoint}'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode(action.toJson()),
      );

      final data = await _handleResponse(response);
      return GoodwillAction.fromJson(data['action'] as Map<String, dynamic>);
    } catch (e) {
      throw GoodwillActionException('Failed to submit goodwill action: $e');
    }
  }

  // Get user's goodwill actions
  Future<List<GoodwillAction>> getUserGoodwillActions({
    required String authToken,
    String? userId,
    int? limit,
    int? offset,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['userId'] = userId;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (status != null) queryParams['status'] = status;

      final query = queryParams.isEmpty 
          ? '' 
          : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final endpoint = userId != null 
          ? '${ApiConfig.goodwillActionsEndpoint}/user/$userId$query'
          : '${ApiConfig.goodwillActionsEndpoint}/me$query';

      final response = await client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      final actionsData = data['actions'] as List<dynamic>? ?? [];
      
      return actionsData
          .map((actionData) => GoodwillAction.fromJson(actionData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw GoodwillActionException('Failed to fetch goodwill actions: $e');
    }
  }

  // Get goodwill action by ID
  Future<GoodwillAction> getGoodwillAction({
    required String actionId,
    String? authToken,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.goodwillActionsEndpoint}/$actionId'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      return GoodwillAction.fromJson(data['action'] as Map<String, dynamic>);
    } catch (e) {
      throw GoodwillActionException('Failed to fetch goodwill action: $e');
    }
  }

  // Update goodwill action
  Future<GoodwillAction> updateGoodwillAction({
    required String actionId,
    required Map<String, dynamic> updates,
    required String authToken,
  }) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl${ApiConfig.goodwillActionsEndpoint}/$actionId'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode(updates),
      );

      final data = await _handleResponse(response);
      return GoodwillAction.fromJson(data['action'] as Map<String, dynamic>);
    } catch (e) {
      throw GoodwillActionException('Failed to update goodwill action: $e');
    }
  }

  // Delete goodwill action
  Future<void> deleteGoodwillAction({
    required String actionId,
    required String authToken,
  }) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl${ApiConfig.goodwillActionsEndpoint}/$actionId'),
        headers: _getHeaders(authToken: authToken),
      );

      await _handleResponse(response);
    } catch (e) {
      throw GoodwillActionException('Failed to delete goodwill action: $e');
    }
  }

  // Get goodwill actions feed
  Future<List<GoodwillAction>> getGoodwillActionsFeed({
    String? authToken,
    int? limit,
    int? offset,
    String? category,
    String? location,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (category != null) queryParams['category'] = category;
      if (location != null) queryParams['location'] = location;

      final query = queryParams.isEmpty 
          ? '' 
          : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.goodwillActionsEndpoint}/feed$query'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      final actionsData = data['actions'] as List<dynamic>? ?? [];
      
      return actionsData
          .map((actionData) => GoodwillAction.fromJson(actionData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw GoodwillActionException('Failed to fetch goodwill actions feed: $e');
    }
  }

  // Search goodwill actions
  Future<List<GoodwillAction>> searchGoodwillActions({
    required String query,
    String? authToken,
    int? limit,
    int? offset,
    String? category,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query,
      };
      
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (category != null) queryParams['category'] = category;
      if (location != null) queryParams['location'] = location;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final queryString = '?' + queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.goodwillActionsEndpoint}/search$queryString'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      final actionsData = data['actions'] as List<dynamic>? ?? [];
      
      return actionsData
          .map((actionData) => GoodwillAction.fromJson(actionData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw GoodwillActionException('Failed to search goodwill actions: $e');
    }
  }

  // Get goodwill action categories
  Future<List<String>> getGoodwillActionCategories({String? authToken}) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.goodwillActionsEndpoint}/categories'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      final categoriesData = data['categories'] as List<dynamic>? ?? [];
      
      return categoriesData.map((category) => category.toString()).toList();
    } catch (e) {
      throw GoodwillActionException('Failed to fetch goodwill action categories: $e');
    }
  }

  // Verify goodwill action
  Future<Map<String, dynamic>> verifyGoodwillAction({
    required String actionId,
    required bool verified,
    String? verificationNotes,
    required String authToken,
  }) async {
    try {
      final verificationData = {
        'verified': verified,
        if (verificationNotes != null) 'notes': verificationNotes,
      };

      final response = await client.post(
        Uri.parse('$baseUrl${ApiConfig.goodwillActionsEndpoint}/$actionId/verify'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode(verificationData),
      );

      return await _handleResponse(response);
    } catch (e) {
      throw GoodwillActionException('Failed to verify goodwill action: $e');
    }
  }

  // Get goodwill action statistics
  Future<Map<String, dynamic>> getGoodwillActionStats({
    required String authToken,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['userId'] = userId;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final query = queryParams.isEmpty 
          ? '' 
          : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.goodwillActionsEndpoint}/stats$query'),
        headers: _getHeaders(authToken: authToken),
      );

      return await _handleResponse(response);
    } catch (e) {
      throw GoodwillActionException('Failed to fetch goodwill action statistics: $e');
    }
  }
}

class GoodwillActionException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const GoodwillActionException(
    this.message, {
    this.statusCode,
    this.details,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'GoodwillActionException($statusCode): $message';
    }
    return 'GoodwillActionException: $message';
  }
}
