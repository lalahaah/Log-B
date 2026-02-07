// AI 기능 구현 시 사용 예정
// import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // auth_screen.dart에서 사용
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/directory_tab.dart';
import 'screens/reports_tab.dart';
import 'screens/schedule_tab.dart';

// --- Log,B Brand Design System (Green Edition) ---
class LogBTheme {
  // Primary Green Palette
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald50 = Color(0xFFECFDF5);

  // Neutral Palette
  static const Color slate950 = Color(0xFF0F172A); // Dark Mode Bg
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate500 = Color(0xFF64748B);
  static const Color bgLight = Color(0xFFF8FAF8);

  // Custom Gradient
  static const LinearGradient greenGradient = LinearGradient(
    colors: [emerald600, emerald500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LogBApp());
}

class LogBApp extends StatelessWidget {
  const LogBApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Log,B',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light, // Change to dark for dark mode testing
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: LogBTheme.bgLight,
        colorScheme: ColorScheme.fromSeed(seedColor: LogBTheme.emerald600),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Pretendard',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: LogBTheme.slate950,
      ),
      home: const SplashScreen(),
    );
  }
}

// --- Splash Screen ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Navigate to main screen after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthGate(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? LogBTheme.slate950 : LogBTheme.bgLight,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/images/LogB_Green_Icon.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 32),

                // Brand Name "Log,B"
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w900,
                      fontSize: 42,
                      letterSpacing: -1.5,
                      color: isDark ? Colors.white : LogBTheme.slate900,
                    ),
                    children: const [
                      TextSpan(text: 'Log'),
                      TextSpan(
                        text: ',',
                        style: TextStyle(
                          color: LogBTheme.emerald600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(text: 'B'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tagline "Log! Business"
                Text(
                  'Log! Business',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: isDark
                        ? LogBTheme.slate500
                        : LogBTheme.slate500.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Official Log,B Green Edition Logo ---
// Using the official brand assets from /logo folder

// --- Main Navigation Frame ---
class MainNavigationFrame extends StatefulWidget {
  const MainNavigationFrame({super.key});

  @override
  State<MainNavigationFrame> createState() => _MainNavigationFrameState();
}

class _MainNavigationFrameState extends State<MainNavigationFrame> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DirectoryTab(),
    const ReportsTab(),
    const ScheduleTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : LogBTheme.slate900,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.people_outline, Icons.people, "인맥"),
            _navItem(1, Icons.chat_bubble_outline, Icons.chat_bubble, "기록"),
            _navItem(
              2,
              Icons.calendar_today_outlined,
              Icons.calendar_today,
              "일정",
            ),
            _navItem(3, Icons.settings_outlined, Icons.settings, "설정"),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData outline, IconData filled, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filled : outline,
              color: isSelected ? LogBTheme.emerald600 : Colors.white54,
              size: 24,
            ),
            if (isSelected)
              Text(
                label,
                style: const TextStyle(
                  color: LogBTheme.emerald600,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Schedule, Reports, Settings Tabs ---
// ScheduleTab은 screens/schedule_tab.dart에서 정의됨

// ReportsTab은 screens/reports_tab.dart에서 정의됨

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text("보안 설정 및 동기화"));
}
