import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Basit local profil deposu
class LocalProfileStore {
  static const _kKey = 'local_profile_json';

  static Future<Map<String, dynamic>?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, jsonEncode(data));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }
}

/// JWT payload'ını çözmek için yardımcı
Map<String, dynamic>? _decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    while (payload.length % 4 != 0) payload += '=';
    final decoded = utf8.decode(base64.decode(payload));
    return json.decode(decoded) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  bool _deleting = false;
  Map<String, dynamic>? _profile; // { fullName, email, avatarUrl? }

  Future<String?> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return (token != null && token.isNotEmpty) ? token : null;
  }

  Future<void> _ensureLoggedInOrRedirect() async {
    final token = await _readToken();
    if (token == null && mounted) {
      Navigator.pushNamed(context, '/login');
    }
  }

  /// Profil artık LOKALDEN okunuyor (API çağrısı yok)
  Future<void> _loadLocalProfile() async {
    try {
      final p = await LocalProfileStore.read();
      setState(() => _profile = p);
    } catch (e) {
      _showSnack('Profil yüklenirken hata: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logoutToGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await LocalProfileStore.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
    _showSnack('Çıkış yapıldı. Misafir modundasınız.');
  }

  /// Sunucuda hesabı sil; body'de e-posta gönder → misafir
  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
            'Hesabınızı kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) {
        _showSnack('Oturum bulunamadı.');
        return;
      }

      // 1) E-posta: önce lokal profil, yoksa JWT
      String? email = _profile?['email']?.toString();
      if (email == null || email.isEmpty || email == '-') {
        final payload = _decodeJwtPayload(token);
        email =
            (payload?['email'] ?? payload?['unique_name'] ?? payload?['sub'])
                ?.toString();
      }
      if (email == null || !email.contains('@')) {
        _showSnack('E-posta bulunamadı. Lütfen tekrar giriş yapın.');
        return;
      }

      // 2) İstek: POST + raw JSON string body -> "user@site.com"
      final dio = Dio(
        BaseOptions(
          validateStatus: (s) => s != null && s < 500, // 4xx'ü yakalayalım
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final res = await dio.post(
        'https://apiservice.istib.org.tr/api/Auth/deleteAccount',
        data: jsonEncode(email), // <-- DÜZ STRING JSON
      );

      if (res.statusCode == 200) {
        await prefs.remove('token');
        await LocalProfileStore.clear();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
        _showSnack('Hesabınız silindi. Misafir moduna geçildi.');
      } else {
        final body = (res.data is String) ? res.data : jsonEncode(res.data);
        _showSnack('Silme başarısız (${res.statusCode}): $body');
        if (res.statusCode == 401 && mounted) {
          Navigator.pushNamed(context, '/login');
        }
      }
    } catch (e) {
      _showSnack('Silme sırasında hata: $e');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void initState() {
    super.initState();  
    _loadLocalProfile(); // API yerine lokal okuma
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final email = _profile?['email'] ?? '-';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('E-posta'),
                  subtitle: Text(email),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Çıkış Yap'),
                  onTap: _logoutToGuest,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Hesabı Sil',
                      style: TextStyle(color: Colors.red)),
                  trailing: _deleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                  onTap: _deleting ? null : _deleteAccount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
