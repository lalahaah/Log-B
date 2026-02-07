import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meeting_schedule.dart';

class MeetingScheduleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _schedulesCollection {
    if (_userId == null) throw Exception('User not logged in');
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('meeting_schedules');
  }

  /// 모든 일정 가져오기 (스트림)
  Stream<List<MeetingSchedule>> getSchedulesStream() {
    return _schedulesCollection
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MeetingSchedule.fromFirestore(doc))
              .toList();
        });
  }

  /// 특정 범위의 일정 가져오기 (예: 한 달)
  Future<List<MeetingSchedule>> getSchedulesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _schedulesCollection
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snapshot.docs
        .map((doc) => MeetingSchedule.fromFirestore(doc))
        .toList();
  }

  /// 일정 추가
  Future<String> addSchedule(MeetingSchedule schedule) async {
    final docRef = await _schedulesCollection.add(schedule.toFirestore());
    return docRef.id;
  }

  /// 일정 수정
  Future<void> updateSchedule(MeetingSchedule schedule) async {
    await _schedulesCollection.doc(schedule.id).update(schedule.toFirestore());
  }

  /// 일정 삭제
  Future<void> deleteSchedule(String scheduleId) async {
    await _schedulesCollection.doc(scheduleId).delete();
  }
}
