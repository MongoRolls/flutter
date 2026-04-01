import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/user_provider.dart';
import 'features/plan/providers/plan_provider.dart';
import 'features/community/providers/heart_provider.dart';
import 'features/community/providers/plaza_provider.dart';
import 'features/home/screens/home_screen.dart';
import 'features/plan/screens/plan_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/community/screens/community_screen.dart';
import 'features/settings/screens/settings_screen.dart';

class MainShell extends StatefulWidget {
  final UserProvider userProvider;
  final HeartProvider heartProvider;

  const MainShell({
    super.key,
    required this.userProvider,
    required this.heartProvider,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final PlanProvider _planProvider;
  late final PlazaProvider _plazaProvider;

  /// 停留在社区 Tab 时周期性刷新队友饮水摘要（IndexedStack 不会卸载子页）。
  Timer? _communityHydrationPoll;

  @override
  void initState() {
    super.initState();
    _planProvider = PlanProvider(userProvider: widget.userProvider);
    _planProvider.loadTodayPlan();
    _plazaProvider = PlazaProvider(
      userProvider: widget.userProvider,
    );
  }

  @override
  void dispose() {
    _communityHydrationPoll?.cancel();
    _planProvider.dispose();
    _plazaProvider.dispose();
    super.dispose();
  }

  Future<void> _syncCommunityTabData() async {
    await Future.wait([
      widget.heartProvider.load(),
      _plazaProvider.refresh(),
    ]);
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final prev =
        prefs.getBool(NotificationService.waterRemindersUsePeerCopyPrefKey) ??
            false;
    final hasTeammates = widget.heartProvider.contacts.isNotEmpty;
    await prefs.setBool(
      NotificationService.waterRemindersUsePeerCopyPrefKey,
      hasTeammates,
    );
    final now =
        prefs.getBool(NotificationService.waterRemindersUsePeerCopyPrefKey) ??
            false;

    if (now != prev &&
        mounted &&
        widget.userProvider.profile.notificationsEnabled) {
      try {
        await NotificationService.instance.scheduleReminders(
          wakeTime: widget.userProvider.profile.wakeTime,
          bedTime: widget.userProvider.profile.bedTime,
          intervalMin: widget.userProvider.profile.reminderIntervalMin,
          reminderStyle: widget.userProvider.profile.reminderStyle,
        );
      } catch (e) {
        debugPrint('Community tab reschedule reminders failed: $e');
      }
    }
  }

  void _onBottomNavTap(int i) {
    setState(() => _currentIndex = i);

    _communityHydrationPoll?.cancel();
    _communityHydrationPoll = null;

    if (i == 3) {
      unawaited(_syncCommunityTabData());
      _communityHydrationPoll = Timer.periodic(
        const Duration(seconds: 45),
        (_) => unawaited(widget.heartProvider.refreshPeersHydration()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(userProvider: widget.userProvider),
          PlanScreen(
            userProvider: widget.userProvider,
            planProvider: _planProvider,
          ),
          ChatScreen(userProvider: widget.userProvider),
          CommunityScreen(
            userProvider: widget.userProvider,
            heartProvider: widget.heartProvider,
            plazaProvider: _plazaProvider,
          ),
          SettingsScreen(
            userProvider: widget.userProvider,
            heartProvider: widget.heartProvider,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.blue,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '首页'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '安排',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_rounded),
            label: 'AI 助手',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: '社区',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
