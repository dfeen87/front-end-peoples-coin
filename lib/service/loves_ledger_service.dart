import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class LovesLedgerService {
  final http.Client client;
  final String baseUrl;

  LovesLedgerService(this.client, {String? baseUrl}) 
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
        throw LovesLedgerServiceException(
          data['message'] ?? ApiConfig.getErrorMessage(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is LovesLedgerServiceException) rethrow;
      throw LovesLedgerServiceException('Invalid response format');
    }
  }

  // Send loves to another user
  Future<Map<String, dynamic>> sendLoves({
    required String recipientUserId,
    required double amount,
    String? message,
    String? transactionType,
    Map<String, dynamic>? metadata,
    required String authToken,
  }) async {
    try {
      final transactionData = {
        'recipientUserId': recipientUserId,
        'amount': amount,
        if (message != null && message.isNotEmpty) 'message': message,
        if (transactionType != null) 'transactionType': transactionType,
        if (metadata != null) 'metadata': metadata,
      };

      final response = await client.post(
        Uri.parse('$baseUrl${ApiConfig.ledgerEndpoint}/send'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode(transactionData),
      );

      return await _handleResponse(response);
    } catch (e) {
      throw LovesLedgerServiceException('Failed to send loves: $e');
    }
  }

  // Get ledger entries
  Future<List<Map<String, dynamic>>> getLedgerEntries({
    String? authToken,
    String? userId,
    int? limit,
    int? offset,
    String? transactionType,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['userId'] = userId;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (transactionType != null) queryParams['transactionType'] = transactionType;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

      final query = queryParams.isEmpty 
          ? '' 
          : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.ledgerEndpoint}/entries$query'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['entries'] ?? []);
    } catch (e) {
      throw LovesLedgerServiceException('Failed to fetch ledger entries: $e');
    }
  }

  // Search ledger entries
  Future<List<Map<String, dynamic>>> searchLedger({
    required String query,
    String? authToken,
    int? limit,
    int? offset,
    String? transactionType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query,
      };
      
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (transactionType != null) queryParams['transactionType'] = transactionType;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final queryString = '?' + queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.ledgerEndpoint}/search$queryString'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['entries'] ?? []);
    } catch (e) {
      throw LovesLedgerServiceException('Failed to search ledger: $e');
    }
  }

  // Get user balance
  Future<Map<String, dynamic>> getUserBalance({
    String? userId,
    required String authToken,
  }) async {
    try {
      final endpoint = userId != null 
          ? '${ApiConfig.ledgerEndpoint}/balance/$userId'
          : '${ApiConfig.ledgerEndpoint}/balance/me';

      final response = await client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(authToken: authToken),
      );

      return await _handleResponse(response);
    } catch (e) {
      throw LovesLedgerServiceException('Failed to fetch user balance: $e');
    }
  }

  // Get transaction by ID
  Future<Map<String, dynamic>> getTransaction({
    required String transactionId,
    String? authToken,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.ledgerEndpoint}/transactions/$transactionId'),
        headers: _getHeaders(authToken: authToken),
      );

      return await _handleResponse(response);
    } catch (e) {
      throw LovesLedgerServiceException('Failed to fetch transaction: $e');
    }
  }

  // Get user transaction history
  Future<List<Map<String, dynamic>>> getUserTransactionHistory({
    required String authToken,
    int? limit,
    int? offset,
    String? transactionType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (transactionType != null) queryParams['transactionType'] = transactionType;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final query = queryParams.isEmpty 
          ? '' 
          : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.ledgerEndpoint}/transactions/me$query'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['transactions'] ?? []);
    } catch (e) {
      throw LovesLedgerServiceException('Failed to fetch transaction history: $e');
    }
  }

  // Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStats({
    required String authToken,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? period, // 'day', 'week', 'month', 'year'
  }) async {
    try {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['userId'] = userId;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (period != null) queryParams['period'] = period;

      final query = queryParams.isEmpty 
          ? '' 
          : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.ledgerEndpoint}/stats$query'),
        headers: _getHeaders(authToken: authToken),
      );

      return await _handleResponse(response);
    } catch (e) {
      throw LovesLedgerServiceException('Failed to fetch transaction statistics: $e');
    }
  }

  // Create recurring transaction
  Future<Map<String, dynamic>> createRecurringTransaction({
    required String recipientUserId,
    required double amount,
    required String frequency, // 'daily', 'weekly', 'monthly'
    String? message,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? metadata,
    required String authToken,
  }) async {
    try {
      final recurringData = {
        'recipientUserId': recipientUserId,
        'amount': amount,
        'frequency': frequency,
        if (message != null && message.isNotEmpty) 'message': message,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };

      final response = await client.post(
        Uri.parse('$baseUrl${ApiConfig.ledgerEndpoint}/recurring'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode(recurringData),
      );

      return await _handleResponse(response);
    } catch (e) {
      throw LovesLedgerServiceException('Failed to create recurring transaction: $e');
    }
  }

  // Get recurring transactions
  Future<List<Map<String, dynamic>>> getRecurringTransactions({
    required String authToken,
    bool? active,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (active != null) queryParams['active'] = active.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final query = queryParams.isEmpty 
          ? '' 
          : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.ledgerEndpoint}/recurring$query'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['recurringTransactions'] ?? []);
    } catch (e) {
      throw LovesLedgerServiceException('Failed to fetch recurring transactions: $e');
    }
  }

  // Cancel recurring transaction
  Future<void> cancelRecurringTransaction({
    required String recurringTransactionId,
    required String authToken,
  }) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl${ApiConfig.ledgerEndpoint}/recurring/$recurringTransactionId'),
        headers: _getHeaders(authToken: authToken),
      );

      await _handleResponse(response);
    } catch (e) {
      throw LovesLedgerServiceException('Failed to cancel recurring transaction: $e');
    }
  }

  // Get leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({
    String? authToken,
    String? period, // 'day', 'week', 'month', 'all'
    String? type, // 'sent', 'received', 'total'
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (type != null) queryParams['type'] = type;
      if (limit != null) queryParams['limit'] = limit.toString();

      final query = queryParams.isEmpty 
          ? '' 
          : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.ledgerEndpoint}/leaderboard$query'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['leaderboard'] ?? []);
    } catch (e) {
      throw LovesLedgerServiceException('Failed to fetch leaderboard: $e');
    }
  }

  // Validate transaction
  Future<Map<String, dynamic>> validateTransaction({
    required String recipientUserId,
    required double amount,
    required String authToken,
  }) async {
    try {
      final validationData = {
        'recipientUserId': recipientUserId,
        'amount': amount,
      };

      final response = await client.post(
        Uri.parse('$baseUrl${ApiConfig.ledgerEndpoint}/validate'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode(validationData),
      );

      return await _handleResponse(response);
    } catch (e) {
      throw LovesLedgerServiceException('Failed to validate transaction: $e');
    }
  }

  // Get transaction limits
  Future<Map<String, dynamic>> getTransactionLimits({
    required String authToken,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.ledgerEndpoint}/limits'),
        headers: _getHeaders(authToken: authToken),
      );

      return await _handleResponse(response);
    } catch (e) {
      throw LovesLedgerServiceException('Failed to fetch transaction limits: $e');
    }
  }

  // Export transactions
  Future<Map<String, dynamic>> exportTransactions({
    required String authToken,
    String? format, // 'csv', 'json', 'pdf'
    DateTime? startDate,
    DateTime? endDate,
    String? transactionType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (format != null) queryParams['format'] = format;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (transactionType != null) queryParams['transactionType'] = transactionType;

      final query = queryParams.isEmpty 
          ? '' 
          : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.post(
        Uri.parse('$baseUrl${ApiConfig.ledgerEndpoint}/export$query'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode({}),
      );

      return await _handleResponse(response);
    } catch (e) {
      throw LovesLedgerServiceException('Failed to export transactions: $e');
    }
  }

  // Get system statistics
  Future<Map<String, dynamic>> getSystemStatistics({
    String? authToken,
    String? period,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;

      final query = queryParams.isEmpty 
          ? '' 
          : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.ledgerEndpoint}/system-stats$query'),
        headers: _getHeaders(authToken: authToken),
      );

      return await _handleResponse(response);
    } catch (e) {
      throw LovesLedgerServiceException('Failed to fetch system statistics: $e');
    }
  }

  void dispose() {
    client.close();
  }
}

class LovesLedgerServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const LovesLedgerServiceException(
    this.message, {
    this.statusCode,
    this.details,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'LovesLedgerServiceException($statusCode): $message';
    }
    return 'LovesLedgerServiceException: $message';
  }
}
