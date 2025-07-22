import 'package:flutter/foundation.dart'; // Corrected import path
import '../models/proposal.dart';
import '../services/api_client.dart';

/// Manages the state of governance proposals.
///
/// This class will hold the current list of proposals and provide methods
/// to fetch or update them.
/// It uses ChangeNotifier to notify any widgets that are listening
/// when the proposals data changes.
class ProposalProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  List<Proposal> _proposals = [];
  bool _isLoading = false;
  String? _error;

  List<Proposal> get proposals => _proposals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProposalProvider(this._apiClient);

  /// Fetches the list of governance proposals from the API.
  /// Optionally filters by status (e.g., "ACTIVE", "CLOSED").
  Future<void> fetchProposals({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _proposals = await _apiClient.listProposals(status: status); // Removed
    } catch (e) {
      _error = "Failed to fetch proposals: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
