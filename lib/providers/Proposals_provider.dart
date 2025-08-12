import 'package:flutter/foundation.dart';
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
  String? _createProposalError;

  bool _isSubmittingVote = false;
  String? _submitVoteError;

  List<Proposal> get proposals => _proposals;
  bool get isFetchingProposals => _isFetchingProposals;
  String? get proposalsError => _proposalsError;

  Proposal? get selectedProposal => _selectedProposal;
  bool get isFetchingDetails => _isFetchingDetails;
  String? get detailsError => _detailsError;

  bool get isCreatingProposal => _isCreatingProposal;
  String? get createProposalError => _createProposalError;

  bool get isSubmittingVote => _isSubmittingVote;
  String? get submitVoteError => _submitVoteError;

  ProposalProvider(this._apiClient);

  /// Fetch proposals, optionally filtered by status
  Future<void> fetchProposals({String? status}) async {
    _isFetchingProposals = true;
    _proposalsError = null;
    notifyListeners();

    try {
      final rawList = await _apiClient.getProposals(status: status);
      _proposals = rawList.map((json) => Proposal.fromJson(json)).toList();
    } catch (e) {
      _proposalsError = 'Failed to fetch proposals: $e';
      _proposals = [];
    } finally {
      _isFetchingProposals = false;
      notifyListeners();
    }
  }

  /// Fetch detailed info about a specific proposal
  Future<void> fetchProposalDetails(String proposalId) async {
    _isFetchingDetails = true;
    _detailsError = null;
    notifyListeners();

    try {
      final json = await _apiClient.getProposalDetails(proposalId: proposalId);
      _selectedProposal = Proposal.fromJson(json);
    } catch (e) {
      _detailsError = 'Failed to fetch proposal details: $e';
      _selectedProposal = null;
    } finally {
      _isFetchingDetails = false;
      notifyListeners();
    }
  }

  /// Create a new proposal and refresh the list on success
  Future<void> createProposal(ProposalToSend proposal) async {
    _isCreatingProposal = true;
    _createProposalError = null;
    notifyListeners();

    try {
      await _apiClient.createProposal(proposal.toJson());
      // Refresh proposals after creation
      await fetchProposals();
    } catch (e) {
      _createProposalError = 'Failed to create proposal: $e';
    } finally {
      _isCreatingProposal = false;
      notifyListeners();
    }
  }

  /// Submit a vote and refresh proposal details on success
  Future<void> submitVote(VoteToSend vote) async {
    _isSubmittingVote = true;
    _submitVoteError = null;
    notifyListeners();

    try {
      await _apiClient.submitVote(vote.toJson());
      if (_selectedProposal != null) {
        await fetchProposalDetails(_selectedProposal!.id);
      }
    } catch (e) {
      _submitVoteError = 'Failed to submit vote: $e';
    } finally {
      _isSubmittingVote = false;
      notifyListeners();
    }
  }
}

