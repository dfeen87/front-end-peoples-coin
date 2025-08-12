import 'package:flutter/foundation.dart';
import '../service/api_service.dart';

class VotingProvider with ChangeNotifier {
  final ApiService _apiService;

  final Map<String, int> _forVotes = {};
  final Map<String, int> _againstVotes = {};

  bool _isLoading = false;
  String? _error;

  VotingProvider(this._apiService);

  // Expose unmodifiable views to prevent external mutation
  Map<String, int> get forVotes => Map.unmodifiable(_forVotes);
  Map<String, int> get againstVotes => Map.unmodifiable(_againstVotes);

  bool get isLoading => _isLoading;
  String? get error => _error;

  int getForVotes(String proposalId) => _forVotes[proposalId] ?? 0;
  int getAgainstVotes(String proposalId) => _againstVotes[proposalId] ?? 0;

  /// Fetch voting results securely using ID token
  Future<void> fetchVotingResults(String proposalId, String idToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _apiService.getVotingResults(proposalId, idToken);

      _forVotes[proposalId] = (results['forVotes'] is int) ? results['forVotes'] as int : 0;
      _againstVotes[proposalId] = (results['againstVotes'] is int) ? results['againstVotes'] as int : 0;
    } catch (e, stacktrace) {
      _error = 'Failed to fetch voting results';
      if (kDebugMode) {
        print('[VotingProvider] Error fetching votes: $e');
        print(stacktrace);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Optional: clear cached votes for a proposal if needed
  void clearVotes(String proposalId) {
    _forVotes.remove(proposalId);
    _againstVotes.remove(proposalId);
    notifyListeners();
  }
}

