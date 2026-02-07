import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/meeting_log.dart';
import '../models/partner.dart';
import '../models/meeting_schedule.dart';
import '../repositories/meeting_log_repository.dart';
import '../repositories/meeting_schedule_repository.dart';
import '../repositories/partner_repository.dart';
import '../repositories/storage_repository.dart';

/// 미팅 리포트 타임라인 (기록 탭)
class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final MeetingLogRepository _logRepository = MeetingLogRepository();
  final PartnerRepository _partnerRepository = PartnerRepository();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddLogDialog({MeetingLog? log}) async {
    final partners = await _partnerRepository.getAllPartners();
    if (partners.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('먼저 파트너를 등록해주세요'),
          backgroundColor: LogBTheme.slate500,
        ),
      );
      return;
    }

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddLogDialog(log: log, partners: partners),
    );

    if (result != null && mounted) {
      try {
        final MeetingLog meetingLog = result['log'];
        final MeetingSchedule? nextSchedule = result['nextSchedule'];

        String? nextMeetingId;
        if (nextSchedule != null) {
          nextMeetingId = await MeetingScheduleRepository().addSchedule(
            nextSchedule,
          );
        }

        if (log == null) {
          final logWithNext = meetingLog.copyWith(nextMeetingId: nextMeetingId);
          await _logRepository.addLog(logWithNext);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('기록과 다음 일정이 저장되었습니다'),
                backgroundColor: LogBTheme.emerald600,
              ),
            );
          }
        } else {
          // 기존 로그 수정 시에도 다음 일정이 새로 추가되었다면 ID 반영
          final updatedLog = nextMeetingId != null
              ? meetingLog.copyWith(nextMeetingId: nextMeetingId)
              : meetingLog;
          await _logRepository.updateLog(updatedLog);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('기록이 수정되었습니다'),
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

  Future<void> _deleteLog(MeetingLog log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? LogBTheme.slate900
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '기록 삭제',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: 'Pretendard',
          ),
        ),
        content: const Text(
          '이 미팅 기록을 삭제하시겠습니까? (첨부파일은 수동으로 관리해야 합니다)',
          style: TextStyle(fontFamily: 'Pretendard'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '취소',
              style: TextStyle(color: LogBTheme.slate500),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              '삭제',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _logRepository.deleteLog(log.id);
    }
  }

  Future<void> _showAttachmentsDialog(MeetingLog log) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? LogBTheme.slate900 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '첨부파일 확인',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: 'Pretendard',
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (log.imageUrls.isNotEmpty) ...[
                  const ListTile(
                    title: Text(
                      '이미지',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...log.imageUrls.asMap().entries.map(
                    (entry) => ListTile(
                      leading: const Icon(
                        Icons.image,
                        color: LogBTheme.emerald600,
                      ),
                      title: Text('이미지 ${entry.key + 1}'),
                      onTap: () => launchUrl(Uri.parse(entry.value)),
                    ),
                  ),
                ],
                if (log.fileUrls.isNotEmpty) ...[
                  const ListTile(
                    title: Text(
                      '파일',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...log.fileUrls.asMap().entries.map(
                    (entry) => ListTile(
                      leading: const Icon(
                        Icons.insert_drive_file,
                        color: LogBTheme.emerald600,
                      ),
                      title: Text('파일 ${entry.key + 1}'),
                      onTap: () => launchUrl(Uri.parse(entry.value)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
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
              IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: LogBTheme.emerald600,
                  size: 30,
                ),
                onPressed: () => _showAddLogDialog(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildSearchBar(isDark),
            ),
          ),
          StreamBuilder<List<MeetingLog>>(
            stream: _searchQuery.isEmpty
                ? _logRepository.getLogsStream()
                : _logRepository.searchLogs(_searchQuery),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final logs = snapshot.data ?? [];
              if (logs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      '기록이 없습니다',
                      style: TextStyle(color: LogBTheme.slate500),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildLogCard(logs[index], isDark),
                    childCount: logs.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          icon: Icon(
            Icons.search,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
          hintText: '파트너명, 제목, 내용 검색...',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildLogCard(MeetingLog log, bool isDark) {
    final dateStr = DateFormat('yyyy.MM.dd').format(log.date);

    return GestureDetector(
      onTap: () => _showAddLogDialog(log: log),
      onLongPress: () => _deleteLog(log),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isDark ? LogBTheme.slate900 : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: LogBTheme.emerald50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: LogBTheme.emerald600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (log.imageUrls.isNotEmpty || log.fileUrls.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showAttachmentsDialog(log),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: LogBTheme.emerald600,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: LogBTheme.emerald600.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.attach_file,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${log.imageUrls.length + log.fileUrls.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.partnerName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: LogBTheme.emerald600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : LogBTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    log.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.white70 : LogBTheme.slate500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 미팅 기록 추가/수정 다이얼로그
class AddLogDialog extends StatefulWidget {
  final MeetingLog? log;
  final List<Partner> partners;

  const AddLogDialog({super.key, this.log, required this.partners});

  @override
  State<AddLogDialog> createState() => _AddLogDialogState();
}

class _AddLogDialogState extends State<AddLogDialog> {
  final _formKey = GlobalKey<FormState>();
  final StorageRepository _storageRepository = StorageRepository();

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _keywordsController;
  late DateTime _selectedDate;

  // 파트너 검색 관련
  Partner? _selectedPartner;
  late TextEditingController _partnerSearchController;
  List<Partner> _filteredPartners = [];
  bool _showPartnerList = false;

  // 다음 일정 관련
  bool _addNextMeeting = false;
  late TextEditingController _nextTitleController;
  late DateTime _nextDate;
  late TimeOfDay _nextStartTime;
  late TimeOfDay _nextEndTime;

  // 파일 업로드 관련
  List<String> _imageUrls = [];
  List<String> _fileUrls = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _contentController = TextEditingController(text: widget.log?.content ?? '');
    _keywordsController = TextEditingController(
      text: widget.log?.keywords.join(', ') ?? '',
    );
    _selectedDate = widget.log?.date ?? DateTime.now();
    _imageUrls = List.from(widget.log?.imageUrls ?? []);
    _fileUrls = List.from(widget.log?.fileUrls ?? []);

    _partnerSearchController = TextEditingController(
      text: widget.log != null
          ? '${widget.log!.partnerName} (${widget.log!.partnerCompany})'
          : '',
    );
    if (widget.log != null) {
      _selectedPartner = widget.partners.firstWhere(
        (p) => p.id == widget.log!.partnerId,
        orElse: () => widget.partners.first,
      );
    }
    _filteredPartners = widget.partners;

    // 다음 일정 초기화 - 기존 로그에 다음 미팅 ID가 있으면 활성화된 것처럼 보여줌 (다만 실제 상세 조회는 파라미터 필요)
    _addNextMeeting = widget.log?.nextMeetingId != null;
    _nextTitleController = TextEditingController();
    _nextDate = DateTime.now().add(const Duration(days: 7));
    _nextStartTime = const TimeOfDay(hour: 14, minute: 0);
    _nextEndTime = const TimeOfDay(hour: 15, minute: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _keywordsController.dispose();
    _partnerSearchController.dispose();
    _nextTitleController.dispose();
    super.dispose();
  }

  void _filterPartners(String query) {
    setState(() {
      _filteredPartners = widget.partners
          .where((p) => p.name.contains(query) || p.company.contains(query))
          .toList();
      _showPartnerList = true;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final url = await _storageRepository.uploadFile(
          File(image.path),
          'images',
        );
        setState(() => _imageUrls.add(url));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => _isUploading = true);
      try {
        final url = await _storageRepository.uploadFile(
          File(result.files.single.path!),
          'files',
        );
        setState(() => _fileUrls.add(url));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPartner == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('파트너를 선택해주세요')));
        return;
      }

      final logResult = MeetingLog(
        id: widget.log?.id ?? '',
        partnerId: _selectedPartner!.id,
        partnerName: _selectedPartner!.name,
        partnerCompany: _selectedPartner!.company,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        date: _selectedDate,
        keywords: _keywordsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        imageUrls: _imageUrls,
        fileUrls: _fileUrls,
        createdAt: widget.log?.createdAt ?? DateTime.now(),
      );

      MeetingSchedule? nextSchedule;
      if (_addNextMeeting) {
        nextSchedule = MeetingSchedule(
          id: '',
          partnerId: _selectedPartner!.id,
          partnerName: _selectedPartner!.name,
          title: _nextTitleController.text.isEmpty
              ? '${_selectedPartner!.name} 미팅'
              : _nextTitleController.text,
          startTime: DateTime(
            _nextDate.year,
            _nextDate.month,
            _nextDate.day,
            _nextStartTime.hour,
            _nextStartTime.minute,
          ),
          endTime: DateTime(
            _nextDate.year,
            _nextDate.month,
            _nextDate.day,
            _nextEndTime.hour,
            _nextEndTime.minute,
          ),
          createdAt: DateTime.now(),
        );
      }

      Navigator.pop(context, {'log': logResult, 'nextSchedule': nextSchedule});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? LogBTheme.slate900 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 900),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.log == null ? '새로운 미팅 기록' : '기록 수정',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : LogBTheme.slate900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Partner Search
                      _buildSectionLabel('미팅 파트너 검색', isDark),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          TextField(
                            controller: _partnerSearchController,
                            onChanged: _filterPartners,
                            onTap: () =>
                                setState(() => _showPartnerList = true),
                            decoration: InputDecoration(
                              hintText: '이름 또는 회사명 입력...',
                              prefixIcon: const Icon(
                                Icons.person_search,
                                color: LogBTheme.emerald600,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : LogBTheme.bgLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          if (_showPartnerList && _filteredPartners.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 60),
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? LogBTheme.slate950
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _filteredPartners.length,
                                itemBuilder: (context, index) {
                                  final p = _filteredPartners[index];
                                  return ListTile(
                                    title: Text(
                                      p.name,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : LogBTheme.slate900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      p.company,
                                      style: const TextStyle(
                                        color: LogBTheme.slate500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedPartner = p;
                                        _partnerSearchController.text =
                                            '${p.name} (${p.company})';
                                        _showPartnerList = false;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Meeting Date
                      _buildSectionLabel('미팅 날짜', isDark),
                      const SizedBox(height: 8),
                      _buildPickerButton(
                        Icons.calendar_today,
                        DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
                        () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setState(() => _selectedDate = d);
                        },
                        isDark,
                      ),
                      const SizedBox(height: 24),

                      // Basic Info
                      _buildTextField(
                        controller: _titleController,
                        label: '제목',
                        hint: '미팅 주제',
                        icon: Icons.title,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _contentController,
                        label: '상세 내용',
                        hint: '대화 내용...',
                        icon: Icons.notes,
                        isDark: isDark,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 24),

                      // Attachments
                      _buildSectionLabel('첨부파일 및 사진', isDark),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildAttachButton(
                            Icons.add_a_photo,
                            '사진 추가',
                            _pickImage,
                            isDark,
                          ),
                          const SizedBox(width: 12),
                          _buildAttachButton(
                            Icons.attach_file,
                            '파일 추가',
                            _pickFile,
                            isDark,
                          ),
                        ],
                      ),
                      if (_isUploading)
                        const LinearProgressIndicator(
                          color: LogBTheme.emerald600,
                        ),
                      const SizedBox(height: 12),
                      _buildAttachmentList(isDark),
                      const SizedBox(height: 24),

                      // Next Meeting
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: LogBTheme.emerald600.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: LogBTheme.emerald600.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.event_available,
                                  color: LogBTheme.emerald600,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '다음 일정 예약',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: LogBTheme.emerald600,
                                  ),
                                ),
                                const Spacer(),
                                Switch(
                                  value: _addNextMeeting,
                                  onChanged: (v) =>
                                      setState(() => _addNextMeeting = v),
                                  activeColor: LogBTheme.emerald600,
                                ),
                              ],
                            ),
                            if (_addNextMeeting) ...[
                              const Divider(),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _nextTitleController,
                                label: '일정 제목 (공란 시 자동생성)',
                                hint: '다음 미팅 주제',
                                icon: Icons.edit_calendar,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildPickerButton(
                                      Icons.calendar_today,
                                      DateFormat('MM/dd').format(_nextDate),
                                      () async {
                                        final d = await showDatePicker(
                                          context: context,
                                          initialDate: _nextDate,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime(2030),
                                        );
                                        if (d != null)
                                          setState(() => _nextDate = d);
                                      },
                                      isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildPickerButton(
                                      Icons.access_time,
                                      _nextStartTime.format(context),
                                      () async {
                                        final t = await showTimePicker(
                                          context: context,
                                          initialTime: _nextStartTime,
                                        );
                                        if (t != null)
                                          setState(() {
                                            _nextStartTime = t;
                                            _nextEndTime = TimeOfDay(
                                              hour: (t.hour + 1) % 24,
                                              minute: t.minute,
                                            );
                                          });
                                      },
                                      isDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LogBTheme.emerald600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '저장하기',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white60 : LogBTheme.slate500,
      ),
    );
  }

  Widget _buildAttachButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: LogBTheme.emerald600),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: LogBTheme.emerald600),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: LogBTheme.emerald600,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentList(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._imageUrls.map((url) => _buildAttachmentItem(url, true, isDark)),
        ..._fileUrls.map((url) => _buildAttachmentItem(url, false, isDark)),
      ],
    );
  }

  Widget _buildAttachmentItem(String url, bool isImage, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : LogBTheme.bgLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isImage ? Icons.image : Icons.insert_drive_file,
            size: 14,
            color: LogBTheme.slate500,
          ),
          const SizedBox(width: 6),
          const Text('첨부됨', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() {
              if (isImage)
                _imageUrls.remove(url);
              else
                _fileUrls.remove(url);
            }),
            child: const Icon(Icons.close, size: 14, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerButton(
    IconData icon,
    String text,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: LogBTheme.emerald600),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label, isDark),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: LogBTheme.emerald600, size: 20),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : LogBTheme.bgLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white12
                    : Colors.grey.withValues(alpha: 0.1),
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
