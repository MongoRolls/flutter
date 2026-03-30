import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/models/memory_fact.dart';
import 'core/models/session_summary.dart';
import 'core/models/custom_reminder.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/user_provider.dart';
import 'core/services/backend_api_service.dart';
import 'core/services/notification_service.dart';
import 'features/plan/models/today_plan.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/debug/screens/debug_screen.dart';
import 'main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(MemoryFactAdapter());
  Hive.registerAdapter(SessionSummaryAdapter());
  Hive.registerAdapter(CustomReminderAdapter());
  Hive.registerAdapter(TodayPlanAdapter());
  await Hive.openBox<MemoryFact>('memory_facts');
  await Hive.openBox<SessionSummary>('session_summaries');
  await Hive.openBox<CustomReminder>('custom_reminders');
  await Hive.openBox<TodayPlan>('today_plans');
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const KeLeMeApp());
}

class KeLeMeApp extends StatefulWidget {
  const KeLeMeApp({super.key});

  @override
  State<KeLeMeApp> createState() => _KeLeMeAppState();
}

class _KeLeMeAppState extends State<KeLeMeApp> {
  final _userProvider = UserProvider();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await Future.wait([
        NotificationService.instance.init(),
        BackendApiService.instance.init(),
      ]);
      try {
        await BackendApiService.instance.ensureAuthenticated();
      } catch (e) {
        debugPrint('Backend auth failed (offline mode): $e');
      }
      await _userProvider.loadProfile();
      // 已完成 onboarding 且开启通知的用户，启动时重新调度
      if (_userProvider.profile.onboardingCompleted &&
          _userProvider.profile.notificationsEnabled) {
        await NotificationService.instance.scheduleReminders(
          wakeTime: _userProvider.profile.wakeTime,
          bedTime: _userProvider.profile.bedTime,
          intervalMin: _userProvider.profile.reminderIntervalMin,
          reminderStyle: _userProvider.profile.reminderStyle,
        );
      }
    } catch (e) {
      debugPrint('Init error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '渴了么',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isLoading
          ? const Scaffold(
              backgroundColor: AppColors.bgDeep,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.blue),
              ),
            )
          : _userProvider.profile.onboardingCompleted
          ? MainShell(userProvider: _userProvider)
          : OnboardingScreen(userProvider: _userProvider),
      routes: {
        '/onboarding': (_) => OnboardingScreen(userProvider: _userProvider),
        '/debug': (_) => DebugScreen(userProvider: _userProvider),
      },
    );
  }
}
