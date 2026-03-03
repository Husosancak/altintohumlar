import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/local_profile_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await LocalProfileStore.clear();

    if (!mounted) return;
    Navigator.pop(context);
  }

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
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Lutfen e-posta ve sifre girin.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final dio = Dio();
      final response = await dio.post(
        'https://apiservice.istib.org.tr/api/Auth/login',
        data: <String, String>{'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'] as String;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        Map<String, dynamic>? profileFromApi;
        final p = response.data['profile'];
        if (p is Map) {
          profileFromApi = Map<String, dynamic>.from(p);
        }

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

        await LocalProfileStore.save(<String, dynamic>{
          'fullName':
              (profileFromApi?['fullName'] ?? nameFromJwt ?? '').toString(),
          'email':
              (profileFromApi?['email'] ?? emailFromJwt ?? email).toString(),
          'avatarUrl': profileFromApi?['avatarUrl'],
        });

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Giris basarisiz. Bilgileri kontrol edin.')),
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        messenger.showSnackBar(
          const SnackBar(content: Text('E-posta veya sifre hatali.')),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('Baglanti hatasi: ${e.message}')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Beklenmeyen hata: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoWidth = (screenWidth * 0.36).clamp(220.0, 360.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Altın Tohumlar Giriş')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: logoWidth,
                  child: Image.asset(
                    'assets/images/splash.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hoş geldiniz',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
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
                        child: const Text('Giriş Yap'),
                      ),
                TextButton(
                  onPressed: _loginAsGuest,
                  child: const Text('Misafir olarak devam et'),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Kayıt Ol'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
