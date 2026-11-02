import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'moderation_repository.dart';
import 'report_model.dart';

class ReportContentSheet extends ConsumerStatefulWidget {
  final String contentType;
  final String contentId;
  final String contentTitle;
  final String authorId;
  final String authorName;

  const ReportContentSheet({
    super.key,
    required this.contentType,
    required this.contentId,
    required this.contentTitle,
    required this.authorId,
    required this.authorName,
  });

  static Future<void> show({
    required BuildContext context,
    required String contentType,
    required String contentId,
    required String contentTitle,
    required String authorId,
    required String authorName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportContentSheet(
        contentType: contentType,
        contentId: contentId,
        contentTitle: contentTitle,
        authorId: authorId,
        authorName: authorName,
      ),
    );
  }

  @override
  ConsumerState<ReportContentSheet> createState() => _ReportContentSheetState();
}

class _ReportContentSheetState extends ConsumerState<ReportContentSheet> {
  String? _selectedCategory;
  final _explanationController = TextEditingController();
  bool _isSubmitting = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _explanationController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) {
      setState(() {
        _statusMessage = 'You must be signed in to submit a report.';
      });
      return;
    }

    if (user.uid == widget.authorId) {
      setState(() {
        _statusMessage = 'You cannot report your own content.';
      });
      return;
    }

    if (_selectedCategory == null) {
      setState(() {
        _statusMessage = 'Please select a reason for reporting.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });

    try {
      final report = ReportItem.create(
        contentType: widget.contentType,
        contentId: widget.contentId,
        authorId: widget.authorId,
        reporterId: user.uid,
        category: _selectedCategory!,
        explanation: _explanationController.text.trim(),
      );

      final repo = ref.read(moderationRepositoryProvider);
      final result = await repo.submitReport(report);

      if (!mounted) return;

      if (result.isSubmittedReceiptFailed) {
        setState(() {
          _isSubmitting = false;
          _isSuccess = true;
          _statusMessage = 'Your report was successfully received by moderation. (Note: local receipt could not be saved).';
        });
      } else if (result.isSuccess) {
        setState(() {
          _isSubmitting = false;
          _isSuccess = true;
          _statusMessage = null;
        });
      } else if (result.isAlreadyReported) {
        setState(() {
          _isSubmitting = false;
          _statusMessage = 'You have already submitted a report for this content.';
        });
      } else {
        setState(() {
          _isSubmitting = false;
          _statusMessage = result.errorMessage ?? 'Submission failed. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _statusMessage = 'Failed to submit report: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(authStateProvider).asData?.value?.uid;
    final isSelf = currentUid != null && currentUid == widget.authorId;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  const Icon(Icons.flag_rounded, color: Color(0xFFEF4444), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Report Content',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Content Details Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Reporting ${widget.contentType.toUpperCase()}: "${widget.contentTitle}" by ${widget.authorName}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),

              if (_isSuccess) ...[
                // Success State
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Report Submitted',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Thank you for helping keep the Seabound community safe. Our team will review this content.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Self-Reporting Guard
                if (isSelf)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7F1D1D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'You cannot report your own content.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  )
                else ...[
                  // Error / Status Message
                  if (_statusMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7F1D1D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],

                  // Category Selection List
                  const Text(
                    'Select a reason:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 8),

                  ...ReportItem.validCategories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF38BDF8) : Colors.white12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 18,
                              color: isSelected ? const Color(0xFF38BDF8) : Colors.white38,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ReportItem.getCategoryLabel(category),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Optional Explanation Field
                  TextField(
                    controller: _explanationController,
                    maxLength: 300,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Additional details (optional)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                      hintText: 'Describe why this content violates community standards...',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                      counterStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting || _selectedCategory == null ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Submit Report',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
