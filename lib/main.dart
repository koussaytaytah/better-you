import 'dart:async';
import 'dart:convert';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/sound_service.dart';
import 'core/services/in_app_notification_listener.dart';
import 'shared/models/daily_log_model.dart';
import 'core/repositories/notification_settings_repository.dart';

import 'core/constants/app_theme.dart';
import 'shared/providers/language_provider.dart';
import 'shared/providers/theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:better_you/l10n/app_localizations.dart';

import 'shared/providers/auth_provider.dart';
import 'shared/providers/data_provider.dart';
import 'core/router/router.dart';
import 'shared/providers/lock_provider.dart';
import 'features/dashboard/screens/screen_time_lock_screen.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge-to-edge with transparent status bar — modern look on Android & iOS
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Catch all Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  // Catch all async/Dart errors outside Flutter
  runZonedGuarded(
    () => runApp(const ProviderScope(child: AppInitializer())),
    (error, stack) {
      debugPrint('BetterYou: Uncaught error: $error');
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;
  String _status = 'Starting up...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      debugPrint('BetterYou: Starting initialization...');

      // 1. Firebase - absolute priority
      _updateStatus('Initializing Firebase...');
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ).timeout(const Duration(seconds: 20));
          debugPrint('BetterYou: Firebase initialized');
        } else {
          debugPrint('BetterYou: Firebase already initialized');
        }
      } catch (e) {
        if (e.toString().contains('duplicate-app') || e.toString().contains('already exists')) {
          debugPrint('BetterYou: Firebase app already exists, continuing...');
        } else {
          rethrow;
        }
      }

      // 2. Dotenv
      _updateStatus('Loading environment...');
      try {
        await dotenv.load(fileName: ".env");
        debugPrint('BetterYou: Dotenv loaded');
      } catch (e) {
        debugPrint('BetterYou: Dotenv load failed (non-fatal): $e');
      }

      // 3. Hive
      _updateStatus('Initializing local database...');
      try {
        await Hive.initFlutter();
        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(DailyLogAdapter());
        }
        await Hive.openBox<DailyLog>('daily_logs');
        debugPrint('BetterYou: Hive initialized');
      } catch (e) {
        debugPrint('BetterYou: Hive init failed (non-fatal): $e');
      }

      // 4. Notifications (local + FCM)
      _updateStatus('Initializing notifications...');
      try {
        final notificationService = NotificationService();
        await notificationService.init();
        await notificationService.scheduleDailyReminder();
        debugPrint('BetterYou: Local notifications initialized');
      } catch (e) {
        debugPrint('BetterYou: Notification init failed (non-fatal): $e');
      }

      // 5. FCM (Firebase Cloud Messaging)
      try {
        final fcmService = FCMService();
        await fcmService.init();
        debugPrint('BetterYou: FCM initialized');
      } catch (e) {
        debugPrint('BetterYou: FCM init failed (non-fatal): $e');
      }

      // 5b. Sound effects
      try {
        await SoundService().init();
        debugPrint('BetterYou: SoundService initialized');
      } catch (e) {
        debugPrint('BetterYou: SoundService init failed (non-fatal): $e');
      }

      // 6. Crashlytics
      try {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(!kDebugMode);
        debugPrint('BetterYou: Crashlytics initialized');
      } catch (e) {
        debugPrint('BetterYou: Crashlytics init failed (non-fatal): $e');
      }

      _updateStatus('Finalizing...');
      if (mounted) {
        setState(() => _initialized = true);
      }
      debugPrint('BetterYou: Initialization complete');
    } catch (e, stack) {
      debugPrint('BetterYou: FATAL initialization error: $e');
      debugPrint(stack.toString());
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  void _updateStatus(String status) {
    if (mounted) {
      setState(() => _status = status);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    'Initialization Failed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _initialized = false;
                        _status = 'Retrying startup...';
                      });
                      _init();
                    },
                    child: const Text('RETRY'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  _status,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const MyApp();
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Better You',
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => UserStatusWrapper(child: child!),
      routerConfig: router,
    );
  }
}

class UserStatusWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const UserStatusWrapper({super.key, required this.child});

  @override
  ConsumerState<UserStatusWrapper> createState() => _UserStatusWrapperState();
}

