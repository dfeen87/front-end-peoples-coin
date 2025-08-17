// lib/providers/voting_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/api_service.dart';

// --- State ---
class VotingState {
  final Map<String, int> forVotes;
  final Map<String, int> againstVotes;
  final bool isLoading;
  final String? error;

  const VotingState({
    this.forVotes = const {},
    this.againstVotes = const {},
    this.isLoading = false,
    this.error,
  });

  VotingState copyWith({
    Map<String, int>? forVotes,
    Map<String, int>? againstVotes,
    bool? isLoading,
    String? error,
  }) {
    return VotingState(
      forVotes: forVotes ?? this.forVotes,
      againstVotes: againstVotes ?? this.againstVotes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory VotingState.initial() => const VotingState();
}

// --- Notifier ---
class VotingNotifier extends StateNotifier<VotingState> {
  final ApiService _apiService;

  VotingNotifier(this._apiService) : super(VotingState.initial());

  int getForVotes(String proposalId) => state.forVotes[proposalId] ?? 0;
  int getAgainstVotes(String proposalId) => state.againstVotes[proposalId] ?? 0;

  Future<void> fetchVotingResults(String proposalId, String idToken) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await _apiService.getVotingResults(proposalId, idToken);

      final updatedForVotes = Map<String, int>.from(state.forVotes);
      final updatedAgainstVotes = Map<String, int>.from(state.againstVotes);

      updatedForVotes[proposalId] = (results['forVotes'] is int) ? results['forVotes'] as int : 0;
      updatedAgainstVotes[proposalId] = (results['againstVotes'] is int) ? results['againstVotes'] as int : 0;

      state = state.copyWith(
        forVotes: updatedForVotes,
        againstVotes: updatedAgainstVotes,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to fetch voting results');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void clearVotes(String proposalId) {
    final updatedForVotes = Map<String, int>.from(state.forVotes)..remove(proposalId);
    final updatedAgainstVotes = Map<String, int>.from(state.againstVotes)..remove(proposalId);

    state = state.copyWith(
      forVotes: updatedForVotes,
      againstVotes: updatedAgainstVotes,
    );
  }
}

// --- Provider ---
final votingProviderNotifier =
    StateNotifierProvider<VotingNotifier, VotingState>((ref) {
  final apiService = ApiService();
  return VotingNotifier(apiService);
});

