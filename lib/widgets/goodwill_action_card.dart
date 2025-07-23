// lib/widgets/goodwill_action_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/goodwill_action.dart';

class GoodwillActionCard extends StatelessWidget {
  final GoodwillAction action;

  const GoodwillActionCard({super.key, required this.action});

  Widget _buildStatusBadge(GoodwillStatus status) {
    IconData icon;
    Color color;
    String text;

    switch (status) {
      case GoodwillStatus.verified:
        icon = Icons.check_circle;
        color = Colors.green.shade400;
        text = 'Verified';
        break;
      case GoodwillStatus.pendingVerification:
        icon = Icons.hourglass_top_rounded;
        color = Colors.amber.shade600;
        text = 'Pending';
        break;
      case GoodwillStatus.rejected:
        icon = Icons.cancel;
        color = Colors.red.shade400;
        text = 'Rejected';
        break;
      // NEW: Added a case to handle the 'unknown' status.
      case GoodwillStatus.unknown:
        icon = Icons.help_outline;
        color = Colors.grey.shade600;
        text = 'Unknown';
        break;
    }

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
    );
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    action.actionType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(action.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              action.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Value: ${action.lovesValue} Loves',
                  style: TextStyle(
                    color: Colors.amber[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat.yMMMd().format(action.createdAt),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
