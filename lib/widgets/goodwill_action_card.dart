import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/goodwill_action.dart';
import 'base_card.dart';

class GoodwillActionCard extends StatelessWidget {
  final GoodwillAction action;
  final VoidCallback? onTap;
  final int descriptionMaxLines;
  final EdgeInsetsGeometry padding;

  const GoodwillActionCard({
    super.key,
    required this.action,
    this.onTap,
    this.descriptionMaxLines = 2,
    this.padding = const EdgeInsets.all(16),
  });

  Widget _buildStatusBadge(BuildContext context, GoodwillStatus status) {
    IconData icon;
    Color color;
    String text;

    final theme = Theme.of(context);

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
      case GoodwillStatus.unknown:
      default:
        icon = Icons.help_outline;
        color = Colors.grey.shade600;
        text = 'Unknown';
        break;
    }

    return Tooltip(
      message: text,
      child: Chip(
        avatar: Icon(icon, color: Colors.white, size: 16),
        label: Text(text, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseCard(
      onTap: onTap,
      padding: padding,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  action.actionType,
                  style: theme.textTheme.headline6?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(context, action.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            action.description ?? '',
            style: theme.textTheme.bodyText2?.copyWith(color: Colors.white70),
            maxLines: descriptionMaxLines,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Value: ${action.lovesValue} Loves',
                style: theme.textTheme.subtitle1?.copyWith(
                  color: Colors.amber[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat.yMMMd().format(action.createdAt),
                style: theme.textTheme.caption?.copyWith(color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