class _UserStatusWrapperState extends ConsumerState<UserStatusWrapper>
    with WidgetsBindingObserver {
  StreamSubscription? _lockSub;
  static const _channel = MethodChannel('com.example.better_you/lock');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Defer non-critical listeners to post-frame to ensure UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLockListener();
      _checkInitialLock();
      _initNotificationListener();
      _updateStatus(true);
      _scheduleSmartNotifications();
      _initFCM();
    });
  }

  void _initNotificationListener() {
    final plugin = FlutterLocalNotificationsPlugin();
    plugin.getNotificationAppLaunchDetails().then((details) {
      if (details?.didNotificationLaunchApp ?? false) {
        _handleNotificationPayload(details?.notificationResponse?.payload);
      }
    });
  }

  void _handleNotificationPayload(String? payload) {
    if (payload != null) {
      try {
        final data = json.decode(payload);
        if (data['locked_app'] != null) {
          ref
              .read(lockProvider.notifier)
              .setLock(
                data['locked_app'],
                data['quest'] ?? 'Complete your quest',
              );
        }
      } catch (e) {
        debugPrint('BetterYou: Error parsing notification payload: $e');
      }
    }
  }

  void _checkInitialLock() async {
    try {
      final Map? data = await _channel.invokeMethod('getLockData');
      if (data != null && data['locked_app'] != null) {
        debugPrint('BetterYou: Initial lock found for ${data['locked_app']}');
        ref
            .read(lockProvider.notifier)
            .setLock(
              data['locked_app'],
              data['quest'] ?? 'Complete your quest',
            );
      }
    } catch (e) {
      debugPrint('BetterYou: Error checking initial lock: $e');
    }
  }

  void _initLockListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onLockTriggered') {
        final data = call.arguments as Map;
        debugPrint(
          'BetterYou: Lock triggered via method channel for ${data['locked_app']}',
        );
        ref
            .read(lockProvider.notifier)
            .setLock(
              data['locked_app'],
              data['quest'] ?? 'Complete your quest',
            );
      }
    });

    _lockSub = FlutterBackgroundService().on('locked_app').listen((event) {
      if (event != null && event['locked_app'] != null) {
        debugPrint(
          'BetterYou: Lock triggered via stream for ${event['locked_app']}',
        );
        ref
            .read(lockProvider.notifier)
            .setLock(event['locked_app'], event['quest'] ?? 'Do your quest');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateStatus(true);
      _checkInitialLock();
    } else {
      _updateStatus(false);
    }
  }

  void _updateStatus(bool isOnline) {
    final currentUserAsync = ref.read(currentUserAsyncProvider);
    final user = currentUserAsync.value;
    if (user != null) {
      ref.read(userRepositoryProvider).updateUserProfile(user.uid, {
        'isOnline': isOnline,
      });
    }
  }

  // Save FCM token and init FCM for current user
  void _initFCM() async {
    final currentUserAsync = ref.read(currentUserAsyncProvider);
    final user = currentUserAsync.value;
    if (user == null) return;

    try {
      final fcmService = FCMService();
      await fcmService.saveTokenForUser(user.uid);
      await fcmService.subscribeToTopic('all_users');
      debugPrint('BetterYou: FCM initialized for user ${user.uid}');
    } catch (e) {
      debugPrint('BetterYou: FCM init failed: $e');
    }

    // Free in-app push: listen to /notifications collection and fire local notifications
    try {
      await InAppNotificationListener().start(user.uid);
      debugPrint('BetterYou: In-app notification listener started');
    } catch (e) {
      debugPrint('BetterYou: In-app listener failed: $e');
    }
  }

  // Schedule smart notifications when user logs in
  void _scheduleSmartNotifications() async {
    final currentUserAsync = ref.read(currentUserAsyncProvider);
    final user = currentUserAsync.value;
    if (user == null) return;

    try {
      final repository = NotificationSettingsRepository();
      final settings = await repository.getSettings(user.uid);
      
      final notificationService = NotificationService();
      await notificationService.scheduleAllNotifications(settings);
      
      debugPrint('BetterYou: Smart notifications scheduled for user ${user.uid}');
    } catch (e) {
      debugPrint('BetterYou: Failed to schedule notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(lockProvider);

    // Global listener for Coach Suggested Quests
    ref.listen(questsProvider, (previous, next) {
      if (next.hasValue && previous?.hasValue == true) {
        final prevQuests = previous!.value!;
        final nextQuests = next.value!;
        
        // Find new coach suggested quests
        final newCoachQuests = nextQuests.where((q) => 
          q.isCoachSuggested && 
          !prevQuests.any((pq) => pq.id == q.id)
        );

        if (newCoachQuests.isNotEmpty) {
           final quest = newCoachQuests.first;
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Row(
                 children: [
                   const Icon(Icons.verified, color: Colors.white, size: 20),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       'New Quest from ${quest.assignedByName ?? "your Coach"}: "${quest.title}"',
                       style: const TextStyle(fontWeight: FontWeight.bold),
                     ),
                   ),
                 ],
               ),
               backgroundColor: AppColors.accent,
               behavior: SnackBarBehavior.floating,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               duration: const Duration(seconds: 5),
               action: SnackBarAction(
                 label: 'VIEW',
                 textColor: Colors.white,
                 onPressed: () => context.push('/quests'),
               ),
             ),
           );
        }
      }
    });

    if (lockState.lockedApp != null) {
      return ScreenTimeLockScreen(
        appName: lockState.lockedApp!,
        questDescription: lockState.quest ?? 'Complete your quest',
        onUnlock: (bonus) {
          ref.read(lockProvider.notifier).unlockWithBonus(bonus);
        },
      );
    }

    return widget.child;
  }
}
