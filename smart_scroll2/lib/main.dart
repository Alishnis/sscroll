// SmartScroll v1 - Educational short-form video platform
// Last modified: 2024-12-19 08:15:00 UTC
// Project location: /Users/aliserromankul/Downloads/smart_scroll_v1

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/video_provider.dart';
import 'providers/group_provider.dart';
import 'providers/user_provider.dart';
import 'providers/post_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/quizlet_provider.dart';
import 'providers/tts_provider.dart';
import 'screens/profile_screen.dart';
import 'screens/posts_screen.dart';
import 'screens/mixed_feed_screen.dart';
import 'screens/reddit_test_screen.dart';
import 'screens/quizlet_screen.dart';
import 'screens/tts_demo_screen.dart';

void main() {
  runApp(const SmartScrollApp());
}

class SmartScrollApp extends StatelessWidget {
  const SmartScrollApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..setMockUser()),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => QuizletProvider()),
        ChangeNotifierProvider(create: (_) => TTSProvider()),
      ],
      child: MaterialApp(
        title: 'SmartScroll v1.0',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MixedFeedScreen(),
    PostsScreen(),
    ProfileScreen(),
    RedditTestScreen(), // Тестовый экран для Reddit
    QuizletScreen(), // Quizlet Study экран
    TTSDemoScreen(), // TTS Demo экран
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.feed_outlined),
            selectedIcon: Icon(Icons.feed),
            label: 'Лента',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Посты',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
          NavigationDestination(
            icon: Icon(Icons.bug_report_outlined),
            selectedIcon: Icon(Icons.bug_report),
            label: 'Reddit Test',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Quizlet',
          ),
          NavigationDestination(
            icon: Icon(Icons.volume_up_outlined),
            selectedIcon: Icon(Icons.volume_up),
            label: 'TTS Demo',
          ),
        ],
      ),
    );
  }
}
