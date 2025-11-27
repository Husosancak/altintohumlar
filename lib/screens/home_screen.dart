import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_service.dart';
import '../core/local_storage.dart';
import '../models/haber.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Haber>> _haberler;
  List<String> _favoriIdler = [];

  @override
  void initState() {
    super.initState();
    _haberler = ApiService().fetchHaberler();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favs = await LocalStorage.getFavorites();
    setState(() {
      _favoriIdler = favs;
    });
  }

  void _toggleFavorite(String id) async {
    if (_favoriIdler.contains(id)) {
      _favoriIdler.remove(id);
    } else {
      _favoriIdler.add(id);
    }
    await LocalStorage.saveFavorites(_favoriIdler);
    setState(() {});
  }

  bool _isFavori(String id) => _favoriIdler.contains(id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Altın Tohumlar')),
      body: FutureBuilder<List<Haber>>(
        future: _haberler,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Veri bulunamadı.'));
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final haber = snapshot.data![index];
                final isFav = _isFavori(haber.id.toString());
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
                        SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailScreen(haber: haber),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        haber.baslik,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isFav
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFav ? Colors.red : null,
                                      ),
                                      onPressed: () =>
                                          _toggleFavorite(haber.id.toString()),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Text(haber.tarih),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (haber.videoURL != null)
                                      IconButton(
                                        icon: Image.asset(
                                            'assets/icons/tv_icon.png',
                                            width: 24),
                                        onPressed: () => launchUrl(
                                            Uri.parse(haber.videoURL!)),
                                      ),
                                    if (haber.egitimPdf != null)
                                      IconButton(
                                        icon: Image.asset(
                                            'assets/icons/pdf_icon.png',
                                            width: 24),
                                        onPressed: () => launchUrl(
                                            Uri.parse(haber.egitimPdf!)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
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
