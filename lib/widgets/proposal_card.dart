import 'package:flutter/material.dart';
import '../models/proposal.dart';
import '../pages/proposal_detail_page.dart';
import 'base_card.dart';

class ProposalCard extends StatelessWidget {
  final Proposal proposal;

  const ProposalCard({super.key, required this.proposal});

  // Builds a small info chip with label and background color
  Widget _buildInfoChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
    );
  }

  // Returns a human-readable voting time status
  String _getTimeStatus() {
    if (proposal.voteEndTime == null) return "No end date set";

    final now = DateTime.now();
    final difference = proposal.voteEndTime!.difference(now);

    if (difference.isNegative) {
      return "Voting has ended";
    } else if (difference.inDays > 1) {
      return "Voting ends in ${difference.inDays} days";
    } else if (difference.inHours > 1) {
      return "Voting ends in ${difference.inHours} hours";
    } else if (difference.inMinutes > 0) {
      return "Voting ends in ${difference.inMinutes} minutes";
    } else {
      return "Voting ends soon";
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProposalDetailPage(proposalId: proposal.id),
          ),
        );
      },
      splashColor: Colors.purple.withOpacity(0.2),
      highlightColor: Colors.purple.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                _buildInfoChip(proposal.status.name.toUpperCase(), Colors.purple.shade400),
                _buildInfoChip(proposal.proposalType, Colors.blueGrey.shade400),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              proposal.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              semanticsLabel: 'Proposal title: ${proposal.title}',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  _getTimeStatus(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

