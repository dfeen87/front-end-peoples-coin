import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/backend_status_service.dart';
import '../service/api_client.dart';

final backendStatusServiceProvider =
    ChangeNotifierProvider<BackendStatusService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BackendStatusService(apiClient);
});

class BackendStatusScreen extends ConsumerWidget {
  const BackendStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendStatusService = ref.watch(backendStatusServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Backend Status')),
      body: Builder(
        builder: (context) {
          if (backendStatusService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (backendStatusService.error != null) {
            return Center(child: Text('Error: ${backendStatusService.error}'));
          }
          final status = backendStatusService.currentStatus;
          if (status == null) {
            return const Center(child: Text('No backend status available.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Node Version: ${status.nodeVersion}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildStatusRow('Metabolic System', status.metabolicActive),
                _buildStatusRow('Nervous System', status.nervousActive),
                _buildStatusRow('Endocrine System', status.endocrineActive),
                _buildStatusRow('Immune System', status.immuneActive),
                const Divider(height: 32),
                const Text('Recent Events:', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: status.recentEvents.length,
                    itemBuilder: (context, index) {
                      final event = status.recentEvents[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.bolt),
                        title: Text(event, style: const TextStyle(fontSize: 14)),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusRow(String systemName, bool isActive) {
    return Row(
      children: [
        Icon(isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        Text(systemName),
      ],
    );
  }
}

