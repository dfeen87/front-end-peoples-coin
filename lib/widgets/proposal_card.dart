// lib/widgets/proposal_card.dart

import 'package:flutter/material.dart';
import '../models/proposal.dart';
import '../pages/proposal_detail_page.dart'; // Import the detail page

class ProposalCard extends StatelessWidget {
  final Proposal proposal;

  const ProposalCard({super.key, required this.proposal});

  // Helper to build a small chip for status or type
  Widget _buildInfoChip(String label, Color color) {
    return Chip(
      label: Text(label),
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
    );
  }

  // Helper to get a user-friendly string for the time remaining
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () {
          // This will navigate to the detail page when a card is tapped
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProposalDetailPage(proposalId: proposal.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
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
                  // Assuming proposal.proposalType is a string from your model
                  _buildInfoChip(proposal.proposalType, Colors.blueGrey.shade400),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                proposal.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _getTimeStatus(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
