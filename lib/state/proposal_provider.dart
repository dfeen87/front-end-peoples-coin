// lib/state/proposal_provider.dart

import 'package:flutter/foundation.dart';
import '../models/proposal.dart';
import '../models/proposal_to_send.dart'; // Import the model for sending
import '../models/vote_to_send.dart';
import '../services/api_client.dart';

class ProposalProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  // State for the list of proposals
  List<Proposal> _proposals = [];
  bool _isFetchingProposals = false;
  String? _proposalsError;

  // State for a single, selected proposal
  Proposal? _selectedProposal;
  bool _isFetchingDetails = false;
  String? _detailsError;
  bool _isSubmittingVote = false;

  // NEW: State for creating a proposal
  bool _isSubmittingProposal = false;

  // Public getters for the list
  List<Proposal> get proposals => _proposals;
  bool get isFetchingProposals => _isFetchingProposals;
  bool get hasListError => _proposalsError != null;
  String? get listError => _proposalsError;

  // Public getters for details and voting
  Proposal? get selectedProposal => _selectedProposal;
  bool get isFetchingDetails => _isFetchingDetails;
  bool get hasDetailsError => _detailsError != null;
  String? get detailsError => _detailsError;
  bool get isSubmittingVote => _isSubmittingVote;

  // NEW: Public getter for creating a proposal
  bool get isSubmittingProposal => _isSubmittingProposal;

  ProposalProvider(this._apiClient);

  Future<void> fetchProposals({String? status}) async {
    // ... (existing method)
  }

  Future<void> fetchProposalDetails(String proposalId) async {
    // ... (existing method)
  }

  Future<bool> submitVote(VoteToSend vote) async {
    // ... (existing method)
  }

  // NEW: Method to create a new proposal
  Future<Map<String, dynamic>> createProposal(ProposalToSend proposal) async {
    _isSubmittingProposal = true;
    notifyListeners();
    Map<String, dynamic> result = {'success': false, 'error': 'An unknown error occurred.'};
    try {
      result = await _apiClient.createProposal(proposal);
      if (result['success']) {
        // After a successful submission, refresh the proposals list
        await fetchProposals(status: 'ACTIVE');
      }
    } catch (e) {
      print("Proposal creation failed: $e");
      result = {'success': false, 'error': e.toString()};
    } finally {
      _isSubmittingProposal = false;
      notifyListeners();
    }
    return result;
  }
}
