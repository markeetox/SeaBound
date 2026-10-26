import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationDisclaimer {
  static const String disclaimerText =
      'Seabound is for planning and reference only. Depth, weather, tide, and chart information may be incomplete, delayed, or inaccurate and must never be used for navigation or safety decisions. Always use official charts and current forecasts, and follow local regulations.';

  static const String prefsKey = 'navigation_disclaimer_acknowledged';

  static Future<bool> isAcknowledged() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  static Future<void> setAcknowledged() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }

  static void showFullDisclaimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text('Navigation Disclaimer'),
            ],
          ),
          content: const Text(disclaimerText),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showFirstLaunchDialogIfNeeded(BuildContext context) async {
    final acknowledged = await isAcknowledged();
    if (!acknowledged && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                SizedBox(width: 8),
                Expanded(child: Text('Notice & Disclaimer')),
              ],
            ),
            content: const SingleChildScrollView(
              child: Text(
                disclaimerText,
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () async {
                  await setAcknowledged();
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text('I understand'),
              ),
            ],
          );
        },
      );
    }
  }
}
