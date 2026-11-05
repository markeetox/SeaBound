import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import 'postcard_model.dart';
import 'postcards_flags.dart';
import 'postcards_providers.dart';

class PostcardsSection extends ConsumerWidget {
  const PostcardsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kPostcardsEnabled) {
      return const SizedBox.shrink();
    }

    final tokens = Theme.of(context).extension<OceanThemeExtension>() ??
        OceanThemeExtension.defaultTokens;

    final earnedAsync = ref.watch(userEarnedPostcardsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Postcards',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              earnedAsync.when(
                data: (cards) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tokens.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tokens.cyan.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${cards.length} Collected',
                    style: TextStyle(
                      color: tokens.cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        earnedAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Error loading postcards: $err',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
          data: (cards) {
            if (cards.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ChromeBorderContainer(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: tokens.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.markunread_mailbox_outlined,
                          size: 40,
                          color: tokens.cyan.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Drive through a postcard zone to earn your first one',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 170,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: cards.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final earned = cards[index];
                  return _buildPostcardCard(context, earned, tokens);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPostcardCard(
    BuildContext context,
    EarnedPostcard earned,
    OceanThemeExtension tokens,
  ) {
    final formattedDate = DateFormat.yMMMd().format(earned.earnedAt);

    return ChromeBorderContainer(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: tokens.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.landscape,
                    size: 44,
                    color: tokens.cyan.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              earned.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formattedDate,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
