import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../core/floating_top_bar.dart';
import '../../core/gradient_background.dart';
import 'admin_moderation_repository.dart';
import 'moderation_log_model.dart';

class AdminAuditHistoryScreen extends ConsumerWidget {
  const AdminAuditHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(adminModerationRepositoryProvider);
    final tokens = Theme.of(context).extension<OceanThemeExtension>() ??
        OceanThemeExtension.defaultTokens;

    return GradientBackground.blue(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 80.0),
                child: StreamBuilder<List<ModerationLog>>(
                  stream: repo.getModerationLogsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(color: tokens.cyan),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading audit logs: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    final logs = snapshot.data ?? [];
                    if (logs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history_toggle_off, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            const Text(
                              'No moderation actions recorded yet',
                              style: TextStyle(color: Colors.white60, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Moderation Audit Log',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Immutable records of content status changes',
                                  style: TextStyle(color: Colors.white60, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final log = logs[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                                child: _buildLogCard(log, tokens),
                              );
                            },
                            childCount: logs.length,
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 40),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            FloatingTopBar(
              leading: FloatingTopBarButton(
                icon: Icons.arrow_back,
                tooltip: 'Back',
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(ModerationLog log, OceanThemeExtension tokens) {
    Color newStatusColor;
    switch (log.newStatus) {
      case 'active':
        newStatusColor = Colors.lightGreenAccent;
        break;
      case 'hidden':
        newStatusColor = Colors.amberAccent;
        break;
      case 'removed':
        newStatusColor = Colors.redAccent;
        break;
      default:
        newStatusColor = Colors.white70;
    }

    return ChromeBorderContainer(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: tokens.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log.contentType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${log.previousStatus.toUpperCase()} → ',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Text(
                      log.newStatus.toUpperCase(),
                      style: TextStyle(
                        color: newStatusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDate(log.createdAt),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Reason: ${log.reason.isEmpty ? "None provided" : log.reason}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Content ID: ${log.contentId}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace'),
                ),
                Text(
                  'Admin: ${log.adminId}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
