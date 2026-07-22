import 'package:fitcoach_/screens/homescreen.dart';
import 'package:fitcoach_/screens/login.dart';
import 'package:fitcoach_/services/auth_gate.dart';
import 'package:fitcoach_/services/push_notification_service.dart';
import 'package:fitcoach_/services/notification_manager.dart';
import 'package:fitcoach_/services/theme_manager.dart';
import 'package:fitcoach_/services/workout_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  final pushService = PushNotificationService();
  await pushService.initialize();

  await NotificationManager.instance.initialize();
  await ThemeManager.instance.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const Myapp());
}

class Myapp extends StatelessWidget {
  const Myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeManager.instance,
        WorkoutManager.instance.isWorkoutActive,
        WorkoutManager.instance.isMinimized,
      ]),
      builder: (context, child) {
        return MaterialApp(
          title: 'FitCoach AI',
          debugShowCheckedModeBanner: false,
          navigatorKey: globalNavigatorKey,
          builder: (context, child) {
            return Stack(
              children: [if (child != null) child, const GlobalMiniPlayer()],
            );
          },
          themeMode: ThemeManager.instance.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            primaryColor: const Color(0xFFBB86FC),
            cardColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD0FD3E),
              secondary: Color(0xFFBB86FC),
              surface: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF000000),
            primaryColor: const Color(0xFFBB86FC),
            cardColor: const Color(0xFF1C1C1E),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD0FD3E),
              secondary: Color(0xFFBB86FC),
              surface: Color(0xFF1C1C1E),
            ),
          ),
          home: const AuthGate(),
          routes: {
            '/login': (context) => const Login(),
            '/home': (context) => const Homescreen(),
          },
        );
      },
    );
  }
}
