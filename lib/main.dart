import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/about_screen.dart';
import 'screens/profile_screen.dart'; // hazırsa aç

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BorsaMeydaniApp());
}

class BorsaMeydaniApp extends StatelessWidget {
  const BorsaMeydaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Altın Tohumlar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.lightBlue)
            .copyWith(secondary: Colors.blueAccent),
      ),
      debugShowCheckedModeBanner: false,
      home: const MainNavigation(), // otomatik misafir
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => const MainNavigation(),
        '/profile': (context) => const ProfileScreen(), // varsa aç
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

  // Sayfaları bir kez oluştur; sekme değişince state kaybolmasın
  late final List<Widget> _pages = <Widget>[
    HomeScreen(),
    const FavoritesScreen(),
    AboutScreen(),
    const ProfileScreen(), // ProfileScreen’in yoksa geçici
  ];

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return token.isNotEmpty;
  }

  void _onItemTapped(int index) async {
    if (index == 3) {
      // Profil sekmesi
      final loggedIn = await _isLoggedIn();
      if (!loggedIn) {
        if (!mounted) return;
        await Navigator.pushNamed(context, '/login');
        // Login dönüşünde tekrar kontrol edip sekmeye geçebilirsin
        final nowLogged = await _isLoggedIn();
        if (!nowLogged) return; // hala misafir → sekmeyi değiştirme
      }
      // Girişli ise normal akışla profile sekmesine geç
    }
    if (!mounted) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ortak AppBar YOK → “Ana Sayfa” yazısı kalktı.
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Favoriler'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Hakkında'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
