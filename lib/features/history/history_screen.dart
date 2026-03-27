import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/qt_provider.dart';
import '../../shared/providers/sermon_provider.dart';
import '../../shared/models/qt_entry.dart';
import '../../shared/models/sermon_entry.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants.dart';
import '../sermon/sermon_detail_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DateTime _focusedMonth = DateTime.now();
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      _selectedDay = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final qtList = ref.watch(qtListProvider);
    final sermonList = ref.watch(sermonListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // 해당 월의 QT 날짜 세트
    final qtDays = qtList
        .where(
          (e) =>
              e.date.year == _focusedMonth.year &&
              e.date.month == _focusedMonth.month,
        )
        .map((e) => e.date.day)
        .toSet();

    // 해당 월의 설교 날짜 세트
    final sermonDays = sermonList
        .where(
          (e) =>
              e.date.year == _focusedMonth.year &&
              e.date.month == _focusedMonth.month,
        )
        .map((e) => e.date.day)
        .toSet();

    final selectedEntries = _selectedDay != null
        ? ref.watch(
            qtsByDateProvider(
              DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay!),
            ),
          )
        : <QtEntry>[];

    final selectedDate = _selectedDay != null
        ? DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('기록'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '묵상 기록'),
            Tab(text: '나의 기록'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── 묵상 기록 탭 ──────────────────────────────────────────
          Column(
            children: [
              // 월 선택
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _prevMonth,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      DateFormat('yyyy년 M월').format(_focusedMonth),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),

              // 범례
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _LegendDot(color: colorScheme.primary, label: '묵상'),
                    const SizedBox(width: 12),
                    _LegendDot(color: Colors.indigo, label: '설교'),
                  ],
                ),
              ),

              // 달력 그리드 + 하단 목록 (LayoutBuilder로 가용 높이에 맞게 셀 크기 조정)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 고정 요소: 요일행(~16) + SizedBox(8) + SizedBox(8) + Divider(1) = 33
                    const fixedOverhead = 33.0;
                    const minEntriesHeight = 60.0;
                    final availableForGrid =
                        (constraints.maxHeight - fixedOverhead - minEntriesHeight)
                            .clamp(180.0, double.infinity);
                    // 최대 6주 기준 셀 높이 계산
                    final cellHeight = availableForGrid / 6;
                    final cellWidth = (constraints.maxWidth - 32) / 7;
                    final aspectRatio = (cellWidth / cellHeight).clamp(1.0, 3.0);

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _CalendarGrid(
                            focusedMonth: _focusedMonth,
                            qtDays: qtDays,
                            sermonDays: sermonDays,
                            selectedDay: _selectedDay,
                            onDayTap: (day) =>
                                setState(() => _selectedDay = day),
                            aspectRatio: aspectRatio,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Divider(height: 1, color: colorScheme.dividerColor),
                        Expanded(
                          child: selectedEntries.isNotEmpty
                              ? _QtEntryList(
                                  entries: selectedEntries,
                                  selectedDate: selectedDate,
                                  onEdit: (entry) => context.push(
                                      AppRoutes.qtEdit,
                                      extra: entry),
                                  onDelete: (entry) => _confirmDelete(entry),
                                )
                              : _EmptyDayView(
                                  selectedDate: selectedDate,
                                  hasAnyQt: qtList.isNotEmpty,
                                  onAddQt: selectedDate != null
                                      ? () => context.push(
                                            AppRoutes.qtForm,
                                            extra: selectedDate,
                                          )
                                      : null,
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          // ── 나의 기록 탭 ──────────────────────────────────────────
          _MyRecordsTab(qtList: qtList, sermonList: sermonList),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(QtEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('묵상 삭제'),
        content: Text(
          '"${entry.scriptureTitle}" 묵상을 삭제하면\n달란트 ${entry.talentsEarned}개가 회수됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(qtServiceProvider).deleteEntry(entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('묵상이 삭제되었어요 (-${entry.talentsEarned} 달란트)'),
          ),
        );
      }
    }
  }
}

// ── 범례 점 ──────────────────────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.textSecondary),
        ),
      ],
    );
  }
}

// ── 빈 날짜 뷰 ───────────────────────────────────────────────────────────────
class _EmptyDayView extends StatelessWidget {
  final DateTime? selectedDate;
  final bool hasAnyQt;
  final VoidCallback? onAddQt;

