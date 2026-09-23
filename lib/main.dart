import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'pages/home_page.dart';
import 'pages/socket_page.dart';
import 'pages/analytics_page.dart';
import 'pages/modes_page.dart';
import 'pages/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DesproApp());
}

class DesproApp extends StatelessWidget {
  const DesproApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Despro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: const Color(0xFF6AC9FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6AC9FF),
          secondary: Color(0xFF00E1A4),
          error: Color(0xFFFF5757),
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: const AppEntry(),
    );
  }
}

///
/// APP ENTRY FLOW
/// 1. SplashPage (while init/delay)
/// 2. OpeningMessagePage (3 detik, cinematic)
/// 3. RootPage (app utama)
///
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initApp();
  }

  Future<void> _initApp() async {
    // Di sini nanti bisa tambah init lain (preferences, dsb).
    await Future.delayed(const Duration(milliseconds: 1200));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Lagi “booting” → tampilkan splash
          return const SplashPage();
        }

        if (snapshot.hasError) {
          // Kelihatan kalau ada error saat init
          return Scaffold(
            backgroundColor: const Color(0xFF0F0F0F),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Initialization error:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }

        // Init selesai → lanjut ke opening message 3 detik
        return const OpeningWrapper();
      },
    );
  }
}

///
/// Wrapper Opening → RootPage (dengan animasi)
///
class OpeningWrapper extends StatefulWidget {
  const OpeningWrapper({super.key});

  @override
  State<OpeningWrapper> createState() => _OpeningWrapperState();
}

class _OpeningWrapperState extends State<OpeningWrapper> {
  bool _showOpening = true;

  @override
  void initState() {
    super.initState();
    // 3 detik tampil opening message
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showOpening = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _showOpening
          ? const OpeningMessagePage(key: ValueKey('opening'))
          : const RootPage(key: ValueKey('root')),
    );
  }
}

///
/// CINEMATIC OPENING MESSAGE
/// "Capstone Project Smart KWh Meter – Group 14"
///
class OpeningMessagePage extends StatelessWidget {
  const OpeningMessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: Stack(
        children: [
          // Glow background di belakang
          Positioned(
            left: -60,
            top: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scheme.primary.withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scheme.secondary.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 24 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Garis kecil cinematic
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutQuad,
                      builder: (context, v, _) {
                        return Container(
                          width: 120 * v,
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              colors: [
                                scheme.primary.withOpacity(0.0),
                                scheme.primary,
                                scheme.secondary,
                                scheme.secondary.withOpacity(0.0),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Capstone Project',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Smart KWh Meter',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Group 14 — Despro 2025',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Chip kecil di bawah, delay dikit
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) {
                        return Opacity(
                          opacity: v,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - v)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withOpacity(0.05),
                                border: Border.all(
                                  color:
                                  Colors.white.withOpacity(0.12),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.electric_bolt_rounded,
                                    size: 16,
                                    color: scheme.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Smart Energy Dashboard',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.82),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

///
/// SPLASH PAGE (pertama kali muncul setelah app start)
///
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF080C14),
              Color(0xFF101826),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 24 * (1 - value)),
                    child: Transform.scale(
                      scale: 0.9 + 0.1 * value,
                      child: child,
                    ),
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glow circle + icon
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF121212),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.7),
                              blurRadius: 26,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.electric_bolt_rounded,
                          size: 40,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Capstone Project Smart KWh Meter',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Smart Energy, Group 14 Despro 2025',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.78),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

///
/// ROOT (APP UTAMA)
///
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    SocketPage(),
    AnalyticsPage(),
    ModesPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF050505),
        border: Border(
          top: BorderSide(color: Color(0xFF1E1E1E), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF050505),
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: Colors.grey[500],
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.power_outlined),
              activeIcon: Icon(Icons.power),
              label: 'Sockets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_mode_outlined),
              activeIcon: Icon(Icons.auto_mode_rounded),
              label: 'Modes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
