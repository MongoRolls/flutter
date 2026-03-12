import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/app_theme.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    await NotificationService.instance.init();
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
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          backgroundColor: AppColors.bgDeep,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          ),
        ),
      );
    }

    return MaterialApp(
      title: '渴了么',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _userProvider.profile.onboardingCompleted
          ? HomeScreen(userProvider: _userProvider)
          : OnboardingScreen(userProvider: _userProvider),
      routes: {
        '/onboarding': (_) => OnboardingScreen(userProvider: _userProvider),
        '/home': (_) => HomeScreen(userProvider: _userProvider),
        '/settings': (_) => SettingsScreen(userProvider: _userProvider),
      },
    );
  }
}