  const _EmptyDayView({
    required this.selectedDate,
    required this.hasAnyQt,
    required this.onAddQt,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (selectedDate == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(hasAnyQt ? '☝️' : '📖', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              hasAnyQt
                  ? '날짜를 선택하면\n묵상 내용을 볼 수 있어요'
                  : '아직 묵상 기록이 없어요\n첫 묵상을 시작해보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📝', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            '${selectedDate!.month}월 ${selectedDate!.day}일\n묵상 기록이 없어요',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.textSecondary),
          ),
          if (onAddQt != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAddQt,
              icon: const Icon(Icons.add, size: 18),
              label: Text('${selectedDate!.month}월 ${selectedDate!.day}일 묵상 추가'),
            ),
          ],
        ],
      ),
    );
  }
}

class _QtEntryList extends StatelessWidget {
  final List<QtEntry> entries;
  final DateTime? selectedDate;
  final void Function(QtEntry) onEdit;
  final void Function(QtEntry) onDelete;

  const _QtEntryList({
    required this.entries,
    required this.selectedDate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.length == 1) {
      return _QtEntryDetail(
        entry: entries.first,
        onEdit: () => onEdit(entries.first),
        onDelete: () => onDelete(entries.first),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        return _QtEntryCollapsed(
          entry: entry,
          index: i + 1,
          colorScheme: colorScheme,
          onEdit: () => onEdit(entry),
          onDelete: () => onDelete(entry),
        );
      },
    );
  }
}

