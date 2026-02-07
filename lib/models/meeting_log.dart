import 'package:cloud_firestore/cloud_firestore.dart';

/// 미팅 기록 데이터 모델
class MeetingLog {
  final String id;
  final String partnerId;
  final String partnerName;
  final String partnerCompany;
  final String title;
  final String content;
  final DateTime date;
  final List<String> keywords;
  final String? aiAnalysis;
  final DateTime createdAt;

  // 새 필드 추가: 첨부파일 및 다음 일정
  final List<String> fileUrls;
  final List<String> imageUrls;
  final String? nextMeetingId;

  MeetingLog({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    required this.partnerCompany,
    required this.title,
    required this.content,
    required this.date,
    required this.keywords,
    this.aiAnalysis,
    required this.createdAt,
    this.fileUrls = const [],
    this.imageUrls = const [],
    this.nextMeetingId,
  });

  /// Firestore 문서에서 MeetingLog 객체 생성
  factory MeetingLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeetingLog(
      id: doc.id,
      partnerId: data['partnerId'] ?? '',
      partnerName: data['partnerName'] ?? '',
      partnerCompany: data['partnerCompany'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      keywords: List<String>.from(data['keywords'] ?? []),
      aiAnalysis: data['aiAnalysis'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      fileUrls: List<String>.from(data['fileUrls'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      nextMeetingId: data['nextMeetingId'],
    );
  }

  /// MeetingLog 객체를 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'partnerId': partnerId,
      'partnerName': partnerName,
      'partnerCompany': partnerCompany,
      'title': title,
      'content': content,
      'date': Timestamp.fromDate(date),
      'keywords': keywords,
      'aiAnalysis': aiAnalysis,
      'createdAt': Timestamp.fromDate(createdAt),
      'fileUrls': fileUrls,
      'imageUrls': imageUrls,
      'nextMeetingId': nextMeetingId,
    };
  }

  /// 복사본 생성 (업데이트 시 유용)
  MeetingLog copyWith({
    String? id,
    String? partnerId,
    String? partnerName,
    String? partnerCompany,
    String? title,
    String? content,
    DateTime? date,
    List<String>? keywords,
    String? aiAnalysis,
    DateTime? createdAt,
    List<String>? fileUrls,
    List<String>? imageUrls,
    String? nextMeetingId,
  }) {
    return MeetingLog(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      partnerCompany: partnerCompany ?? this.partnerCompany,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      keywords: keywords ?? this.keywords,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      createdAt: createdAt ?? this.createdAt,
      fileUrls: fileUrls ?? this.fileUrls,
      imageUrls: imageUrls ?? this.imageUrls,
      nextMeetingId: nextMeetingId ?? this.nextMeetingId,
    );
  }
}
