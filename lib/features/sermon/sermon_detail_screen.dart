import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/models/sermon_entry.dart';
import '../../shared/providers/sermon_provider.dart';
import '../../app/theme/app_colors.dart';

class SermonDetailScreen extends ConsumerWidget {
  final SermonEntry sermon;
  const SermonDetailScreen({super.key, required this.sermon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('주일설교'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('설교 삭제'),
                    content: const Text('이 설교를 삭제하면 달란트 5개가 회수됩니다.'),
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
                if (confirmed == true && context.mounted) {
                  await ref.read(sermonServiceProvider).deleteSermon(sermon.id);
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
            itemBuilder: (_) => [
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 날짜
          Text(
            DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(sermon.date),
            style: TextStyle(color: colorScheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),

          // 제목
          Text(
            sermon.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          // 설교자 + 본문
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: colorScheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                sermon.pastor,
                style: TextStyle(color: colorScheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(width: 12),
              Icon(Icons.menu_book_outlined, size: 16, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                sermon.scriptureRef,
                style: TextStyle(color: colorScheme.primary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 요약
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.backgroundLevel1,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: colorScheme.primary, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 설교 요약',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sermon.summary,
                  style: const TextStyle(fontSize: 15, height: 1.7),
                ),
              ],
            ),
          ),

          // 전체 내용 (있을 때만)
          if (sermon.fullContent.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.backgroundLevel1,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📝 설교 전문',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sermon.fullContent,
                    style: const TextStyle(fontSize: 14, height: 1.7),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
