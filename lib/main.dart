import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'providers/task_provider.dart';
import 'providers/flashcard_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/water_provider.dart';
import 'providers/timetable_provider.dart';
import 'providers/user_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/upload/upload_screen.dart';
import 'screens/notes/notes_screen.dart';
import 'screens/flashcards/flashcards_screen.dart';
import 'screens/timetable/timetable_screen.dart';
import 'screens/tasks/tasks_screen.dart';
import 'screens/pomodoro/pomodoro_screen.dart';
import 'screens/water/water_screen.dart';
import 'widgets/bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Load Environment Variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Failed to load .env file: $e");
  }

  // 2. Initialize Hive Service (CRITICAL for Storage)
  try {
    await HiveService().init();
    debugPrint("Hive initialized successfully");
  } catch (e) {
    debugPrint("CRITICAL: Failed to init HiveService: $e");
  }

  // 3. Initialize Notification Service
  try {
    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.rescheduleAll();
    debugPrint("Notifications initialized successfully");
  } catch (e) {
    debugPrint("Failed to init NotificationService: $e");
  }

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Modern UI adjustments
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const StudyAIApp());
}

class StudyAIApp extends StatelessWidget {
  const StudyAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => FlashcardProvider()),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => WaterProvider()),
        ChangeNotifierProvider(create: (_) => TimetableProvider()),
      ],
      child: MaterialApp(
        title: 'StudyAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MainScaffold(),
        routes: {
          '/upload': (_) => const UploadScreen(),
          '/notes': (_) => const NotesScreen(),
          '/flashcards': (_) => const FlashcardsScreen(),
          '/timetable': (_) => const TimetableScreen(),
          '/tasks': (_) => const TasksScreen(),
          '/pomodoro': (_) => const PomodoroScreen(),
          '/water': (_) => const WaterScreen(),
        },
      ),
    );
  }
}

// ── Main Scaffold with Bottom Navigation ──────────────────────────
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => MainScaffoldState();
}

class MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // Tab order: Home, Notes, Flashcards, Tasks, Pomodoro(Focus)
  late final List<Widget> _screens = [
    HomeScreen(onTabChange: (index) => setState(() => _currentIndex = index)),
    const NotesScreen(),
    const FlashcardsScreen(),
    const TasksScreen(),
    const PomodoroScreen(),
  ];

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: StudyBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
      // Floating actions for Pomodoro & Water
      floatingActionButton: _currentIndex == 0 ? _FloatingToolbar() : null,
    );
  }
}

class _FloatingToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _FABItem(
          emoji: '💧',
          label: 'Water',
          onTap: () => Navigator.push(
            context,
            _buildPageRoute(const WaterScreen()),
          ),
        ),
        const SizedBox(height: 8),
        _FABItem(
          emoji: '🍅',
          label: 'Pomodoro',
          onTap: () => Navigator.push(
            context,
            _buildPageRoute(const PomodoroScreen()),
          ),
        ),
        const SizedBox(height: 8),
        _FABItem(
          emoji: '📅',
          label: 'Timetable',
          onTap: () => Navigator.push(
            context,
            _buildPageRoute(const TimetableScreen()),
          ),
        ),
      ],
    );
  }

  PageRoute _buildPageRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => screen,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

class _FABItem extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _FABItem({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          boxShadow: AppTheme.elevatedShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label, style: AppTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
