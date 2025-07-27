import 'package:flutter/material.dart';
import '../models/proposal.dart';
import '../models/vote_to_send.dart';
import '../models/proposal_to_send.dart';
import '../service/api_client.dart';

class ProposalProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  // --- State Variables for Proposal List ---
  List<Proposal> _proposals = [];
  bool _isFetchingProposals = false;
  String? _listError;

  // --- State Variables for Selected Proposal Details ---
  Proposal? _selectedProposal;
  bool _isFetchingDetails = false;
  String? _detailsError;

  // --- State Variables for Actions ---
  bool _isSubmittingProposal = false;
  bool _isSubmittingVote = false;

  // --- GETTERS ---
  List<Proposal> get proposals => _proposals;
  bool get isFetchingProposals => _isFetchingProposals;
  bool get hasListError => _listError != null;
  String? get listError => _listError;

  Proposal? get selectedProposal => _selectedProposal;
  bool get isFetchingDetails => _isFetchingDetails;
  bool get hasDetailsError => _detailsError != null;
  String? get detailsError => _detailsError;

  bool get isSubmittingProposal => _isSubmittingProposal;
  bool get isSubmittingVote => _isSubmittingVote;

  // --- CONSTRUCTOR ---
  ProposalProvider(this._apiClient);

  // --- METHODS ---

  Future<void> fetchProposals({String? status}) async {
    _isFetchingProposals = true;
    _listError = null;
    notifyListeners();

    try {
      final fetchedProposals = await _apiClient.listProposals(status: status);
      _proposals = fetchedProposals;
    } catch (e) {
      _listError = 'Failed to load proposals: ${e.toString()}';
      print('Error fetching proposals: $_listError');
    } finally {
      _isFetchingProposals = false;
      notifyListeners();
    }
  }

  Future<void> fetchProposalDetails(String proposalId) async {
    _isFetchingDetails = true;
    _detailsError = null;
    notifyListeners();

    try {
      _selectedProposal = await _apiClient.getProposalDetails(proposalId);
      if (_selectedProposal == null) {
        _detailsError = 'Proposal not found.';
      }
    } catch (e) {
      _detailsError = 'Failed to load proposal details: ${e.toString()}';
      print('Error fetching proposal details: $_detailsError');
    } finally {
      _isFetchingDetails = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createProposal(ProposalToSend proposal) async {
    _isSubmittingProposal = true;
    _detailsError = null;
    notifyListeners();

    try {
      final result = await _apiClient.createProposal(proposal);
      if (result['success'] == true) {
        print('Proposal created successfully!');
        await fetchProposals(status: 'ACTIVE');
        return {'success': true};
      } else {
        final errorMessage = result['error'] ?? 'Unknown error creating proposal.';
        _detailsError = errorMessage;
        print('API Error creating proposal: $_detailsError');
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      final errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _detailsError = errorMessage;
      print('Caught Error creating proposal: $_detailsError');
      return {'success': false, 'error': errorMessage};
    } finally {
      _isSubmittingProposal = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> submitVote(VoteToSend vote) async {
    _isSubmittingVote = true;
    _detailsError = null;
    notifyListeners();

    try {
      final result = await _apiClient.submitVote(vote);
      if (result['success'] == true) {
        print('Vote submitted successfully!');
        if (_selectedProposal != null) {
          await fetchProposalDetails(_selectedProposal!.id);
        } else {
          await fetchProposals(status: 'ACTIVE');
        }
        return {'success': true};
      } else {
        final errorMessage = result['error'] ?? 'Unknown error submitting vote.';
        _detailsError = errorMessage;
        print('API Error submitting vote: $_detailsError');
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      final errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _detailsError = errorMessage;
      print('Caught Error submitting vote: $_detailsError');
      return {'success': false, 'error': errorMessage};
    } finally {
      _isSubmittingVote = false;
      notifyListeners();
    }
  }
}

