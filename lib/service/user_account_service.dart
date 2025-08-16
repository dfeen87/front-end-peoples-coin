import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_account.dart';

class UserAccountService {
  final http.Client client;
  final String baseUrl;

  UserAccountService(this.client, {String? baseUrl}) 
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
        throw UserAccountServiceException(
          data['message'] ?? ApiConfig.getErrorMessage(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is UserAccountServiceException) rethrow;
      throw UserAccountServiceException('Invalid response format');
    }
  }

  // Get authenticated user profile
  Future<UserAccount> getAuthenticatedUserProfile({
    required String idToken,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/me'),
        headers: _getHeaders(authToken: idToken),
      );

      final data = await _handleResponse(response);
      return UserAccount.fromJson(data['user'] as Map<String, dynamic>);
    } catch (e) {
      throw UserAccountServiceException('Failed to fetch user profile: $e');
    }
  }

  // Get user profile by ID
  Future<UserAccount> getUserProfile({
    required String userId,
    String? authToken,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/$userId'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      return UserAccount.fromJson(data['user'] as Map<String, dynamic>);
    } catch (e) {
      throw UserAccountServiceException('Failed to fetch user profile: $e');
    }
  }

  // Update user profile
  Future<UserAccount> updateUserProfile({
    required String authToken,
    String? username,
    String? email,
    String? displayName,
    String? bio,
    String? avatarUrl,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (username != null) updateData['username'] = username;
      if (email != null) updateData['email'] = email;
      if (displayName != null) updateData['displayName'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (avatarUrl != null) updateData['avatarUrl'] = avatarUrl;
      if (preferences != null) updateData['preferences'] = preferences;
      if (metadata != null) updateData['metadata'] = metadata;

      final response = await client.put(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/me'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode(updateData),
      );

      final data = await _handleResponse(response);
      return UserAccount.fromJson(data['user'] as Map<String, dynamic>);
    } catch (e) {
      throw UserAccountServiceException('Failed to update user profile: $e');
    }
  }

  // Check username availability
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/check-username?username=${Uri.encodeComponent(username)}'),
        headers: _getHeaders(),
      );

      final data = await _handleResponse(response);
      return data['available'] as bool? ?? false;
    } catch (e) {
      throw UserAccountServiceException('Failed to check username availability: $e');
    }
  }

  // Search users
  Future<List<UserAccount>> searchUsers({
    required String query,
    String? authToken,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query,
      };
      
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final queryString = '?' + queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/search$queryString'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      final usersData = data['users'] as List<dynamic>? ?? [];
      
      return usersData
          .map((userData) => UserAccount.fromJson(userData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw UserAccountServiceException('Failed to search users: $e');
    }
  }

  // Follow user
  Future<void> followUser({
    required String userId,
    required String authToken,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/$userId/follow'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode({}),
      );

      await _handleResponse(response);
    } catch (e) {
      throw UserAccountServiceException('Failed to follow user: $e');
    }
  }

  // Unfollow user
  Future<void> unfollowUser({
    required String userId,
    required String authToken,
  }) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/$userId/follow'),
        headers: _getHeaders(authToken: authToken),
      );

      await _handleResponse(response);
    } catch (e) {
      throw UserAccountServiceException('Failed to unfollow user: $e');
    }
  }

  // Get user followers
  Future<List<UserAccount>> getUserFollowers({
    required String userId,
    String? authToken,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final query = queryParams.isEmpty 
          ? '' 
          : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/$userId/followers$query'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      final usersData = data['followers'] as List<dynamic>? ?? [];
      
      return usersData
          .map((userData) => UserAccount.fromJson(userData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw UserAccountServiceException('Failed to fetch user followers: $e');
    }
  }

  // Get user following
  Future<List<UserAccount>> getUserFollowing({
    required String userId,
    String? authToken,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final query = queryParams.isEmpty 
          ? '' 
          : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/$userId/following$query'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      final usersData = data['following'] as List<dynamic>? ?? [];
      
      return usersData
          .map((userData) => UserAccount.fromJson(userData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw UserAccountServiceException('Failed to fetch user following: $e');
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics({
    required String userId,
    String? authToken,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/$userId/stats'),
        headers: _getHeaders(authToken: authToken),
      );

      return await _handleResponse(response);
    } catch (e) {
      throw UserAccountServiceException('Failed to fetch user statistics: $e');
    }
  }

  // Block user
  Future<void> blockUser({
    required String userId,
    required String authToken,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/$userId/block'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode({}),
      );

      await _handleResponse(response);
    } catch (e) {
      throw UserAccountServiceException('Failed to block user: $e');
    }
  }

  // Unblock user
  Future<void> unblockUser({
    required String userId,
    required String authToken,
  }) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/$userId/block'),
        headers: _getHeaders(authToken: authToken),
      );

      await _handleResponse(response);
    } catch (e) {
      throw UserAccountServiceException('Failed to unblock user: $e');
    }
  }

  // Get blocked users
  Future<List<UserAccount>> getBlockedUsers({
    required String authToken,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final query = queryParams.isEmpty 
          ? '' 
          : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/me/blocked$query'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      final usersData = data['blockedUsers'] as List<dynamic>? ?? [];
      
      return usersData
          .map((userData) => UserAccount.fromJson(userData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw UserAccountServiceException('Failed to fetch blocked users: $e');
    }
  }

  // Report user
  Future<void> reportUser({
    required String userId,
    required String reason,
    String? description,
    required String authToken,
  }) async {
    try {
      final reportData = {
        'reason': reason,
        if (description != null && description.isNotEmpty) 'description': description,
      };

      final response = await client.post(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/$userId/report'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode(reportData),
      );

      await _handleResponse(response);
    } catch (e) {
      throw UserAccountServiceException('Failed to report user: $e');
    }
  }

  // Update user preferences
  Future<UserAccount> updateUserPreferences({
    required String authToken,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/me/preferences'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode({'preferences': preferences}),
      );

      final data = await _handleResponse(response);
      return UserAccount.fromJson(data['user'] as Map<String, dynamic>);
    } catch (e) {
      throw UserAccountServiceException('Failed to update user preferences: $e');
    }
  }

  // Deactivate account
  Future<void> deactivateAccount({
    required String authToken,
    String? reason,
  }) async {
    try {
      final deactivationData = {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      };

      final response = await client.post(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/me/deactivate'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode(deactivationData),
      );

      await _handleResponse(response);
    } catch (e) {
      throw UserAccountServiceException('Failed to deactivate account: $e');
    }
  }

  // Reactivate account
  Future<UserAccount> reactivateAccount({
    required String authToken,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl${ApiConfig.usersEndpoint}/me/reactivate'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode({}),
      );

      final data = await _handleResponse(response);
      return UserAccount.fromJson(data['user'] as Map<String, dynamic>);
    } catch (e) {
      throw UserAccountServiceException('Failed to reactivate account: $e');
    }
  }

  void dispose() {
    client.close();
  }
}

class UserAccountServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const UserAccountServiceException(
    this.message, {
    this.statusCode,
    this.details,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'UserAccountServiceException($statusCode): $message';
    }
    return 'UserAccountServiceException: $message';
  }
}
