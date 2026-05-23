import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard/match_create_screen.dart';
import '../../features/dashboard/team_setup_screen.dart';
import '../../features/dashboard/toss_screen.dart';
import '../../features/camera/camera_screen.dart';
import '../../features/drs/drs_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/analytics/match_summary_screen.dart';
import '../../features/admin/admin_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/matches/create',
      builder: (context, state) => const MatchCreateScreen(),
    ),
    GoRoute(
      path: '/matches/:id/team-setup',
      builder: (context, state) {
        final matchId = state.pathParameters['id'] ?? '';
        return TeamSetupScreen(matchId: matchId);
      },
    ),
    GoRoute(
      path: '/matches/:id/toss',
      builder: (context, state) {
        final matchId = state.pathParameters['id'] ?? '';
        return TossScreen(matchId: matchId);
      },
    ),
    GoRoute(
      path: '/matches/:id/camera',
      builder: (context, state) {
        final matchId = state.pathParameters['id'] ?? '';
        return CameraScreen(matchId: matchId);
      },
    ),
    GoRoute(
      path: '/matches/:id/drs',
      builder: (context, state) {
        final matchId = state.pathParameters['id'] ?? '';
        return DrsScreen(matchId: matchId);
      },
    ),
    GoRoute(
      path: '/matches/:id/analytics',
      builder: (context, state) {
        final matchId = state.pathParameters['id'] ?? '';
        return AnalyticsScreen(matchId: matchId);
      },
    ),
    GoRoute(
      path: '/matches/:id/summary',
      builder: (context, state) {
        final matchId = state.pathParameters['id'] ?? '';
        return MatchSummaryScreen(matchId: matchId);
      },
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Route not found: ${state.error}'),
    ),
  ),
);
