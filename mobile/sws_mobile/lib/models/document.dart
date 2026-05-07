class Document {
  final int id;
  final String originalName;
  final int size;
  final String uploadDate;
  final String status;

  Document({
    required this.id,
    required this.originalName,
    required this.size,
    required this.uploadDate,
    required this.status,
  });

  factory Document.fromJson(Map<String, dynamic> json) => Document(
    id: json['id'],
    originalName: json['original_name'],
    size: json['size'],
    uploadDate: json['upload_date'],
    status: json['status'],
  );

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
