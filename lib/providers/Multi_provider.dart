// lib/app_state_providers.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import your providers
import 'state/user_provider.dart';
import 'state/goodwill_processing_provider.dart';
import 'state/proposal_provider.dart';
import 'state/ledger_provider.dart';
import 'state/voting_provider.dart';
import 'service/api_client.dart';

class AppStateProviders extends StatelessWidget {
  final PeoplesCoinApiClient apiClient;
  final Widget child;

  const AppStateProviders({
    super.key,
    required this.apiClient,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => GoodwillProcessingProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ProposalProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => LedgerProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => VotingProvider(apiClient)),
      ],
      child: child,
    );
  }
}
