import 'package:flutter/foundation.dart';
import '../models/proposal.dart';
import '../services/api_client.dart';

class ProposalsProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  List<Proposal> _proposals = [];
  bool _isLoading = false;
  String? _error;

  List<Proposal> get proposals => _proposals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProposalsProvider(this._apiClient);

  Future<void> fetchProposals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _proposals = await _apiClient.getProposals();
    } catch (e) {
      _error = 'Failed to fetch proposals: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

