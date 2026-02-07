import 'package:cloud_firestore/cloud_firestore.dart';

/// 파트너(거래처) 데이터 모델
class Partner {
  final String id;
  final String name;
  final String company;
  final String position;
  final String email;
  final String phone;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Partner({
    required this.id,
    required this.name,
    required this.company,
    required this.position,
    this.email = '',
    this.phone = '',
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
  });

  /// Firestore 문서에서 Partner 객체 생성
  factory Partner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Partner(
      id: doc.id,
      name: data['name'] ?? '',
      company: data['company'] ?? '',
      position: data['position'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Partner 객체를 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'company': company,
      'position': position,
      'email': email,
      'phone': phone,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// CSV 행으로 변환
  List<String> toCsvRow() {
    return [name, company, position, email, phone, tags.join(';')];
  }

  /// CSV 행에서 Partner 객체 생성
  factory Partner.fromCsvRow(List<dynamic> row) {
    return Partner(
      id: '', // Firestore에서 자동 생성됨
      name: row.length > 0 ? row[0].toString() : '',
      company: row.length > 1 ? row[1].toString() : '',
      position: row.length > 2 ? row[2].toString() : '',
      email: row.length > 3 ? row[3].toString() : '',
      phone: row.length > 4 ? row[4].toString() : '',
      tags: row.length > 5 && row[5].toString().isNotEmpty
          ? row[5].toString().split(';')
          : [],
      createdAt: DateTime.now(),
    );
  }

  /// CSV 헤더
  static List<String> csvHeaders() {
    return ['이름', '회사', '직책', '이메일', '전화번호', '태그'];
  }

  /// 복사본 생성
  Partner copyWith({
    String? id,
    String? name,
    String? company,
    String? position,
    String? email,
    String? phone,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Partner(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      position: position ?? this.position,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
