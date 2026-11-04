import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../core/floating_top_bar.dart';
import '../../core/gradient_background.dart';
import '../auth/auth_providers.dart';
import 'admin_moderation_repository.dart';
import 'report_model.dart';

class AdminReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;

  const AdminReportDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<AdminReportDetailScreen> createState() => _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends ConsumerState<AdminReportDetailScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
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
                child: FutureBuilder<ReportItem?>(
                  future: repo.getReportById(widget.reportId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: tokens.cyan),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading report: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    final report = snapshot.data;
                    if (report == null) {
                      return const Center(
                        child: Text(
                          'Report not found',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      );
                    }

                    return _buildReportDetail(report, tokens);
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

  Widget _buildReportDetail(ReportItem report, OceanThemeExtension tokens) {
    final repo = ref.watch(adminModerationRepositoryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
              ),
            ),

          // Report Header Card
          ChromeBorderContainer(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: tokens.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tokens.cyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: tokens.cyan),
                        ),
                        child: Text(
                          report.contentType.toUpperCase(),
                          style: TextStyle(
                            color: tokens.cyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      _buildStatusPill(report.status, tokens),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ReportItem.getCategoryLabel(report.category),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (report.explanation.isNotEmpty) ...[
                    const Text(
                      'Reporter Explanation:',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.explanation,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildMetadataRow('Report ID', report.id),
                  _buildMetadataRow('Reporter UID', report.reporterId),
                  _buildMetadataRow('Content Author UID', report.authorId),
                  _buildMetadataRow('Submitted At', _formatDate(report.createdAt)),
                  if (report.resolvedAt != null) ...[
                    _buildMetadataRow('Resolved At', _formatDate(report.resolvedAt!)),
                    _buildMetadataRow('Resolved By', report.resolvedBy ?? 'Admin'),
                    if (report.resolutionNotes != null)
                      _buildMetadataRow('Resolution Notes', report.resolutionNotes!),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Target Content Inspection Card
          Text(
            'Target Content Inspection',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>?>(
            future: repo.fetchTargetContent(
              contentType: report.contentType,
              contentId: report.contentId,
            ),
            builder: (context, targetSnap) {
              if (targetSnap.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: tokens.cyan));
              }

              final targetData = targetSnap.data;
              if (targetData == null) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tokens.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Target content document not found or has been deleted.',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              final moderationStatus = targetData['moderationStatus'] as String? ?? 'active';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTargetCard(report.contentType, targetData, moderationStatus, tokens),
                  const SizedBox(height: 24),
                  if (report.contentType != 'user') ...[
                    Text(
                      'Content Moderation Actions',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildContentModerationButtons(report, moderationStatus, tokens),
                    const SizedBox(height: 24),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white70, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Profile reports permit review and report resolution/dismissal only. Account actions are strictly restricted.',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              );
            },
          ),

          // Report Disposition / Triage Actions
          Text(
            'Report Ticket Disposition',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildReportDispositionButtons(report, tokens),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTargetCard(
    String contentType,
    Map<String, dynamic> data,
    String moderationStatus,
    OceanThemeExtension tokens,
  ) {
    return ChromeBorderContainer(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  contentType == 'spot'
                      ? 'Spot: ${data['name'] ?? 'Untitled'}'
                      : contentType == 'trip'
                          ? 'Trip: ${data['title'] ?? 'Untitled'}'
                          : 'Profile: ${data['username'] ?? 'User'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusPill(moderationStatus, tokens),
              ],
            ),
            const Divider(color: Colors.white12, height: 24),
            if (contentType == 'spot' || contentType == 'trip') ...[
              if (data['description'] != null)
                _buildMetadataRow('Description', data['description'].toString()),
              if (data['notes'] != null)
                _buildMetadataRow('Notes', data['notes'].toString()),
              if (data['species'] != null)
                _buildMetadataRow('Species', (data['species'] as List).join(', ')),
              if (data['latitude'] != null && data['longitude'] != null)
                _buildMetadataRow('Coordinates', '${data['latitude']}, ${data['longitude']}'),
              if (data['locationName'] != null)
                _buildMetadataRow('Location', data['locationName'].toString()),
            ] else ...[
              if (data['username'] != null)
                _buildMetadataRow('Username', data['username'].toString()),
              if (data['avatarId'] != null)
                _buildMetadataRow('Avatar ID', data['avatarId'].toString()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentModerationButtons(
    ReportItem report,
    String currentModerationStatus,
    OceanThemeExtension tokens,
  ) {
    final canHide = currentModerationStatus == 'active';
    final canRestore = currentModerationStatus == 'hidden' || currentModerationStatus == 'removed';
    final canRemove = currentModerationStatus == 'active' || currentModerationStatus == 'hidden';

    return Row(
      children: [
        if (canHide)
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.visibility_off, size: 18),
              label: const Text('Hide Content'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isLoading ? null : () => _confirmModeration(report, currentModerationStatus, 'hidden'),
            ),
          ),
        if (canHide && (canRestore || canRemove)) const SizedBox(width: 8),
        if (canRestore)
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('Restore Active'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isLoading ? null : () => _confirmModeration(report, currentModerationStatus, 'active'),
            ),
          ),
        if (canRestore && canRemove) const SizedBox(width: 8),
        if (canRemove)
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Remove Content'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isLoading ? null : () => _confirmModeration(report, currentModerationStatus, 'removed'),
            ),
          ),
      ],
    );
  }

  Widget _buildReportDispositionButtons(ReportItem report, OceanThemeExtension tokens) {
    final isClosed = report.status == 'resolved' || report.status == 'dismissed';

    if (isClosed) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white54),
            const SizedBox(width: 12),
            Text(
              'This ticket is ${report.status} and cannot be modified.',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (report.status == 'pending') ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Mark Under Review'),
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.cyan,
                side: BorderSide(color: tokens.cyan),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isLoading ? null : () => _markUnderReview(report),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Resolve Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _isLoading ? null : () => _promptResolveOrDismiss(report, isResolve: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Dismiss Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _isLoading ? null : () => _promptResolveOrDismiss(report, isResolve: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusPill(String status, OceanThemeExtension tokens) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.lightGreenAccent;
        break;
      case 'hidden':
        color = Colors.amberAccent;
        break;
      case 'removed':
        color = Colors.redAccent;
        break;
      case 'pending':
        color = Colors.amberAccent;
        break;
      case 'under_review':
        color = tokens.cyan;
        break;
      case 'resolved':
        color = Colors.lightGreenAccent;
        break;
      case 'dismissed':
        color = Colors.white54;
        break;
      default:
        color = Colors.white70;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markUnderReview(ReportItem report) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminModerationRepositoryProvider);
      await repo.markUnderReview(report.id);
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to mark under review: $e';
      });
    }
  }

  Future<void> _promptResolveOrDismiss(ReportItem report, {required bool isResolve}) async {
    final notesController = TextEditingController();
    final actionName = isResolve ? 'Resolve' : 'Dismiss';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.tokens.surface,
          title: Text('$actionName Report', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to $actionName this report ticket? Once closed, it cannot be reopened.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Resolution notes (optional, max 500 chars)...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isResolve ? Colors.green.shade700 : Colors.grey.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(actionName),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final repo = ref.read(adminModerationRepositoryProvider);
        final user = ref.read(authStateProvider).asData?.value;
        final adminId = user?.uid ?? 'admin';
        final notes = notesController.text.trim();

        if (isResolve) {
          await repo.resolveReport(reportId: report.id, adminId: adminId, resolutionNotes: notes);
        } else {
          await repo.dismissReport(reportId: report.id, adminId: adminId, resolutionNotes: notes);
        }

        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to $actionName report: $e';
        });
      }
    }
  }

  Future<void> _confirmModeration(
    ReportItem report,
    String previousStatus,
    String newStatus,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.tokens.surface,
          title: Text('Change Content Status: $newStatus', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will transition ${report.contentType} from "$previousStatus" to "$newStatus" and record an immutable entry in /moderation_logs.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Reason for action (required, max 500 chars)...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: newStatus == 'removed'
                    ? Colors.red.shade800
                    : newStatus == 'hidden'
                        ? Colors.amber.shade800
                        : Colors.teal.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (reasonController.text.trim().isEmpty) return;
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Confirm Action'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final reason = reasonController.text.trim();
      if (reason.isEmpty) return;

      setState(() => _isLoading = true);
      try {
        final repo = ref.read(adminModerationRepositoryProvider);
        final user = ref.read(authStateProvider).asData?.value;
        final adminId = user?.uid ?? 'admin';

        await repo.moderateContent(
          contentType: report.contentType,
          contentId: report.contentId,
          previousStatus: previousStatus,
          newStatus: newStatus,
          reason: reason,
          adminId: adminId,
        );

        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to moderate content: $e';
        });
      }
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
