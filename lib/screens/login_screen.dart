import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/local_profile_store.dart'; // <= yolunu kendi yapına göre ayarla

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  void _loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await LocalProfileStore.clear();

    if (!mounted) return;
    Navigator.pop(context); // Login’i kapat, altta zaten Ana Sayfa var
  }

  // JWT payload'ından e-posta/isim çekmek için küçük yardımcı
  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64.decode(payload));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen e-posta ve şifre girin.")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final dio = Dio();
      final response = await dio.post(
        'https://apiservice.istib.org.tr/api/Auth/login',
        data: {"email": email, "password": password},
      );

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'] as String;

        // 1) Token'ı kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        // 2) Lokal profili yaz
        // 2a) API profil döndüyse onu kullan
        Map<String, dynamic>? profileFromApi;
        final p = response.data['profile'];
        if (p is Map) {
          profileFromApi = Map<String, dynamic>.from(p as Map);
        }

        // 2b) Yoksa JWT'ten e-posta/isim çöz
        String? emailFromJwt;
        String? nameFromJwt;
        if (profileFromApi == null) {
          final payload = _decodeJwtPayload(token);
          emailFromJwt =
              (payload?['email'] ?? payload?['unique_name'] ?? payload?['sub'])
                  ?.toString();
          nameFromJwt = (payload?['name'] ??
                  payload?['given_name'] ??
                  payload?['fullName'])
              ?.toString();
        }

        await LocalProfileStore.save({
          'fullName':
              (profileFromApi?['fullName'] ?? nameFromJwt ?? '').toString(),
          'email':
              (profileFromApi?['email'] ?? emailFromJwt ?? email).toString(),
          'avatarUrl': profileFromApi?['avatarUrl'],
        });

        // 3) Ana sayfa
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Giriş başarısız. Bilgilerinizi kontrol edin.")),
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("E-posta veya şifre hatalı.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bağlantı hatası: ${e.message}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Beklenmeyen hata: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Altın Tohumlar Giriş")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Hoş geldiniz",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-posta'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre'),
            ),
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _loginWithEmail,
                    child: const Text("Giriş Yap"),
                  ),
            TextButton(
              onPressed: _loginAsGuest,
              child: const Text("Misafir olarak devam et"),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text("Kayıt Ol"),
            ),
          ],
        ),
      ),
    );
  }
}
