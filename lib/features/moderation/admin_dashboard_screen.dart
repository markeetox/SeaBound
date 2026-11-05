import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../core/floating_top_bar.dart';
import '../../core/gradient_background.dart';
import '../auth/auth_providers.dart';
import 'admin_moderation_repository.dart';
import '../postcards/postcards_flags.dart';
import 'report_model.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _selectedStatus = 'all'; // 'all', 'pending', 'under_review', 'resolved', 'dismissed'
  String _selectedContentType = 'all'; // 'all', 'spot', 'trip', 'user'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(isAdminProvider);
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
                child: isAdminAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(color: tokens.cyan),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error checking permissions: $err',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  data: (isAdmin) {
                    if (!isAdmin) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.gpp_bad, size: 64, color: Colors.redAccent),
                            const SizedBox(height: 16),
                            const Text(
                              'Access Denied',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You do not have administrative privileges.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tokens.surface,
                                foregroundColor: tokens.cyan,
                              ),
                              onPressed: () => context.go('/home'),
                              child: const Text('Back to Home'),
                            ),
                          ],
                        ),
                      );
                    }

                    return _buildDashboardContent(tokens);
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
              actions: [
                if (kPostcardsEnabled)
                  FloatingTopBarButton(
                    icon: Icons.landscape,
                    tooltip: 'Manage Postcards',
                    onPressed: () => context.push('/admin/postcards'),
                  ),
                FloatingTopBarButton(
                  icon: Icons.history,
                  tooltip: 'Audit History',
                  onPressed: () => context.push('/admin/history'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(OceanThemeExtension tokens) {
    final repo = ref.watch(adminModerationRepositoryProvider);

    return StreamBuilder<Map<String, int>>(
      stream: repo.getReportCountsStream(),
      builder: (context, countsSnap) {
        final counts = countsSnap.data ?? {
          'pending': 0,
          'under_review': 0,
          'resolved': 0,
          'dismissed': 0,
          'total': 0,
        };

        return StreamBuilder<List<ReportItem>>(
          stream: repo.getReportsStream(
            statusFilter: _selectedStatus == 'all' ? null : _selectedStatus,
          ),
          builder: (context, reportsSnap) {
            final reports = reportsSnap.data ?? [];
            final filteredReports = reports.where((r) {
              if (_selectedContentType != 'all' && r.contentType != _selectedContentType) {
                return false;
              }
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                final matchesCategory = ReportItem.getCategoryLabel(r.category).toLowerCase().contains(query);
                final matchesExplanation = r.explanation.toLowerCase().contains(query);
                final matchesId = r.contentId.toLowerCase().contains(query);
                if (!matchesCategory && !matchesExplanation && !matchesId) return false;
              }
              return true;
            }).toList();

            return RefreshIndicator(
              color: tokens.cyan,
              backgroundColor: tokens.surface,
              onRefresh: () async {
                setState(() {});
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Moderation Hub',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildMetricCards(counts, tokens),
                          const SizedBox(height: 16),
                          _buildSearchField(tokens),
                          const SizedBox(height: 12),
                          _buildFilters(tokens),
                          const SizedBox(height: 16),
                          Text(
                            'Report Queue (${filteredReports.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  if (reportsSnap.connectionState == ConnectionState.waiting && !reportsSnap.hasData)
                    SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: tokens.cyan),
                      ),
                    )
                  else if (filteredReports.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            const Text(
                              'No reports matching current filter',
                              style: TextStyle(color: Colors.white60, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final report = filteredReports[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                            child: _buildReportCard(report, tokens),
                          );
                        },
                        childCount: filteredReports.length,
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCards(Map<String, int> counts, OceanThemeExtension tokens) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            label: 'Pending',
            count: counts['pending'] ?? 0,
            color: Colors.amberAccent,
            statusKey: 'pending',
            tokens: tokens,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            label: 'Reviewing',
            count: counts['under_review'] ?? 0,
            color: tokens.cyan,
            statusKey: 'under_review',
            tokens: tokens,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            label: 'Resolved',
            count: (counts['resolved'] ?? 0) + (counts['dismissed'] ?? 0),
            color: Colors.lightGreenAccent,
            statusKey: 'resolved',
            tokens: tokens,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required int count,
    required Color color,
    required String statusKey,
    required OceanThemeExtension tokens,
  }) {
    final isSelected = _selectedStatus == statusKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = _selectedStatus == statusKey ? 'all' : statusKey;
        });
      },
      child: ChromeBorderContainer(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : tokens.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(OceanThemeExtension tokens) {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search explanation, category, content ID...',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        prefixIcon: Icon(Icons.search, color: tokens.cyan),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white70),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: tokens.surface.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.cyan),
        ),
      ),
      onChanged: (val) {
        setState(() => _searchQuery = val.trim());
      },
    );
  }

  Widget _buildFilters(OceanThemeExtension tokens) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All Status', _selectedStatus == 'all', () {
            setState(() => _selectedStatus = 'all');
          }, tokens),
          const SizedBox(width: 8),
          _buildFilterChip('Pending', _selectedStatus == 'pending', () {
            setState(() => _selectedStatus = 'pending');
          }, tokens),
          const SizedBox(width: 8),
          _buildFilterChip('Under Review', _selectedStatus == 'under_review', () {
            setState(() => _selectedStatus = 'under_review');
          }, tokens),
          const SizedBox(width: 8),
          _buildFilterChip('Resolved', _selectedStatus == 'resolved', () {
            setState(() => _selectedStatus = 'resolved');
          }, tokens),
          const SizedBox(width: 8),
          _buildFilterChip('Dismissed', _selectedStatus == 'dismissed', () {
            setState(() => _selectedStatus = 'dismissed');
          }, tokens),
          const SizedBox(width: 16),
          Container(height: 20, width: 1, color: Colors.white24),
          const SizedBox(width: 16),
          _buildFilterChip('All Types', _selectedContentType == 'all', () {
            setState(() => _selectedContentType = 'all');
          }, tokens),
          const SizedBox(width: 8),
          _buildFilterChip('Spots', _selectedContentType == 'spot', () {
            setState(() => _selectedContentType = 'spot');
          }, tokens),
          const SizedBox(width: 8),
          _buildFilterChip('Trips', _selectedContentType == 'trip', () {
            setState(() => _selectedContentType = 'trip');
          }, tokens),
          const SizedBox(width: 8),
          _buildFilterChip('Profiles', _selectedContentType == 'user', () {
            setState(() => _selectedContentType = 'user');
          }, tokens),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, OceanThemeExtension tokens) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected ? tokens.cyan.withValues(alpha: 0.25) : tokens.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? tokens.cyan : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? tokens.cyan : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(ReportItem report, OceanThemeExtension tokens) {
    Color statusColor;
    switch (report.status) {
      case 'pending':
        statusColor = Colors.amberAccent;
        break;
      case 'under_review':
        statusColor = tokens.cyan;
        break;
      case 'resolved':
        statusColor = Colors.lightGreenAccent;
        break;
      case 'dismissed':
        statusColor = Colors.white54;
        break;
      default:
        statusColor = Colors.white70;
    }

    return ChromeBorderContainer(
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push('/admin/reports/${report.id}');
        },
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      report.contentType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      report.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ReportItem.getCategoryLabel(report.category),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (report.explanation.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  report.explanation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Target: ${report.contentId}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    _formatDate(report.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
