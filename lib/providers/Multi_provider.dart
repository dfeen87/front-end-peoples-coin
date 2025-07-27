import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import your providers
import 'state/user_provider.dart';
import 'state/goodwill_actions_provider.dart';
import 'state/proposal_provider.dart';
import 'state/public_ledger_provider.dart';
import 'state/voting_results_provider.dart';

class AppStateProviders extends StatelessWidget {
  final Widget child;

  const AppStateProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(/* pass your API client here */),
        ),
        ChangeNotifierProvider<GoodwillActionsProvider>(
          create: (_) => GoodwillActionsProvider(/* pass API client or repo */),
        ),
        ChangeNotifierProvider<ProposalProvider>(
          create: (_) => ProposalProvider(/* pass API client or repo */),
        ),
        ChangeNotifierProvider<PublicLedgerProvider>(
          create: (_) => PublicLedgerProvider(/* pass API client or repo */),
        ),
        ChangeNotifierProvider<VotingResultsProvider>(
          create: (_) => VotingResultsProvider(/* pass API client or repo */),
        ),
        // Add more providers here as your app grows
      ],
      child: child,
    );
  }
}

