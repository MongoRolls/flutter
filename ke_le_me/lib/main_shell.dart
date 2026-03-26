import 'package:flutter/material.dart';

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
  const MainShell({super.key, required this.userProvider});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final PlanProvider _planProvider;
  late final HeartProvider _heartProvider;
  late final PlazaProvider _plazaProvider;

  @override
  void initState() {
    super.initState();
    _planProvider = PlanProvider(userProvider: widget.userProvider);
    _planProvider.loadTodayPlan();
    _heartProvider = HeartProvider();
    _plazaProvider = PlazaProvider(
      userProvider: widget.userProvider,
    );
  }

  @override
  void dispose() {
    _planProvider.dispose();
    _heartProvider.dispose();
    _plazaProvider.dispose();
    super.dispose();
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
            heartProvider: _heartProvider,
            plazaProvider: _plazaProvider,
          ),
          SettingsScreen(userProvider: widget.userProvider),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
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
