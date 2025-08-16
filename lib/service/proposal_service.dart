import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/proposal.dart';
import '../models/vote.dart';

class ProposalService {
  final http.Client client;
  final String baseUrl;

  ProposalService(this.client, {String? baseUrl}) 
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  // Default constructor for when no client is provided
  ProposalService.defaultClient({String? baseUrl}) 
      : client = http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl;

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
        throw ProposalServiceException(
          data['message'] ?? ApiConfig.getErrorMessage(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ProposalServiceException) rethrow;
      throw ProposalServiceException('Invalid response format');
    }
  }

  // Get list of proposals
  Future<List<Proposal>> listProposals({
    String? status,
    String? idToken,
    int? limit,
    int? offset,
    String? category,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (category != null) queryParams['category'] = category;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

      final query = queryParams.isEmpty 
          ? '' 
          : '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.proposalsEndpoint}$query'),
        headers: _getHeaders(authToken: idToken),
      );

      final data = await _handleResponse(response);
      final proposalsData = data['proposals'] as List<dynamic>? ?? [];
      
      return proposalsData
          .map((proposalData) => Proposal.fromJson(proposalData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ProposalServiceException('Failed to fetch proposals: $e');
    }
  }

  // Get proposal details
  Future<Proposal> getProposalDetails({
    required String proposalId,
    required String idToken,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.proposalsEndpoint}/$proposalId'),
        headers: _getHeaders(authToken: idToken),
      );

      final data = await _handleResponse(response);
      return Proposal.fromJson(data['proposal'] as Map<String, dynamic>);
    } catch (e) {
      throw ProposalServiceException('Failed to fetch proposal details: $e');
    }
  }

  // Create a new proposal
  Future<Proposal> createProposal({
    required String title,
    required String description,
    required String category,
    String? proposerUserId,
    Map<String, dynamic>? metadata,
    DateTime? votingEndDate,
    required String idToken,
  }) async {
    try {
      final proposalData = {
        'title': title,
        'description': description,
        'category': category,
        if (proposerUserId != null) 'proposerUserId': proposerUserId,
        if (metadata != null) 'metadata': metadata,
        if (votingEndDate != null) 'votingEndDate': votingEndDate.toIso8601String(),
      };

      final response = await client.post(
        Uri.parse('$baseUrl${ApiConfig.proposalsEndpoint}'),
        headers: _getHeaders(authToken: idToken),
        body: json.encode(proposalData),
      );

      final data = await _handleResponse(response);
      return Proposal.fromJson(data['proposal'] as Map<String, dynamic>);
    } catch (e) {
      throw ProposalServiceException('Failed to create proposal: $e');
    }
  }

  // Update proposal
  Future<Proposal> updateProposal({
    required String proposalId,
    String? title,
    String? description,
    String? category,
    Map<String, dynamic>? metadata,
    DateTime? votingEndDate,
    required String idToken,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category;
      if (metadata != null) updateData['metadata'] = metadata;
      if (votingEndDate != null) updateData['votingEndDate'] = votingEndDate.toIso8601String();

      final response = await client.put(
        Uri.parse('$baseUrl${ApiConfig.proposalsEndpoint}/$proposalId'),
        headers: _getHeaders(authToken: idToken),
        body: json.encode(updateData),
      );

      final data = await _handleResponse(response);
      return Proposal.fromJson(data['proposal'] as Map<String, dynamic>);
    } catch (e) {
      throw ProposalServiceException('Failed to update proposal: $e');
    }
  }

  // Delete proposal
  Future<void> deleteProposal({
    required String proposalId,
    required String idToken,
  }) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl${ApiConfig.proposalsEndpoint}/$proposalId'),
        headers: _getHeaders(authToken: idToken),
      );

      await _handleResponse(response);
    } catch (e) {
      throw ProposalServiceException('Failed to delete proposal: $e');
    }
  }

  // Submit vote on proposal
  Future<Vote> submitVote({
    required String proposalId,
    required String choice, // 'yes', 'no', 'abstain'
    String? comment,
    required String idToken,
  }) async {
    try {
      final voteData = {
        'choice': choice,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };

      final response = await client.post(
        Uri.parse('$baseUrl${ApiConfig.proposalsEndpoint}/$proposalId/votes'),
        headers: _getHeaders(authToken: idToken),
        body: json.encode(voteData),
      );

      final data = await _handleResponse(response);
      return Vote.fromJson(data['vote'] as Map<String, dynamic>);
    } catch (e) {
      throw ProposalServiceException('Failed to submit vote: $e');
    }
  }

  // Get votes for a proposal
  Future<List<Vote>> getProposalVotes({
    required String proposalId,
    String? idToken,
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
        Uri.parse('$baseUrl${ApiConfig.proposalsEndpoint}/$proposalId/votes$query'),
        headers: _getHeaders(authToken: idToken),
      );

      final data = await _handleResponse(response);
      final votesData = data['votes'] as List<dynamic>? ?? [];
      
      return votesData
          .map((voteData) => Vote.fromJson(voteData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ProposalServiceException('Failed to fetch proposal votes: $e');
    }
  }

  // Get user's vote on a proposal
  Future<Vote?> getUserVote({
    required String proposalId,
    required String idToken,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.proposalsEndpoint}/$proposalId/votes/me'),
        headers: _getHeaders(authToken: idToken),
      );

      final data = await _handleResponse(response);
      final voteData = data['vote'] as Map<String, dynamic>?;
      
      return voteData != null ? Vote.fromJson(voteData) : null;
    } catch (e) {
      if (e is ProposalServiceException && e.statusCode == 404) {
        return null; // User hasn't voted yet
      }
      throw ProposalServiceException('Failed to fetch user vote: $e');
    }
  }

  // Get proposal statistics
  Future<Map<String, dynamic>> getProposalStats({
    required String proposalId,
    String? idToken,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.proposalsEndpoint}/$proposalId/stats'),
        headers: _getHeaders(authToken: idToken),
      );

      return await _handleResponse(response);
    } catch (e) {
      throw ProposalServiceException('Failed to fetch proposal statistics: $e');
    }
  }

  // Search proposals
  Future<List<Proposal>> searchProposals({
    required String query,
    String? idToken,
    String? category,
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query,
      };
      
      if (category != null) queryParams['category'] = category;
      if (status != null) queryParams['status'] = status;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final queryString = '?' + queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.proposalsEndpoint}/search$queryString'),
        headers: _getHeaders(authToken: idToken),
      );

      final data = await _handleResponse(response);
      final proposalsData = data['proposals'] as List<dynamic>? ?? [];
      
      return proposalsData
          .map((proposalData) => Proposal.fromJson(proposalData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ProposalServiceException('Failed to search proposals: $e');
    }
  }

  // Get proposal categories
  Future<List<String>> getProposalCategories({String? idToken}) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConfig.proposalsEndpoint}/categories'),
        headers: _getHeaders(authToken: idToken),
      );

      final data = await _handleResponse(response);
      final categoriesData = data['categories'] as List<dynamic>? ?? [];
      
      return categoriesData.map((category) => category.toString()).toList();
    } catch (e) {
      throw ProposalServiceException('Failed to fetch proposal categories: $e');
    }
  }

  // Close proposal voting
  Future<Proposal> closeProposalVoting({
    required String proposalId,
    required String idToken,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl${ApiConfig.proposalsEndpoint}/$proposalId/close'),
        headers: _getHeaders(authToken: idToken),
        body: json.encode({}),
      );

      final data = await _handleResponse(response);
      return Proposal.fromJson(data['proposal'] as Map<String, dynamic>);
    } catch (e) {
      throw ProposalServiceException('Failed to close proposal voting: $e');
    }
  }

  void dispose() {
    client.close();
  }
}

class ProposalServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ProposalServiceException(
    this.message, {
    this.statusCode,
    this.details,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ProposalServiceException($statusCode): $message';
    }
    return 'ProposalServiceException: $message';
  }
}