class _QtEntryCollapsed extends StatefulWidget {
  final QtEntry entry;
  final int index;
  final ColorScheme colorScheme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QtEntryCollapsed({
    required this.entry,
    required this.index,
    required this.colorScheme,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_QtEntryCollapsed> createState() => _QtEntryCollapsedState();
}

class _QtEntryCollapsedState extends State<_QtEntryCollapsed> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.backgroundLevel1,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index}',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entry.scriptureTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (widget.entry.prayer.isNotEmpty)
                          Text(
                            widget.entry.prayer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: cs.textSecondary, size: 20),
                    onSelected: (v) {
                      if (v == 'edit') widget.onEdit();
                      if (v == 'delete') widget.onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('수정'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('삭제', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: cs.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: cs.dividerColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailSection(icon: '💭', title: '묵상', content: widget.entry.meditation),
                  const SizedBox(height: 10),
                  _DetailSection(icon: '🌱', title: '적용', content: widget.entry.application),
                  const SizedBox(height: 10),
                  _DetailSection(icon: '🙏', title: '기도', content: widget.entry.prayer),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final Set<int> qtDays;
  final Set<int> sermonDays;
  final int? selectedDay;
  final void Function(int) onDayTap;
  final double aspectRatio;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.qtDays,
    required this.sermonDays,
    required this.selectedDay,
    required this.onDayTap,
    this.aspectRatio = 1.3,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=일, 1=월, ..., 6=토

    const weekLabels = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      children: [
        Row(
          children: weekLabels
              .map(
                (w) => Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: w == '일'
                            ? Colors.red.shade300
                            : colorScheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: aspectRatio,
          ),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startWeekday) return const SizedBox();
            final day = index - startWeekday + 1;
            final hasQt = qtDays.contains(day);
            final hasSermon = sermonDays.contains(day);
            final isSelected = selectedDay == day;
            final isToday =
                DateTime.now().year == focusedMonth.year &&
                DateTime.now().month == focusedMonth.month &&
                DateTime.now().day == day;

            return GestureDetector(
              onTap: () => onDayTap(day), // 모든 날짜 탭 가능
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : hasQt
                          ? colorScheme.primary.withValues(alpha: 0.15)
                          : null,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: colorScheme.primary, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            hasQt || hasSermon || isToday ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : hasQt
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                      ),
                    ),
                    // 하단 점: QT(초록) / 설교(인디고) / 둘 다
                    if (!isSelected && (hasQt || hasSermon))
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasQt)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primary,
                              ),
                            ),
                          if (hasSermon)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.indigo,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QtEntryDetail extends StatelessWidget {
  final QtEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QtEntryDetail({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(entry.date),
                    style: TextStyle(
                      color: colorScheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.scriptureTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.scriptureVerse,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('수정'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('삭제', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _DetailSection(icon: '💭', title: '묵상', content: entry.meditation),
        const SizedBox(height: 12),
        _DetailSection(icon: '🌱', title: '적용', content: entry.application),
        const SizedBox(height: 12),
        _DetailSection(icon: '🙏', title: '기도', content: entry.prayer),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String icon;
  final String title;
  final String content;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.backgroundLevel1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$icon $title',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }
}

// ─── 나의 기록 탭 ──────────────────────────────────────────────────────────
class _MyRecordsTab extends StatefulWidget {
  final List<QtEntry> qtList;
  final List<SermonEntry> sermonList;

  const _MyRecordsTab({required this.qtList, required this.sermonList});

  @override
  State<_MyRecordsTab> createState() => _MyRecordsTabState();
}

class _MyRecordsTabState extends State<_MyRecordsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _innerTab;
  late int _selectedYear;
  int? _selectedMonth; // null = 전체

  @override
  void initState() {
    super.initState();
    _innerTab = TabController(length: 2, vsync: this);
    _selectedYear = DateTime.now().year;
  }

  @override
  void dispose() {
    _innerTab.dispose();
    super.dispose();
  }

  // 전체 연도 목록 (QT + 설교 합산)
  List<int> get _availableYears {
    final years = <int>{DateTime.now().year};
    for (final e in widget.qtList) {
      years.add(e.date.year);
    }
    for (final e in widget.sermonList) {
      years.add(e.date.year);
    }
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  List<QtEntry> get _filteredQt => widget.qtList.where((e) {
        if (e.date.year != _selectedYear) return false;
        if (_selectedMonth != null && e.date.month != _selectedMonth) {
          return false;
        }
        return true;
      }).toList();

  List<SermonEntry> get _filteredSermon => widget.sermonList.where((e) {
        if (e.date.year != _selectedYear) return false;
        if (_selectedMonth != null && e.date.month != _selectedMonth) {
          return false;
        }
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 필터 행
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              // 연도 드롭다운
              DropdownButton<int>(
                value: _selectedYear,
                isDense: true,
                items: _availableYears
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y년')))
                    .toList(),
                onChanged: (y) {
                  if (y != null) setState(() => _selectedYear = y);
                },
              ),
              const SizedBox(width: 12),
              // 월 드롭다운
              DropdownButton<int?>(
                value: _selectedMonth,
                isDense: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('전체')),
                  ...List.generate(
                    12,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1}월'),
                    ),
                  ),
                ],
                onChanged: (m) => setState(() => _selectedMonth = m),
              ),
              const Spacer(),
              Text(
                '묵상 ${_filteredQt.length}건 · 설교 ${_filteredSermon.length}건',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // 묵상 / 설교 내부 탭
        TabBar(
          controller: _innerTab,
          tabs: [
            Tab(text: '묵상 (${_filteredQt.length})'),
            Tab(text: '설교 (${_filteredSermon.length})'),
          ],
        ),

        Expanded(
          child: TabBarView(
            controller: _innerTab,
            children: [
              _QtListView(entries: _filteredQt),
              _SermonListView(sermons: _filteredSermon),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 나의 기록 > 묵상 목록 ──────────────────────────────────────────────────
class _QtListView extends StatelessWidget {
  final List<QtEntry> entries;
  const _QtListView({required this.entries});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (entries.isEmpty) {
      return Center(
        child: Text(
          '해당 기간에 묵상 기록이 없어요',
          style: TextStyle(color: colorScheme.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final e = entries[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.backgroundLevel1,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('📖', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.scriptureTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('M월 d일 (E)', 'ko_KR').format(e.date),
                      style: TextStyle(
                        color: colorScheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (e.prayer.isNotEmpty)
                Icon(Icons.chevron_right, color: colorScheme.textSecondary, size: 18),
            ],
          ),
        );
      },
    );
  }
}

// ── 나의 기록 > 설교 목록 ──────────────────────────────────────────────────
class _SermonListView extends StatelessWidget {
  final List<SermonEntry> sermons;
  const _SermonListView({required this.sermons});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (sermons.isEmpty) {
      return Center(
        child: Text(
          '해당 기간에 설교 기록이 없어요',
          style: TextStyle(color: colorScheme.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sermons.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final s = sermons[i];
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SermonDetailScreen(sermon: s)),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.backgroundLevel1,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('✝️', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.pastor}  ·  ${DateFormat('M월 d일').format(s.date)}',
                        style: TextStyle(
                          color: colorScheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.textSecondary, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}
