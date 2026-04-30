import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/skills_screen.dart';
import 'screens/qualifications_screen.dart';
import 'screens/training_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/notifications_screen.dart';
import 'firebase_options.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/skills_viewmodel.dart';
import 'viewmodels/qualifications_viewmodel.dart';
import 'viewmodels/training_viewmodel.dart';
import 'viewmodels/documents_viewmodel.dart';
import 'viewmodels/notifications_viewmodel.dart';
import 'services/inactivity_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final InactivityService _inactivityService = InactivityService();

  @override
  void dispose() {
    _inactivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProxyProvider<AuthViewModel, DashboardViewModel>(
          create:
              (context) => DashboardViewModel(
                Provider.of<AuthViewModel>(context, listen: false),
              ),
          update:
              (_, authViewModel, dashboardViewModel) =>
                  DashboardViewModel(authViewModel),
        ),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => SkillsViewModel()),
        ChangeNotifierProvider(create: (_) => QualificationsViewModel()),
        ChangeNotifierProvider(create: (_) => TrainingViewModel()),
        ChangeNotifierProvider(create: (_) => DocumentsViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
      ],
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification) {
            _inactivityService.resetTimer();
          }
          return false;
        },
        child: GestureDetector(
          onTap: _inactivityService.resetTimer,
          behavior: HitTestBehavior.translucent,
          child: MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Skills Audit System',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0F172A),
                primary: const Color(0xFF0F172A),
              ),
              useMaterial3: true,
            ),
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/dashboard': (context) => const DashboardScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/skills': (context) => const SkillsScreen(),
              '/qualifications': (context) => const QualificationsScreen(),
              '/training': (context) => const TrainingScreen(),
              '/documents': (context) => const DocumentsScreen(),
              '/notifications': (context) => const NotificationsScreen(),
            },
            builder: (context, child) {
              _inactivityService.initialize(_navigatorKey);
              return child!;
            },
          ),
        ),
      ),
    );
  }
}
