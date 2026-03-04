import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/user_provider.dart';

class UserWelcome extends ConsumerWidget {
  final bool visible;

  const UserWelcome({super.key, required this.visible});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAccountState = ref.watch(userAccountProvider);
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: userAccountState.when(
          loading: () => const SizedBox(
            height: 60,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
          error: (_, __) => const SizedBox(height: 60),
          data: (userAccount) {
            if (userAccount == null) return const SizedBox(height: 60);
            final username = userAccount.username ?? 'User';
            final balance = userAccount.balance.toStringAsFixed(2);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $username!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                  semanticsLabel: 'Welcome, $username',
                ),
                const SizedBox(height: 4),
                Text(
                  'Your Balance: $balance Loves',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.w600,
                      ),
                  semanticsLabel: 'Your balance is $balance Loves',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

