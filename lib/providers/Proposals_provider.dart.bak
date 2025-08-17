import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/proposal.dart';
import '../models/proposal_to_send.dart';
import '../models/vote_to_send.dart';
import '../service/api_client.dart';
import 'app_state_providers.dart';

// --- State ---
class ProposalState {
  final List<Proposal> proposals;
  final bool isFetchingProposals;
  final String? proposalsError;

  final Proposal? selectedProposal;
  final bool isFetchingDetails;
  final String? detailsError;

  final bool isCreatingProposal;
  final String? createProposalError;

  final bool isSubmittingVote;
  final String? submitVoteError;

  const ProposalState({
    this.proposals = const [],
    this.isFetchingProposals = false,
    this.proposalsError,
    this.selectedProposal,
    this.isFetchingDetails = false,
    this.detailsError,
    this.isCreatingProposal = false,
    this.createProposalError,
    this.isSubmittingVote = false,
    this.submitVoteError,
  });

  ProposalState copyWith({
    List<Proposal>? proposals,
    bool? isFetchingProposals,
    String? proposalsError,
    Proposal? selectedProposal,
    bool? isFetchingDetails,
    String? detailsError,
    bool? isCreatingProposal,
    String? createProposalError,
    bool? isSubmittingVote,
    String? submitVoteError,
  }) {
    return ProposalState(
      proposals: proposals ?? this.proposals,
      isFetchingProposals: isFetchingProposals ?? this.isFetchingProposals,
      proposalsError: proposalsError,
      selectedProposal: selectedProposal ?? this.selectedProposal,
      isFetchingDetails: isFetchingDetails ?? this.isFetchingDetails,
      detailsError: detailsError,
      isCreatingProposal: isCreatingProposal ?? this.isCreatingProposal,
      createProposalError: createProposalError,
      isSubmittingVote: isSubmittingVote ?? this.isSubmittingVote,
      submitVoteError: submitVoteError,
    );
  }

  factory ProposalState.initial() => const ProposalState();
}

// --- Notifier ---
class ProposalNotifier extends StateNotifier<ProposalState> {
  final PeoplesCoinApiClient _apiClient;

  ProposalNotifier(this._apiClient) : super(ProposalState.initial());

  Future<void> fetchProposals({String? status}) async {
    state = state.copyWith(isFetchingProposals: true, proposalsError: null);
    try {
      final rawList = await _apiClient.getProposals(status: status);
      final proposals = rawList.map((json) => Proposal.fromJson(json)).toList();
      state = state.copyWith(proposals: proposals);
    } catch (e) {
      state = state.copyWith(proposals: [], proposalsError: 'Failed to fetch proposals: $e');
    } finally {
      state = state.copyWith(isFetchingProposals: false);
    }
  }

  Future<void> fetchProposalDetails(String proposalId) async {
    state = state.copyWith(isFetchingDetails: true, detailsError: null);
    try {
      final json = await _apiClient.getProposalDetails(proposalId: proposalId);
      state = state.copyWith(selectedProposal: Proposal.fromJson(json));
    } catch (e) {
      state = state.copyWith(selectedProposal: null, detailsError: 'Failed to fetch proposal details: $e');
    } finally {
      state = state.copyWith(isFetchingDetails: false);
    }
  }

  Future<void> createProposal(ProposalToSend proposal) async {
    state = state.copyWith(isCreatingProposal: true, createProposalError: null);
    try {
      await _apiClient.createProposal(proposal.toJson());
      await fetchProposals(); // refresh proposals
    } catch (e) {
      state = state.copyWith(createProposalError: 'Failed to create proposal: $e');
    } finally {
      state = state.copyWith(isCreatingProposal: false);
    }
  }

  Future<void> submitVote(VoteToSend vote) async {
    state = state.copyWith(isSubmittingVote: true, submitVoteError: null);
    try {
      await _apiClient.submitVote(vote.toJson());
      if (state.selectedProposal != null) {
        await fetchProposalDetails(state.selectedProposal!.id);
      }
    } catch (e) {
      state = state.copyWith(submitVoteError: 'Failed to submit vote: $e');
    } finally {
      state = state.copyWith(isSubmittingVote: false);
    }
  }
}

// --- Provider ---
final proposalProviderNotifier =
    StateNotifierProvider<ProposalNotifier, ProposalState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProposalNotifier(apiClient);
});

