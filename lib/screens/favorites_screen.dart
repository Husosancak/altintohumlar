import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_service.dart';
import '../core/local_storage.dart';
import '../models/haber.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  FavoritesScreenState createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> {
  Future<List<Haber>>? _favoriler;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final all = await ApiService().fetchHaberler();
    final favIds = await LocalStorage.getFavorites();
    final favItems =
        all.where((h) => favIds.contains(h.id.toString())).toList();
    setState(() {
      _favoriler = Future.value(favItems);
    });
  }

  void _removeFromFavorites(String id) async {
    await LocalStorage.removeFavorite(id);
    await _loadFavorites(); // Listeyi güncelle
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Favoriler')),
      body: FutureBuilder<List<Haber>>(
        future: _favoriler,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text(''));
          } else {
            final haberler = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: haberler.length,
              itemBuilder: (context, index) {
                final haber = haberler[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Image.network(
                          haber.resim,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      haber.baslik,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.favorite,
                                        color: Colors.red),
                                    onPressed: () => _removeFromFavorites(
                                        haber.id.toString()),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(haber.tarih),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (haber.videoURL != null)
                                    IconButton(
                                      icon: Image.asset(
                                          'assets/icons/tv_icon.png',
                                          width: 24),
                                      onPressed: () =>
                                          launchUrl(Uri.parse(haber.videoURL!)),
                                    ),
                                  if (haber.egitimPdf != null)
                                    IconButton(
                                      icon: Image.asset(
                                          'assets/icons/pdf_icon.png',
                                          width: 24),
                                      onPressed: () => launchUrl(
                                          Uri.parse(haber.egitimPdf!)),
                                    ),
                                  if (haber.basin != null)
                                    IconButton(
                                      icon: Image.asset(
                                          'assets/icons/earsiv1.png',
                                          width: 24),
                                      onPressed: () =>
                                          launchUrl(Uri.parse(haber.basin!)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
