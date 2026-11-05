import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../core/floating_top_bar.dart';
import '../../core/gradient_background.dart';
import '../auth/auth_providers.dart';
import 'admin_postcard_form_screen.dart';
import 'postcard_model.dart';
import 'postcards_flags.dart';
import 'postcards_providers.dart';

class AdminPostcardsScreen extends ConsumerStatefulWidget {
  const AdminPostcardsScreen({super.key});

  @override
  ConsumerState<AdminPostcardsScreen> createState() => _AdminPostcardsScreenState();
}

class _AdminPostcardsScreenState extends ConsumerState<AdminPostcardsScreen> {
  @override
  Widget build(BuildContext context) {
    if (!kPostcardsEnabled) {
      return const SizedBox.shrink();
    }

    final tokens = Theme.of(context).extension<OceanThemeExtension>() ??
        OceanThemeExtension.defaultTokens;
    final isAdminAsync = ref.watch(isAdminProvider);

    return GradientBackground.blue(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 80.0),
                child: isAdminAsync.when(
                  loading: () => Center(child: CircularProgressIndicator(color: tokens.cyan)),
                  error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white70))),
                  data: (isAdmin) {
                    if (!isAdmin) {
                      return const Center(
                        child: Text(
                          'Access Denied: Administrator permissions required.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      );
                    }

                    return _buildPostcardsList(tokens);
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
                FloatingTopBarButton(
                  icon: Icons.add,
                  tooltip: 'Create Postcard',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AdminPostcardFormScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostcardsList(OceanThemeExtension tokens) {
    final repo = ref.watch(postcardsRepositoryProvider);

    return StreamBuilder<List<Postcard>>(
      stream: repo.streamActivePostcards(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: tokens.cyan));
        }

        final cards = snapshot.data ?? [];

        if (cards.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.landscape_outlined, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                const Text(
                  'No postcards created yet',
                  style: TextStyle(color: Colors.white60, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.cyan,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Create First Postcard'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AdminPostcardFormScreen()),
                    );
                  },
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: cards.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final postcard = cards[index];
            return _buildPostcardRow(postcard, tokens);
          },
        );
      },
    );
  }

  Widget _buildPostcardRow(Postcard postcard, OceanThemeExtension tokens) {
    final repo = ref.read(postcardsRepositoryProvider);

    return ChromeBorderContainer(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    postcard.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: postcard.active,
                  activeThumbColor: tokens.cyan,
                  onChanged: (val) async {
                    await repo.savePostcard(postcard.copyWith(active: val));
                  },
                ),
              ],
            ),
            if (postcard.locationName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                postcard.locationName,
                style: TextStyle(color: tokens.cyan, fontSize: 13),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Zone: (${postcard.zone.lat.toStringAsFixed(4)}, ${postcard.zone.lng.toStringAsFixed(4)}) • Radius: ${postcard.zone.radiusMeters.toStringAsFixed(0)}m',
              style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: tokens.cyan),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AdminPostcardFormScreen(postcard: postcard),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  onPressed: () => _confirmDelete(postcard),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Postcard postcard) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OceanThemeExtension.defaultTokens.surface,
        title: const Text('Delete Postcard', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to permanently delete "${postcard.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(postcardsRepositoryProvider).deletePostcard(postcard.id);
    }
  }
}
