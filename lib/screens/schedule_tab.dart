import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '../main.dart';
import '../models/meeting_schedule.dart';
import '../models/meeting_log.dart';
import '../models/partner.dart';
import '../repositories/meeting_schedule_repository.dart';
import '../repositories/meeting_log_repository.dart';
import '../repositories/partner_repository.dart';

/// 통합 미팅 이벤트 모델 (일정 + 기록)
class MeetingEvent {
  final String id;
  final String title;
  final String partnerName;
  final DateTime date;
  final bool isLog; // true: 기록(MeetingLog), false: 일정(MeetingSchedule)
  final String? location;
  final String? timeText;
  final dynamic originalObject;

  MeetingEvent({
    required this.id,
    required this.title,
    required this.partnerName,
    required this.date,
    required this.isLog,
    this.location,
    this.timeText,
    required this.originalObject,
  });
}

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  final MeetingScheduleRepository _scheduleRepository =
      MeetingScheduleRepository();
  final MeetingLogRepository _logRepository = MeetingLogRepository();
  final PartnerRepository _partnerRepository = PartnerRepository();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<MeetingEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<MeetingEvent> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  Future<void> _showAddScheduleDialog({MeetingSchedule? schedule}) async {
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

    final result = await showDialog<MeetingSchedule>(
      context: context,
      builder: (context) => _AddScheduleDialog(
        schedule: schedule,
        partners: partners,
        initialDate: _selectedDay ?? DateTime.now(),
      ),
    );

    if (result != null && mounted) {
      try {
        if (schedule == null) {
          await _scheduleRepository.addSchedule(result);
        } else {
          await _scheduleRepository.updateSchedule(result);
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

  Future<void> _deleteEvent(MeetingEvent event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? LogBTheme.slate900
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          event.isLog ? '기록 삭제' : '일정 삭제',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: 'Pretendard',
          ),
        ),
        content: Text(
          event.isLog ? '이 미팅 기록을 삭제하시겠습니까?' : '이 일정을 삭제하시겠습니까?',
          style: const TextStyle(fontFamily: 'Pretendard'),
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
      if (event.isLog) {
        await _logRepository.deleteLog(event.id);
      } else {
        await _scheduleRepository.deleteSchedule(event.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? LogBTheme.slate950 : LogBTheme.bgLight,
      body: StreamBuilder<List<MeetingEvent>>(
        stream: CombineLatestStream.combine2(
          _scheduleRepository.getSchedulesStream(),
          _logRepository.getLogsStream(),
          (List<MeetingSchedule> schedules, List<MeetingLog> logs) {
            final List<MeetingEvent> events = [];

            // 일정 추가
            for (var s in schedules) {
              events.add(
                MeetingEvent(
                  id: s.id,
                  title: s.title,
                  partnerName: s.partnerName,
                  date: s.startTime,
                  isLog: false,
                  location: s.location,
                  timeText:
                      '${DateFormat('HH:mm').format(s.startTime)} - ${DateFormat('HH:mm').format(s.endTime)}',
                  originalObject: s,
                ),
              );
            }

            // 기록 추가
            for (var l in logs) {
              events.add(
                MeetingEvent(
                  id: l.id,
                  title: l.title,
                  partnerName: l.partnerName,
                  date: l.date,
                  isLog: true,
                  timeText: '완료된 미팅',
                  originalObject: l,
                ),
              );
            }

            // 날짜순 정렬
            events.sort((a, b) => a.date.compareTo(b.date));
            return events;
          },
        ),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final List<MeetingEvent> allEvents = snapshot.data!;
            _events = {};
            for (var event in allEvents) {
              final date = DateTime(
                event.date.year,
                event.date.month,
                event.date.day,
              );
              if (_events[date] == null) _events[date] = [];
              _events[date]!.add(event);
            }
          }

          final selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: isDark
                    ? LogBTheme.slate950
                    : LogBTheme.bgLight,
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
                    onPressed: () => _showAddScheduleDialog(),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? LogBTheme.slate900 : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() => _calendarFormat = format);
                    },
                    eventLoader: _getEventsForDay,
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: LogBTheme.emerald600.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: LogBTheme.emerald600,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: LogBTheme.emerald600,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(
                        color: LogBTheme.emerald600,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      weekendTextStyle: const TextStyle(
                        color: Colors.redAccent,
                      ),
                      defaultTextStyle: TextStyle(
                        color: isDark ? Colors.white : LogBTheme.slate900,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonDecoration: BoxDecoration(
                        color: LogBTheme.emerald50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      formatButtonTextStyle: const TextStyle(
                        color: LogBTheme.emerald600,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      titleTextStyle: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : LogBTheme.slate900,
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  child: Text(
                    'EVENTS FOR ${DateFormat('MMMM d').format(_selectedDay ?? _focusedDay).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: LogBTheme.slate500,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              if (selectedEvents.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 64,
                          color: isDark ? Colors.white24 : LogBTheme.slate500,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '일정이나 기록이 없습니다',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            color: isDark ? Colors.white54 : LogBTheme.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final event = selectedEvents[index];
                      return _buildEventCard(event, isDark);
                    }, childCount: selectedEvents.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
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

  Widget _buildEventCard(MeetingEvent event, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (!event.isLog) {
          _showAddScheduleDialog(
            schedule: event.originalObject as MeetingSchedule,
          );
        }
        // 기록(Log)의 경우 상세 화면이나 수정 다이얼로그로 연결 가능 (현재는 삭제만 지원)
      },
      onLongPress: () => _deleteEvent(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? LogBTheme.slate900 : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: event.isLog
                ? LogBTheme.emerald600.withValues(alpha: 0.3)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.05)),
            width: event.isLog ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: event.isLog
                      ? LogBTheme.emerald600.withValues(alpha: 0.1)
                      : LogBTheme.emerald50.withValues(
                          alpha: isDark ? 0.05 : 1,
                        ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!event.isLog) ...[
                      Text(
                        DateFormat('HH:mm').format(event.date),
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: LogBTheme.emerald600,
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.check_circle,
                        color: LogBTheme.emerald600,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'LOG',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: LogBTheme.emerald600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            event.partnerName,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: LogBTheme.emerald600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (event.isLog)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: LogBTheme.emerald600,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '기록됨',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.title,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : LogBTheme.slate900,
                        ),
                      ),
                      if (event.location != null &&
                          event.location!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: LogBTheme.slate500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location!,
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 13,
                                  color: LogBTheme.slate500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (event.isLog) ...[
                        const SizedBox(height: 4),
                        Text(
                          (event.originalObject as MeetingLog).content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 13,
                            color: LogBTheme.slate500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddScheduleDialog extends StatefulWidget {
  final MeetingSchedule? schedule;
  final List<Partner> partners;
  final DateTime initialDate;

  const _AddScheduleDialog({
    this.schedule,
    required this.partners,
    required this.initialDate,
  });

  @override
  State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  Partner? _selectedPartner;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.schedule?.title ?? '',
    );
    _locationController = TextEditingController(
      text: widget.schedule?.location ?? '',
    );
    _notesController = TextEditingController(
      text: widget.schedule?.notes ?? '',
    );
    _selectedDate = widget.schedule?.startTime ?? widget.initialDate;

    if (widget.schedule != null) {
      _startTime = TimeOfDay.fromDateTime(widget.schedule!.startTime);
      _endTime = TimeOfDay.fromDateTime(widget.schedule!.endTime);
      _selectedPartner = widget.partners.firstWhere(
        (p) => p.id == widget.schedule!.partnerId,
        orElse: () => widget.partners.first,
      );
    } else {
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay(
        hour: (_startTime.hour + 1) % 24,
        minute: _startTime.minute,
      );
      if (widget.partners.isNotEmpty) {
        _selectedPartner = widget.partners.first;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          _endTime = TimeOfDay(
            hour: (_startTime.hour + 1) % 24,
            minute: _startTime.minute,
          );
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPartner == null) return;

      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final result = MeetingSchedule(
        id: widget.schedule?.id ?? '',
        partnerId: _selectedPartner!.id,
        partnerName: _selectedPartner!.name,
        title: _titleController.text.trim(),
        startTime: startDateTime,
        endTime: endDateTime,
        location: _locationController.text.trim(),
        notes: _notesController.text.trim(),
        createdAt: widget.schedule?.createdAt ?? DateTime.now(),
      );
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? LogBTheme.slate900 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.schedule == null ? '새 일정 추가' : '일정 수정',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : LogBTheme.slate900,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white54 : LogBTheme.slate500,
                    ),
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
                      _buildSectionLabel('미팅 파트너', isDark),
                      const SizedBox(height: 8),
                      _buildPartnerDropdown(isDark),
                      const SizedBox(height: 24),

                      _buildSectionLabel('일시', isDark),
                      const SizedBox(height: 8),
                      _buildDateTimePicker(isDark),
                      const SizedBox(height: 24),

                      _buildTextField(
                        controller: _titleController,
                        label: '일정 제목',
                        hint: '예: 신규 프로젝트 미팅',
                        icon: Icons.title,
                        isDark: isDark,
                        validator: (v) =>
                            v?.isEmpty ?? true ? '제목을 입력하세요' : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _locationController,
                        label: '장소',
                        hint: '미팅 장소 또는 링크',
                        icon: Icons.location_on,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _notesController,
                        label: '메모',
                        hint: '준비물 등을 적어주세요',
                        icon: Icons.notes,
                        isDark: isDark,
                        maxLines: 3,
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
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : LogBTheme.slate500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LogBTheme.emerald600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.schedule == null ? '저장하기' : '수정하기',
                      style: const TextStyle(fontWeight: FontWeight.w800),
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
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildPartnerDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : LogBTheme.bgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Partner>(
          value: _selectedPartner,
          isExpanded: true,
          dropdownColor: isDark ? LogBTheme.slate900 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          items: widget.partners
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text(
                    '${p.name} (${p.company})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : LogBTheme.slate900,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedPartner = v),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(bool isDark) {
    return Column(
      children: [
        InkWell(
          onTap: _pickDate,
          child: _buildPickerBox(
            Icons.calendar_today,
            DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
            isDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickTime(true),
                child: _buildPickerBox(
                  Icons.access_time,
                  _startTime.format(context),
                  isDark,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('~'),
            ),
            Expanded(
              child: InkWell(
                onTap: () => _pickTime(false),
                child: _buildPickerBox(
                  Icons.access_time,
                  _endTime.format(context),
                  isDark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPickerBox(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : LogBTheme.bgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: LogBTheme.emerald600),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : LogBTheme.slate900,
            ),
          ),
        ],
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
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : LogBTheme.slate900,
          ),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: LogBTheme.emerald600,
                width: 2,
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
