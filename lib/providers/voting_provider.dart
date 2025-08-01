kimport 'package:flutter/foundation.dart';
import '../services/api_client.dart';

class VotingProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  Map<String, int> _forVotes = {};
  Map<String, int> _againstVotes = {};
  bool _isLoading = false;
  String? _error;

  VotingProvider(this._apiClient);

  int getForVotes(String proposalId) => _forVotes[proposalId] ?? 0;
  int getAgainstVotes(String proposalId) => _againstVotes[proposalId] ?? 0;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchVotingResults(String proposalId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _apiClient.getVotingResults(proposalId);
      _forVotes[proposalId] = results['forVotes'] ?? 0;
      _againstVotes[proposalId] = results['againstVotes'] ?? 0;
    } catch (e) {
      _error = 'Failed to fetch voting results: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
