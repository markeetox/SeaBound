import 'package:cloud_firestore/cloud_firestore.dart';

class ReportIdValidator {
  static const int maxContentIdLength = 128;
  static const int maxReporterIdLength = 128;
  static const int maxCompositeIdLength = 256;
  static final RegExp _safeIdRegex = RegExp(r'^[a-zA-Z0-9:_-]+$');

  static String generate({
    required String contentType,
    required String contentId,
    required String reporterId,
  }) {
    if (contentType != 'spot' && contentType != 'trip' && contentType != 'user') {
      throw ArgumentError('Invalid content type: $contentType');
    }
    if (contentId.isEmpty || contentId.length > maxContentIdLength) {
      throw ArgumentError('Content ID must be between 1 and $maxContentIdLength characters');
    }
    if (reporterId.isEmpty || reporterId.length > maxReporterIdLength) {
      throw ArgumentError('Reporter ID must be between 1 and $maxReporterIdLength characters');
    }
    if (!_safeIdRegex.hasMatch(contentId) || !_safeIdRegex.hasMatch(reporterId)) {
      throw ArgumentError('IDs must contain only valid canonical characters [a-zA-Z0-9:_-]');
    }

    final compositeId = '${contentType}_${contentId.length}_${contentId}_$reporterId';
    if (compositeId.length > maxCompositeIdLength) {
      throw ArgumentError('Generated report ID exceeds maximum length of $maxCompositeIdLength');
    }
    return compositeId;
  }
}

class ReportItem {
  final String id;
  final String contentType;
  final String contentId;
  final String authorId;
  final String reporterId;
  final String category;
  final String explanation;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolutionNotes;

  const ReportItem({
    required this.id,
    required this.contentType,
    required this.contentId,
    required this.authorId,
    required this.reporterId,
    required this.category,
    this.explanation = '',
    this.status = 'pending',
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNotes,
  });

  static const List<String> validCategories = [
    'offensive_content',
    'harassment',
    'hate_speech',
    'explicit',
    'violence_threats',
    'spam_misleading',
    'illegal_activity',
    'other',
  ];

  static String getCategoryLabel(String category) {
    switch (category) {
      case 'offensive_content':
        return 'Inappropriate or offensive content';
      case 'harassment':
        return 'Harassment or bullying';
      case 'hate_speech':
        return 'Hate speech or discrimination';
      case 'explicit':
        return 'Sexual or explicit content';
      case 'violence_threats':
        return 'Violence or threats';
      case 'spam_misleading':
        return 'Spam or misleading information';
      case 'illegal_activity':
        return 'Dangerous or illegal activity';
      case 'other':
      default:
        return 'Other';
    }
  }

  factory ReportItem.create({
    required String contentType,
    required String contentId,
    required String authorId,
    required String reporterId,
    required String category,
    String explanation = '',
  }) {
    if (!validCategories.contains(category)) {
      throw ArgumentError('Invalid report category: $category');
    }
    if (explanation.length > 300) {
      throw ArgumentError('Explanation must not exceed 300 characters');
    }

    final id = ReportIdValidator.generate(
      contentType: contentType,
      contentId: contentId,
      reporterId: reporterId,
    );

    return ReportItem(
      id: id,
      contentType: contentType,
      contentId: contentId,
      authorId: authorId,
      reporterId: reporterId,
      category: category,
      explanation: explanation,
      status: 'pending',
      createdAt: DateTime.now(),
    );
  }

  factory ReportItem.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return ReportItem(
      id: map['id'] as String? ?? docId,
      contentType: map['contentType'] as String? ?? '',
      contentId: map['contentId'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      reporterId: map['reporterId'] as String? ?? '',
      category: map['category'] as String? ?? 'other',
      explanation: map['explanation'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: map['createdAt'] != null ? parseDateTime(map['createdAt']) : DateTime.now(),
      resolvedAt: map['resolvedAt'] != null ? parseDateTime(map['resolvedAt']) : null,
      resolvedBy: map['resolvedBy'] as String?,
      resolutionNotes: map['resolutionNotes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contentType': contentType,
      'contentId': contentId,
      'authorId': authorId,
      'reporterId': reporterId,
      'category': category,
      'explanation': explanation,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
      if (resolvedBy != null) 'resolvedBy': resolvedBy,
      if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
    };
  }
}
