import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/proposal.dart';
import '../models/proposal_to_send.dart';
import '../models/vote_to_send.dart';
import '../service/api_client.dart';

class ProposalProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  List<Proposal> _proposals = [];
  bool _isFetchingProposals = false;
  String? _proposalsError;

  Proposal? _selectedProposal;
  bool _isFetchingDetails = false;
  String? _detailsError;

  bool _isCreatingProposal = false;
  bool _isSubmittingVote = false;

  List<Proposal> get proposals => _proposals;
  bool get isFetchingProposals => _isFetchingProposals;
  bool get hasProposalsError => _proposalsError != null;
  String? get proposalsError => _proposalsError;

  Proposal? get selectedProposal => _selectedProposal;
  bool get isFetchingDetails => _isFetchingDetails;
  bool get hasDetailsError => _detailsError != null;
  String? get detailsError => _detailsError;

  bool get isCreatingProposal => _isCreatingProposal;
  bool get isSubmittingVote => _isSubmittingVote;

  ProposalProvider(this._apiClient);

  Future<void> fetchProposals({String? status, required String idToken}) async {
    _isFetchingProposals = true;
    _proposalsError = null;
    notifyListeners();

    try {
      _proposals = await _apiClient.listProposals(status: status, idToken: idToken);
      if (kDebugMode) print('[ProposalProvider] Fetched ${_proposals.length} proposals.');
    } catch (e) {
      _proposalsError = 'Failed to fetch proposals: $e';
      if (kDebugMode) print('[ProposalProvider] Error fetching proposals: $e');
      _proposals = [];
    } finally {
      _isFetchingProposals = false;
      notifyListeners();
    }
  }

  Future<void> fetchProposalDetails(String proposalId, {required String idToken}) async {
    _isFetchingDetails = true;
    _detailsError = null;
    notifyListeners();

    try {
      _selectedProposal = await _apiClient.getProposalDetails(
        proposalId: proposalId,
        idToken: idToken,
      );
      if (kDebugMode) print('[ProposalProvider] Fetched details for proposal: $proposalId.');
    } catch (e) {
      _detailsError = 'Failed to fetch proposal details: $e';
      if (kDebugMode) print('[ProposalProvider] Error fetching details: $e');
      _selectedProposal = null;
    } finally {
      _isFetchingDetails = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createProposal(
      {required ProposalToSend proposal, required String idToken}) async {
    _isCreatingProposal = true;
    notifyListeners();

    try {
      final response = await _apiClient.createProposal(
        proposal: proposal,
        idToken: idToken,
      );
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

  Future<Map<String, dynamic>> submitVote(
      {required VoteToSend vote, required String idToken}) async {
    _isSubmittingVote = true;
    notifyListeners();

    try {
      final response = await _apiClient.submitVote(
        vote: vote,
        idToken: idToken,
      );
      if (kDebugMode) print('[ProposalProvider] Vote submitted successfully.');

      if (_selectedProposal != null) {
        // You were missing the idToken here.
        await fetchProposalDetails(_selectedProposal!.id, idToken: idToken);
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
