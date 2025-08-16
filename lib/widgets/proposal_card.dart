import 'package:flutter/material.dart';
import '../models/proposal.dart';
import '../pages/proposal_detail_page.dart';
import 'base_card.dart';

class ProposalCard extends StatelessWidget {
  final Proposal proposal;
  final VoidCallback? onTap;
  final VoidCallback? onVote;
  final bool showTimer;

  const ProposalCard({
    super.key,
    required this.proposal,
    this.onTap,
    this.onVote,
    this.showTimer = true,
  });

  // Info chip
  Widget _infoChip(String label, Color color) => Chip(
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      );

  // Human-readable time status
  String _timeStatus() {
    final endTime = proposal.voteEndTime;
    if (endTime == null) return "No end date set";

    final diff = endTime.difference(DateTime.now());
    if (diff.isNegative) return "Voting has ended";
    if (diff.inDays > 1) return "Voting ends in ${diff.inDays} days";
    if (diff.inHours > 1) return "Voting ends in ${diff.inHours} hours";
    if (diff.inMinutes > 0) return "Voting ends in ${diff.inMinutes} minutes";
    return "Voting ends soon";
  }

  // Status badge
  Widget _statusBadge() {
    final statusMap = {
      'active': Colors.green,
      'closed': Colors.blue,
      'draft': Colors.grey,
      'rejected': Colors.red,
    };
    final color = statusMap[proposal.status.name.toLowerCase()] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        proposal.status.name[0].toUpperCase() + proposal.status.name.substring(1),
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Voting stats (fallback when vote button is not shown)
  Widget _votingStats(BuildContext context) => Row(
        children: [
          Icon(Icons.how_to_vote, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(width: 4),
          Text('Voting ended', style: Theme.of(context).textTheme.bodySmall),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onTap: onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProposalDetailPage(proposalId: proposal.id)),
            );
          },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Status and type chips
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _statusBadge(),
              _infoChip(proposal.proposalType, Colors.blueGrey.shade400),
            ],
          ),
          const SizedBox(height: 12),

          // Title
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

          // Optional timer/status
          if (showTimer)
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  _timeStatus(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),

          const SizedBox(height: 12),

          // Vote button (if active) or fallback voting stats
          if (proposal.status.name.toLowerCase() == 'active' && onVote != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onVote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Vote'),
              ),
            )
          else
            _votingStats(context),
        ]),
      ),
    );
  }
}

