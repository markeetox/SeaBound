import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'postcard_model.dart';

class PostcardUnlockedDialog extends StatelessWidget {
  final Postcard postcard;

  const PostcardUnlockedDialog({super.key, required this.postcard});

  static void show(BuildContext context, Postcard postcard) {
    showDialog(
      context: context,
      builder: (dialogCtx) => PostcardUnlockedDialog(postcard: postcard),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<OceanThemeExtension>() ??
        OceanThemeExtension.defaultTokens;

    return AlertDialog(
      backgroundColor: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white24, width: 1.5),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.cyan.withValues(alpha: 0.15),
              border: Border.all(color: tokens.cyan),
            ),
            child: Icon(
              Icons.markunread_mailbox_rounded,
              size: 48,
              color: tokens.cyan,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'NEW POSTCARD EARNED!',
            style: TextStyle(
              color: Colors.amberAccent,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            postcard.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (postcard.locationName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              postcard.locationName,
              style: TextStyle(
                color: tokens.cyan,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (postcard.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              postcard.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.cyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Add to Collection',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
