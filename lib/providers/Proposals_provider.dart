import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Needed for ChangeNotifier
import '../models/proposal.dart';
import '../models/proposal_to_send.dart';
import '../models/vote_to_send.dart';
import '../services/api_client.dart';

class ProposalProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  // --- State for the proposals list ---
  List<Proposal> _proposals = [];
  bool _isFetchingProposals = false;
  String? _proposalsError;

  // --- State for a single selected proposal's details ---
  Proposal? _selectedProposal;
  bool _isFetchingDetails = false;
  String? _detailsError;

  // --- State for creating and submitting actions ---
  bool _isCreatingProposal = false;
  bool _isSubmittingVote = false;

  // --- Getters for Proposals List ---
  List<Proposal> get proposals => _proposals;
  bool get isFetchingProposals => _isFetchingProposals;
  bool get hasProposalsError => _proposalsError != null;
  String? get proposalsError => _proposalsError;

  // --- Getters for Selected Proposal Details ---
  Proposal? get selectedProposal => _selectedProposal;
  bool get isFetchingDetails => _isFetchingDetails;
  bool get hasDetailsError => _detailsError != null;
  String? get detailsError => _detailsError;

  // --- Getters for Submission Status ---
  bool get isCreatingProposal => _isCreatingProposal;
  bool get isSubmittingVote => _isSubmittingVote;

  ProposalProvider(this._apiClient);

  /// Fetches a list of proposals, optionally filtered by status.
  Future<void> fetchProposals({String? status}) async {
    _isFetchingProposals = true;
    _proposalsError = null;
    notifyListeners();

    try {
      _proposals = await _apiClient.getProposals(status: status);
      if (kDebugMode) print('[ProposalProvider] Fetched ${_proposals.length} proposals.');
    } catch (e) {
      _proposalsError = 'Failed to fetch proposals: $e';
      if (kDebugMode) print('[ProposalProvider] Error fetching proposals: $e');
      _proposals = []; // Clear old data on error
    } finally {
      _isFetchingProposals = false;
      notifyListeners();
    }
  }

  /// Fetches a single proposal's details by its ID.
  Future<void> fetchProposalDetails(String proposalId) async {
    _isFetchingDetails = true;
    _detailsError = null;
    notifyListeners();

    try {
      _selectedProposal = await _apiClient.getProposalDetails(proposalId);
      if (kDebugMode) print('[ProposalProvider] Fetched details for proposal: ${proposalId}.');
    } catch (e) {
      _detailsError = 'Failed to fetch proposal details: $e';
      if (kDebugMode) print('[ProposalProvider] Error fetching details: $e');
      _selectedProposal = null; // Clear old data on error
    } finally {
      _isFetchingDetails = false;
      notifyListeners();
    }
  }

  /// Submits a new proposal to the backend.
  Future<Map<String, dynamic>> createProposal(ProposalToSend proposal) async {
    _isCreatingProposal = true;
    notifyListeners();
    
    try {
      final response = await _apiClient.createProposal(proposal);
      if (kDebugMode) print('[ProposalProvider] Proposal created successfully.');
      return {'success': true, 'data': response};
    } catch (e) {
      if (kDebugMode) print('[ProposalProvider] Failed to create proposal: $e');
      return {'success': false, 'error': e.toString()};
    } finally {
      _isCreatingProposal = false;
      notifyListeners();
    }
  }

  /// Submits a vote for a proposal.
  Future<Map<String, dynamic>> submitVote(VoteToSend vote) async {
    _isSubmittingVote = true;
    notifyListeners();

    try {
      final response = await _apiClient.submitVote(vote);
      if (kDebugMode) print('[ProposalProvider] Vote submitted successfully.');

      // Refresh the proposal details to show the updated vote counts
      if (_selectedProposal != null) {
        await fetchProposalDetails(_selectedProposal!.id);
      }
      return {'success': true, 'data': response};
    } catch (e) {
      if (kDebugMode) print('[ProposalProvider] Failed to submit vote: $e');
      return {'success': false, 'error': e.toString()};
    } finally {
      _isSubmittingVote = false;
      notifyListeners();
    }
  }
}
