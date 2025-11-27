import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hakkında")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Altın Tohumlar Uygulaması", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Bu uygulama İstanbul Ticaret Borsası tarafından geliştirilen ve sektörel bilgilendirme amaçlı etkinliklerin, duyuruların paylaşıldığı resmi platformdur."),
            SizedBox(height: 20),
            Text("Veri Kaynağı", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("https://apiservice.istib.org.tr/api/altintohumlar"),
            SizedBox(height: 20),
            Text("İletişim", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('''E-posta: basin@istib.org.tr
Telefon: 0 (212) 511 84 40'''),
          ],
        ),
      ),
    );
  }
}
