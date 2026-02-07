import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/partner.dart';

/// 파트너 데이터 관리 저장소
class PartnerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 현재 사용자의 파트너 컬렉션 참조
  CollectionReference<Map<String, dynamic>> _partnersCollection() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('사용자가 로그인되어 있지 않습니다.');
    }
    return _firestore.collection('users').doc(userId).collection('partners');
  }

  /// 파트너 추가
  Future<String> addPartner(Partner partner) async {
    try {
      final docRef = await _partnersCollection().add(partner.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('파트너 추가 실패: $e');
    }
  }

  /// 파트너 수정
  Future<void> updatePartner(Partner partner) async {
    try {
      await _partnersCollection()
          .doc(partner.id)
          .update(partner.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      throw Exception('파트너 수정 실패: $e');
    }
  }

  /// 파트너 삭제
  Future<void> deletePartner(String partnerId) async {
    try {
      await _partnersCollection().doc(partnerId).delete();
    } catch (e) {
      throw Exception('파트너 삭제 실패: $e');
    }
  }

  /// 파트너 목록 스트림 (최신순)
  Stream<List<Partner>> getPartnersStream({
    String? sortBy = 'createdAt',
    bool descending = true,
  }) {
    try {
      return _partnersCollection()
          .orderBy(sortBy ?? 'createdAt', descending: descending)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => Partner.fromFirestore(doc)).toList(),
          );
    } catch (e) {
      throw Exception('파트너 목록 가져오기 실패: $e');
    }
  }

  /// 태그로 필터링된 파트너 목록
  Stream<List<Partner>> getPartnersByTag(String tag) {
    try {
      return _partnersCollection()
          .where('tags', arrayContains: tag)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => Partner.fromFirestore(doc)).toList(),
          );
    } catch (e) {
      throw Exception('태그별 파트너 검색 실패: $e');
    }
  }

  /// 검색어로 파트너 검색 (이름, 회사)
  Stream<List<Partner>> searchPartners(String query) {
    if (query.isEmpty) {
      return getPartnersStream();
    }

    try {
      return _partnersCollection()
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            final partners = snapshot.docs
                .map((doc) => Partner.fromFirestore(doc))
                .toList();
            return partners.where((partner) {
              final lowerQuery = query.toLowerCase();
              return partner.name.toLowerCase().contains(lowerQuery) ||
                  partner.company.toLowerCase().contains(lowerQuery) ||
                  partner.position.toLowerCase().contains(lowerQuery);
            }).toList();
          });
    } catch (e) {
      throw Exception('파트너 검색 실패: $e');
    }
  }

  /// 여러 파트너 일괄 추가 (CSV 업로드용)
  Future<void> addPartnersBatch(List<Partner> partners) async {
    try {
      final batch = _firestore.batch();
      for (final partner in partners) {
        final docRef = _partnersCollection().doc();
        batch.set(docRef, partner.toFirestore());
      }
      await batch.commit();
    } catch (e) {
      throw Exception('파트너 일괄 추가 실패: $e');
    }
  }

  /// 모든 파트너 가져오기 (CSV 다운로드용)
  Future<List<Partner>> getAllPartners() async {
    try {
      final snapshot = await _partnersCollection()
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => Partner.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('파트너 목록 가져오기 실패: $e');
    }
  }
}
