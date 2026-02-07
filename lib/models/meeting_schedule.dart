import 'package:cloud_firestore/cloud_firestore.dart';

/// 미팅 일정 데이터 모델
class MeetingSchedule {
  final String id;
  final String partnerId;
  final String partnerName;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String notes;
  final DateTime createdAt;

  MeetingSchedule({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.notes = '',
    required this.createdAt,
  });

  /// Firestore 문서에서 MeetingSchedule 객체 생성
  factory MeetingSchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeetingSchedule(
      id: doc.id,
      partnerId: data['partnerId'] ?? '',
      partnerName: data['partnerName'] ?? '',
      title: data['title'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// MeetingSchedule 객체를 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'partnerId': partnerId,
      'partnerName': partnerName,
      'title': title,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// 복사본 생성
  MeetingSchedule copyWith({
    String? id,
    String? partnerId,
    String? partnerName,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? notes,
    DateTime? createdAt,
  }) {
    return MeetingSchedule(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
