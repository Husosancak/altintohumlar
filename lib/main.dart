import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/about_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/plans_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BorsaMeydaniApp());
}

class BorsaMeydaniApp extends StatelessWidget {
  const BorsaMeydaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Altin Tohumlar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.lightBlue)
            .copyWith(secondary: Colors.blueAccent),
      ),
      debugShowCheckedModeBanner: false,
      home: const MainNavigation(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => const MainNavigation(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const FavoritesScreen(),
    const PlansScreen(),
    AboutScreen(),
    const ProfileScreen(),
  ];

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return token.isNotEmpty;
  }

  Future<void> _onItemTapped(int index) async {
    if (index == 4) {
      final loggedIn = await _isLoggedIn();
      if (!loggedIn) {
        if (!mounted) return;
        await Navigator.pushNamed(context, '/login');
        final nowLogged = await _isLoggedIn();
        if (!nowLogged) return;
      }
    }

    if (!mounted) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => _onItemTapped(index),
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Favoriler'),
          BottomNavigationBarItem(
              icon: Icon(Icons.note_alt_outlined), label: 'Notlarim'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Hakkinda'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
