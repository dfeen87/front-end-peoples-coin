import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/vote.dart';

class VoteService {
  final http.Client client;
  final String baseUrl;

  VoteService(this.client, {String? baseUrl}) 
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
        throw VoteServiceException(
          data['message'] ?? ApiConfig.getErrorMessage(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is VoteServiceException) rethrow;
      throw VoteServiceException('Invalid response format');
    }
  }

  // Submit a vote
  Future<Vote> submitVote({
    required String proposalId,
    required String choice,
    String? comment,
    required String authToken,
  }) async {
    try {
      final voteData = {
        'proposalId': proposalId,
        'choice': choice,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };

      final response = await client.post(
        Uri.parse('$baseUrl${ApiConfig.votesEndpoint}'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode(voteData),
      );

      final data = await _handleResponse(response);
      return Vote.fromJson(data['vote'] as Map<String, dynamic>);
    } catch (e) {
      throw VoteServiceException('Failed to submit vote: $e');
    }
  }

  // Get vote by ID
  Future<Vote> getVote({
    required String voteId,
    String? authToken,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.votesEndpoint}/$voteId'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      return Vote.fromJson(data['vote'] as Map<String, dynamic>);
    } catch (e) {
      throw VoteServiceException('Failed to fetch vote: $e');
    }
  }

  // Update vote (if allowed)
  Future<Vote> updateVote({
    required String voteId,
    String? choice,
    String? comment,
    required String authToken,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (choice != null) updateData['choice'] = choice;
      if (comment != null) updateData['comment'] = comment;

      final response = await client.put(
        Uri.parse('$baseUrl${ApiConfig.votesEndpoint}/$voteId'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode(updateData),
      );

      final data = await _handleResponse(response);
      return Vote.fromJson(data['vote'] as Map<String, dynamic>);
    } catch (e) {
      throw VoteServiceException('Failed to update vote: $e');
    }
  }

  // Delete vote (if allowed)
  Future<void> deleteVote({
    required String voteId,
    required String authToken,
  }) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl${ApiConfig.votesEndpoint}/$voteId'),
        headers: _getHeaders(authToken: authToken),
      );

      await _handleResponse(response);
    } catch (e) {
      throw VoteServiceException('Failed to delete vote: $e');
    }
  }

  // Get votes by proposal
  Future<List<Vote>> getVotesByProposal({
    required String proposalId,
    String? authToken,
    int? limit,
    int? offset,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, String>{
        'proposalId': proposalId,
      };
      
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

      final query = '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.votesEndpoint}/by-proposal$query'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      final votesData = data['votes'] as List<dynamic>? ?? [];
      
      return votesData
          .map((voteData) => Vote.fromJson(voteData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw VoteServiceException('Failed to fetch votes by proposal: $e');
    }
  }

  // Get votes by user
  Future<List<Vote>> getVotesByUser({
    required String userId,
    String? authToken,
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'userId': userId,
      };
      
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final query = '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.votesEndpoint}/by-user$query'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      final votesData = data['votes'] as List<dynamic>? ?? [];
      
      return votesData
          .map((voteData) => Vote.fromJson(voteData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw VoteServiceException('Failed to fetch votes by user: $e');
    }
  }

  // Get user's vote on specific proposal
  Future<Vote?> getUserVoteOnProposal({
    required String proposalId,
    required String authToken,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.votesEndpoint}/user-vote?proposalId=$proposalId'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      final voteData = data['vote'] as Map<String, dynamic>?;
      
      return voteData != null ? Vote.fromJson(voteData) : null;
    } catch (e) {
      if (e is VoteServiceException && e.statusCode == 404) {
        return null; // User hasn't voted yet
      }
      throw VoteServiceException('Failed to fetch user vote on proposal: $e');
    }
  }

  // Get vote statistics for a proposal
  Future<Map<String, dynamic>> getVoteStatistics({
    required String proposalId,
    String? authToken,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.votesEndpoint}/stats?proposalId=$proposalId'),
        headers: _getHeaders(authToken: authToken),
      );

      return await _handleResponse(response);
    } catch (e) {
      throw VoteServiceException('Failed to fetch vote statistics: $e');
    }
  }

  // Validate vote eligibility
  Future<Map<String, dynamic>> checkVoteEligibility({
    required String proposalId,
    required String authToken,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.votesEndpoint}/eligibility?proposalId=$proposalId'),
        headers: _getHeaders(authToken: authToken),
      );

      return await _handleResponse(response);
    } catch (e) {
      throw VoteServiceException('Failed to check vote eligibility: $e');
    }
  }

  // Get vote history for user
  Future<List<Vote>> getUserVoteHistory({
    required String authToken,
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final query = queryParams.isEmpty 
          ? '' 
          : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.votesEndpoint}/history$query'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = await _handleResponse(response);
      final votesData = data['votes'] as List<dynamic>? ?? [];
      
      return votesData
          .map((voteData) => Vote.fromJson(voteData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw VoteServiceException('Failed to fetch vote history: $e');
    }
  }

  // Bulk vote operations
  Future<List<Vote>> submitBulkVotes({
    required List<Map<String, dynamic>> votesData,
    required String authToken,
  }) async {
    try {
      final bulkData = {
        'votes': votesData,
      };

      final response = await client.post(
        Uri.parse('$baseUrl${ApiConfig.votesEndpoint}/bulk'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode(bulkData),
      );

      final data = await _handleResponse(response);
      final votesResponseData = data['votes'] as List<dynamic>? ?? [];
      
      return votesResponseData
          .map((voteData) => Vote.fromJson(voteData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw VoteServiceException('Failed to submit bulk votes: $e');
    }
  }

  // Get voting power for user
  Future<Map<String, dynamic>> getUserVotingPower({
    required String authToken,
    String? proposalId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (proposalId != null) queryParams['proposalId'] = proposalId;

      final query = queryParams.isEmpty 
          ? '' 
          : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.votesEndpoint}/voting-power$query'),
        headers: _getHeaders(authToken: authToken),
      );

      return await _handleResponse(response);
    } catch (e) {
      throw VoteServiceException('Failed to fetch voting power: $e');
    }
  }

  void dispose() {
    client.close();
  }
}

class VoteServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const VoteServiceException(
    this.message, {
    this.statusCode,
    this.details,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'VoteServiceException($statusCode): $message';
    }
    return 'VoteServiceException: $message';
  }
}
    
