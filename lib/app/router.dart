import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../features/home/home_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/qt_form/qt_form_screen.dart';
import '../features/prayer_card/prayer_card_screen.dart';
import '../features/community/community_list_screen.dart';
import '../features/community/create_community_screen.dart';
import '../features/community/join_community_screen.dart';
import '../features/history/history_screen.dart';
import '../features/auth/profile_screen.dart';
import '../features/sermon/sermon_form_screen.dart';
import '../features/sermon/sermon_detail_screen.dart';
import '../features/report/weekly_report_screen.dart';
import '../shared/models/qt_entry.dart';
import '../shared/models/sermon_entry.dart';
import '../shared/providers/auth_provider.dart';
import 'shell_scaffold.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isLoading = authState.isLoading;
      final isLoggedIn = user != null;
      final isAnonymous = user?.isAnonymous ?? false;
      final isAuthRoute = state.uri.path == AppRoutes.login ||
          state.uri.path == AppRoutes.signup;

      if (isLoading) return null;
      // 미로그인 상태에서 앱 내부 접근 시 로그인으로 (익명 부트스트랩 실패 등 예외 상황)
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      // 실계정(이메일)으로 로그인된 경우에만 auth 라우트 접근 차단
      // 익명 사용자는 계정 만들기/로그인 화면에 접근 가능해야 함
      if (isLoggedIn && !isAnonymous && isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      // 인증 라우트 (Shell 밖)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),

      // Shell: BottomNavigationBar를 감싸는 라우트
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            ShellScaffold(navigatorKey: _shellNavigatorKey, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.community,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CommunityListScreen()),
          ),
          GoRoute(
            path: AppRoutes.history,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HistoryScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      // 모달/풀스크린 라우트 (Shell 밖)
      GoRoute(
        path: AppRoutes.qtForm,
        builder: (context, state) {
          final initialDate = state.extra as DateTime?;
          return QtFormScreen(initialDate: initialDate);
        },
      ),
      GoRoute(
        path: AppRoutes.qtEdit,
        builder: (context, state) {
          final entry = state.extra as QtEntry;
          return QtFormScreen(editEntry: entry);
        },
      ),
      GoRoute(
        path: AppRoutes.prayerCard,
        builder: (context, state) {
          final entry = state.extra as QtEntry;
          return PrayerCardScreen(entry: entry);
        },
      ),
      GoRoute(
        path: AppRoutes.sermonNew,
        builder: (context, state) => const SermonFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.sermonDetail,
        builder: (context, state) {
          final sermon = state.extra as SermonEntry;
          return SermonDetailScreen(sermon: sermon);
        },
      ),
      GoRoute(
        path: AppRoutes.communityCreate,
        builder: (context, state) => const CreateCommunityScreen(),
      ),
      GoRoute(
        path: AppRoutes.communityJoin,
        builder: (context, state) => const JoinCommunityScreen(),
      ),
      GoRoute(
        path: AppRoutes.weeklyReport,
        builder: (context, state) => const WeeklyReportScreen(),
      ),
    ],
  );
});

// 기존 호환성을 위한 static router (auth 상태 없이 사용 시 fallback)
final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
  ],
);
