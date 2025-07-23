// lib/widgets/voting_results_bar.dart

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
    final double forPercentage = totalVotes > 0 ? forVotes / totalVotes : 0;

    return Column(
      children: [
        // The visual bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                Expanded(
                  flex: (forPercentage * 100).toInt(),
                  child: Container(color: Colors.green.shade400),
                ),
                Expanded(
                  flex: 100 - (forPercentage * 100).toInt(),
                  child: Container(color: Colors.red.shade400),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // The text labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(forPercentage * 100).toStringAsFixed(1)}% FOR ($forVotes votes)', style: TextStyle(color: Colors.green.shade300)),
            Text('${((1 - forPercentage) * 100).toStringAsFixed(1)}% AGAINST ($againstVotes votes)', style: TextStyle(color: Colors.red.shade300)),
          ],
        )
      ],
    );
  }
}
