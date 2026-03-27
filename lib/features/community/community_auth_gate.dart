import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';

/// 익명 사용자가 공동체 기능을 시도할 때 표시하는 바텀시트
Future<void> showCommunityAuthGate(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('🤝', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              '공동체 기능은 계정이 필요해요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '계정을 만들면 공동체에 참여하고\n다른 분들과 묵상을 나눌 수 있어요.\n지금까지의 QT 기록은 그대로 유지돼요!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.signup);
                },
                child: const Text('계정 만들기'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.login);
                },
                child: const Text('이미 계정이 있어요 (로그인)'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
