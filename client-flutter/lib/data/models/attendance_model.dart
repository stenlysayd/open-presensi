class AttendanceRecordModel {
  final String? id;
  final String qrToken;
  final String? memberName;
  final String? regNumber;
  final String? groupName;
  final String recordType;
  final String status;
  final DateTime recordedAt;
  final bool isOffline;

  AttendanceRecordModel({
    this.id,
    required this.qrToken,
    this.memberName,
    this.regNumber,
    this.groupName,
    required this.recordType,
    required this.status,
    required this.recordedAt,
    this.isOffline = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'qr_token': qrToken,
      'record_type': recordType,
      'status': status,
      'recorded_at': recordedAt.toIso8601String(),
      'is_offline_sync': isOffline,
    };
  }

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'],
      qrToken: json['qr_token'] ?? '',
      memberName: json['member_name'],
      regNumber: json['registration_number'],
      groupName: json['group_name'],
      recordType: json['record_type'] ?? 'masuk',
      status: json['status'] ?? 'hadir',
      recordedAt: DateTime.tryParse(json['recorded_at'] ?? '') ?? DateTime.now(),
      isOffline: json['is_offline_sync'] ?? false,
    );
  }
}
