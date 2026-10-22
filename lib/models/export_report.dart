class ExportReport {
  const ExportReport({
    required this.id,
    required this.uid,
    required this.fileName,
    required this.periodLabel,
    required this.generatedAt,
    required this.fileSizeBytes,
    this.localPath,
    this.storageUrl,
    this.status = 'ready_local',
    this.errorMessage,
  });

  final String id;
  final String uid;
  final String fileName;
  final String periodLabel;
  final DateTime generatedAt;
  final int fileSizeBytes;
  final String? localPath;
  final String? storageUrl;
  final String status;
  final String? errorMessage;

  ExportReport copyWith({
    String? id,
    String? uid,
    String? fileName,
    String? periodLabel,
    DateTime? generatedAt,
    int? fileSizeBytes,
    String? localPath,
    String? storageUrl,
    String? status,
    String? errorMessage,
  }) {
    return ExportReport(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      fileName: fileName ?? this.fileName,
      periodLabel: periodLabel ?? this.periodLabel,
      generatedAt: generatedAt ?? this.generatedAt,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      localPath: localPath ?? this.localPath,
      storageUrl: storageUrl ?? this.storageUrl,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'fileName': fileName,
      'periodLabel': periodLabel,
      'generatedAt': generatedAt.toUtc().toIso8601String(),
      'fileSizeBytes': fileSizeBytes,
      if (localPath != null) 'localPath': localPath,
      if (storageUrl != null) 'storageUrl': storageUrl,
      'status': status,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  factory ExportReport.fromMap(Map<String, dynamic> map) {
    return ExportReport(
      id: map['id'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      fileName: map['fileName'] as String? ?? 'report.pdf',
      periodLabel: map['periodLabel'] as String? ?? 'Kỳ báo cáo',
      generatedAt:
          DateTime.tryParse(map['generatedAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      localPath: map['localPath'] as String?,
      storageUrl: map['storageUrl'] as String?,
      status: map['status'] as String? ?? 'ready_local',
      errorMessage: map['errorMessage'] as String?,
    );
  }
}
