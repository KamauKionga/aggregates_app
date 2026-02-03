import 'enums.dart';

class DocumentModel {
  final String id;
  final String name;
  final String type; // e.g., 'image', 'pdf'
  final String? url;
  VerificationStatus status;

  DocumentModel({
    required this.id,
    required this.name,
    required this.type,
    this.url,
    this.status = VerificationStatus.incomplete,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'url': url,
        'status': status.toString(),
      };

  factory DocumentModel.fromMap(Map<String, dynamic> m) {
    final s = (m['status'] as String?) ?? '';
    return DocumentModel(
      id: m['id'] as String,
      name: m['name'] as String,
      type: m['type'] as String,
      url: m['url'] as String?,
      status: s.contains('approved')
          ? VerificationStatus.approved
          : s.contains('rejected')
              ? VerificationStatus.rejected
              : s.contains('underReview')
                  ? VerificationStatus.underReview
                  : s.contains('submitted')
                      ? VerificationStatus.submitted
                      : VerificationStatus.incomplete,
    );
  }
}
