import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/api_client.dart';
import 'user_provider.dart';
import 'goodwill_processing_provider.dart';
import '../state/proposal_provider.dart';
import 'ledger_provider.dart';
import 'voting_provider.dart';

// API client provider
final apiClientProvider = Provider<PeoplesCoinApiClient>((ref) {
  throw UnimplementedError('API Client must be overridden in main.dart');
});

// State providers
final userProvider = ChangeNotifierProvider<UserProvider>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserProvider(apiClient);
});

final goodwillProcessingProvider = ChangeNotifierProvider<GoodwillProcessingProvider>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GoodwillProcessingProvider(apiClient);
});

final proposalProvider = ChangeNotifierProvider<ProposalProvider>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProposalProvider(apiClient);
});

final ledgerProvider = ChangeNotifierProvider<LedgerProvider>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LedgerProvider(apiClient);
});

final votingProvider = ChangeNotifierProvider<VotingProvider>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VotingProvider(apiClient);
});

