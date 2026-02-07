import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meeting_log.dart';

class MeetingLogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _logsCollection {
    if (_userId == null) throw Exception('User not logged in');
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('meeting_logs');
  }

  /// 모든 미팅 로그 가져오기 (스트림)
  Stream<List<MeetingLog>> getLogsStream({
    String sortBy = 'date',
    bool descending = true,
  }) {
    return _logsCollection
        .orderBy(sortBy, descending: descending)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MeetingLog.fromFirestore(doc))
              .toList();
        });
  }

  /// 특정 파트너의 미팅 로그 가져오기 (스트림)
  Stream<List<MeetingLog>> getPartnerLogsStream(String partnerId) {
    return _logsCollection
        .where('partnerId', isEqualTo: partnerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MeetingLog.fromFirestore(doc))
              .toList();
        });
  }

  /// 검색어로 미팅 로그 검색
  Stream<List<MeetingLog>> searchLogs(String query) {
    // 주의: Firestore는 클라이언트 측 검색에 한계가 있어, 여기선 파트너 이름이나 제목으로 필터링하는 방식
    // 실제 운영 시에는 Algolia 같은 서비스를 사용하거나 서비스 로직에서 필터링 권장
    return _logsCollection.orderBy('date', descending: true).snapshots().map((
      snapshot,
    ) {
      final allLogs = snapshot.docs
          .map((doc) => MeetingLog.fromFirestore(doc))
          .toList();
      if (query.isEmpty) return allLogs;

      final lowerQuery = query.toLowerCase();
      return allLogs.where((log) {
        return log.partnerName.toLowerCase().contains(lowerQuery) ||
            log.title.toLowerCase().contains(lowerQuery) ||
            log.content.toLowerCase().contains(lowerQuery) ||
            log.keywords.any((k) => k.toLowerCase().contains(lowerQuery));
      }).toList();
    });
  }

  /// 미팅 로그 추가
  Future<String> addLog(MeetingLog log) async {
    final docRef = await _logsCollection.add(log.toFirestore());
    return docRef.id;
  }

  /// 미팅 로그 수정
  Future<void> updateLog(MeetingLog log) async {
    await _logsCollection.doc(log.id).update(log.toFirestore());
  }

  /// 미팅 로그 삭제
  Future<void> deleteLog(String logId) async {
    await _logsCollection.doc(logId).delete();
  }

  /// 모든 로그 가져오기 (Future)
  Future<List<MeetingLog>> getAllLogs() async {
    final snapshot = await _logsCollection
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => MeetingLog.fromFirestore(doc)).toList();
  }
}
