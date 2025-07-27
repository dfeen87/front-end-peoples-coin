import 'package:flutter/material.dart';

class VotingResultsBar extends StatelessWidget {
  final int forVotes;
  final int againstVotes;

  const VotingResultsBar({
    super.key,
    required this.forVotes,
    required this.againstVotes,
  });

  @override
  Widget build(BuildContext context) {
    final totalVotes = forVotes + againstVotes;
    final double forPercentage = totalVotes > 0 ? forVotes / totalVotes : 0.0;
    final double againstPercentage = 1.0 - forPercentage;

    // Convert percentages to flex values out of 1000 for better granularity
    final int forFlex = (forPercentage * 1000).round();
    final int againstFlex = 1000 - forFlex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Visual bar with smooth rounded corners and subtle gradient
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: SizedBox(
            height: 20,
            child: Row(
              children: [
                Expanded(
                  flex: forFlex,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade600, Colors.green.shade300],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: againstFlex,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade600, Colors.red.shade300],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Text labels with semantics for accessibility
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              label: '${(forPercentage * 100).toStringAsFixed(1)} percent for with $forVotes votes',
              child: Text(
                '${(forPercentage * 100).toStringAsFixed(1)}% FOR ($forVotes votes)',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Semantics(
              label: '${(againstPercentage * 100).toStringAsFixed(1)} percent against with $againstVotes votes',
              child: Text(
                '${(againstPercentage * 100).toStringAsFixed(1)}% AGAINST ($againstVotes votes)',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

