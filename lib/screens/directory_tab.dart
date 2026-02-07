import 'package:flutter/material.dart';
import '../main.dart';
import '../models/partner.dart';
import '../repositories/partner_repository.dart';
import '../services/csv_service.dart';
import 'add_partner_dialog.dart';

/// 인맥(파트너) 관리 탭
class DirectoryTab extends StatefulWidget {
  const DirectoryTab({super.key});

  @override
  State<DirectoryTab> createState() => _DirectoryTabState();
}

class _DirectoryTabState extends State<DirectoryTab> {
  final PartnerRepository _repository = PartnerRepository();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _sortBy = 'createdAt';
  bool _descending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddPartnerDialog({Partner? partner}) async {
    final result = await showDialog<Partner>(
      context: context,
      builder: (context) => AddPartnerDialog(partner: partner),
    );

    if (result != null && mounted) {
      try {
        if (partner == null) {
          // 새로 추가
          await _repository.addPartner(result);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('파트너가 추가되었습니다'),
                backgroundColor: LogBTheme.emerald600,
              ),
            );
          }
        } else {
          // 수정
          await _repository.updatePartner(result);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('파트너가 수정되었습니다'),
                backgroundColor: LogBTheme.emerald600,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _exportToCsv() async {
    try {
      final partners = await _repository.getAllPartners();
      if (partners.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('내보낼 파트너가 없습니다'),
              backgroundColor: LogBTheme.slate500,
            ),
          );
        }
        return;
      }

      final filePath = await CsvService.exportPartnersToCsv(partners);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV 파일이 저장되었습니다\n$filePath'),
            backgroundColor: LogBTheme.emerald600,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV 내보내기 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importFromCsv() async {
    try {
      final partners = await CsvService.importPartnersFromCsv();
      if (partners.isEmpty) {
        return;
      }

      await _repository.addPartnersBatch(partners);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${partners.length}개의 파트너를 가져왔습니다'),
            backgroundColor: LogBTheme.emerald600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV 가져오기 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePartner(Partner partner) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('파트너 삭제'),
        content: Text('${partner.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _repository.deletePartner(partner.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('파트너가 삭제되었습니다'),
              backgroundColor: LogBTheme.emerald600,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 실패: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('최신순'),
              trailing: _sortBy == 'createdAt' && _descending
                  ? const Icon(Icons.check, color: LogBTheme.emerald600)
                  : null,
              onTap: () {
                setState(() {
                  _sortBy = 'createdAt';
                  _descending = true;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('오래된순'),
              trailing: _sortBy == 'createdAt' && !_descending
                  ? const Icon(Icons.check, color: LogBTheme.emerald600)
                  : null,
              onTap: () {
                setState(() {
                  _sortBy = 'createdAt';
                  _descending = false;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('이름순 (ㄱ-ㅎ)'),
              trailing: _sortBy == 'name' && !_descending
                  ? const Icon(Icons.check, color: LogBTheme.emerald600)
                  : null,
              onTap: () {
                setState(() {
                  _sortBy = 'name';
                  _descending = false;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('회사명순 (ㄱ-ㅎ)'),
              trailing: _sortBy == 'company' && !_descending
                  ? const Icon(Icons.check, color: LogBTheme.emerald600)
                  : null,
              onTap: () {
                setState(() {
                  _sortBy = 'company';
                  _descending = false;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? LogBTheme.slate950 : LogBTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          // 앱바 - 로고와 아이콘들을 같은 줄에 배치
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: isDark ? LogBTheme.slate950 : LogBTheme.bgLight,
            elevation: 0,
            title: Row(
              children: [
                _buildLogo(32),
                const SizedBox(width: 10),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      fontFamily: 'Pretendard',
                      color: isDark ? Colors.white : LogBTheme.slate900,
                    ),
                    children: const [
                      TextSpan(text: 'Log'),
                      TextSpan(
                        text: ',',
                        style: TextStyle(
                          color: LogBTheme.emerald600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(text: 'B'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // 업로드 버튼
              IconButton(
                icon: const Icon(
                  Icons.upload_file,
                  color: LogBTheme.emerald600,
                ),
                onPressed: _importFromCsv,
                tooltip: 'CSV 가져오기',
              ),
              // 다운로드 버튼
              IconButton(
                icon: const Icon(Icons.download, color: LogBTheme.emerald600),
                onPressed: _exportToCsv,
                tooltip: 'CSV 다운로드',
              ),
              // 플러스 버튼
              IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: LogBTheme.emerald600,
                  size: 30,
                ),
                onPressed: () => _showAddPartnerDialog(),
                tooltip: '파트너 추가',
              ),
              const SizedBox(width: 8),
            ],
          ),

          // 검색바와 필터
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildSearchBar(isDark)),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.filter_list,
                          color: LogBTheme.emerald600,
                        ),
                        onPressed: _showSortOptions,
                        tooltip: '정렬',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 파트너 목록
          StreamBuilder<List<Partner>>(
            stream: _searchQuery.isEmpty
                ? _repository.getPartnersStream(
                    sortBy: _sortBy,
                    descending: _descending,
                  )
                : _repository.searchPartners(_searchQuery),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('오류: ${snapshot.error}')),
                );
              }

              final partners = snapshot.data ?? [];

              if (partners.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: isDark ? Colors.white24 : LogBTheme.slate500,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? '파트너를 추가해주세요' : '검색 결과가 없습니다',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            color: isDark ? Colors.white54 : LogBTheme.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PARTNERS (${partners.length})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: LogBTheme.slate500,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildPartnerCard(partners[0], isDark),
                        ],
                      );
                    }
                    return _buildPartnerCard(partners[index], isDark);
                  }, childCount: partners.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        'assets/images/LogB_Green_Icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? LogBTheme.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          icon: Icon(
            Icons.search,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
          hintText: '거래처 검색...',
          border: InputBorder.none,
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white38 : null,
          ),
        ),
        style: TextStyle(
          fontFamily: 'Pretendard',
          color: isDark ? Colors.white : LogBTheme.slate900,
        ),
      ),
    );
  }

  Widget _buildPartnerCard(Partner partner, bool isDark) {
    return GestureDetector(
      onTap: () => _showAddPartnerDialog(partner: partner),
      onLongPress: () => _deletePartner(partner),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? LogBTheme.slate900 : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: LogBTheme.emerald50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, color: LogBTheme.emerald600),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner.name,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: isDark ? Colors.white : LogBTheme.slate900,
                        ),
                      ),
                      Text(
                        '${partner.company}${partner.position.isNotEmpty ? ' · ${partner.position}' : ''}',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          color: LogBTheme.slate500,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (partner.email.isNotEmpty || partner.phone.isNotEmpty)
                        Text(
                          [
                            partner.email,
                            partner.phone,
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            color: LogBTheme.slate500,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            if (partner.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: partner.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: LogBTheme.emerald50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: LogBTheme.emerald600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
