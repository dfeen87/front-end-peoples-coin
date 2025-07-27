import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/user_provider.dart';

class UserWelcome extends StatelessWidget {
  final bool visible;

  const UserWelcome({super.key, required this.visible});

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.isLoading) {
              return const SizedBox(
                height: 60,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            } else if (userProvider.userAccount != null) {
              final username = userProvider.userAccount!.username ?? 'User';
              final balance = userProvider.userAccount!.balance.toStringAsFixed(2);

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
            }
            // When userAccount is null and not loading, show empty space to keep layout stable
            return const SizedBox(height: 60);
          },
        ),
      ),
    );
  }
}

