import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_events.dart';
import '../core/api_service.dart';
import '../core/local_storage.dart';
import '../models/haber.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Haber> _allHaberler = <Haber>[];
  List<String> _favoriIdler = <String>[];
  bool _loading = true;
  String? _errorMessage;
  String _sort = 'date_desc';

  @override
  void initState() {
    super.initState();
    AppEvents.favoritesVersion.addListener(_syncFavoritesFromStorage);
    _refreshAll(showLoading: true);
  }

  @override
  void dispose() {
    AppEvents.favoritesVersion.removeListener(_syncFavoritesFromStorage);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        ApiService().fetchHaberler(),
        LocalStorage.getFavorites(),
      ]);

      if (!mounted) return;
      setState(() {
        _allHaberler = List<Haber>.from(results[0] as List<Haber>);
        _favoriIdler = List<String>.from(results[1] as List<String>);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Veriler yüklenemedi. Lütfen tekrar deneyin.';
      });
    }
  }

  void _toggleFavorite(String id) async {
    if (_favoriIdler.contains(id)) {
      _favoriIdler.remove(id);
    } else {
      _favoriIdler.add(id);
    }
    await LocalStorage.saveFavorites(_favoriIdler);
    AppEvents.notifyFavoritesChanged();
    if (!mounted) return;
    setState(() {});
  }

  void _syncFavoritesFromStorage() {
    LocalStorage.getFavorites().then((favs) {
      if (!mounted) return;
      setState(() {
        _favoriIdler = favs;
      });
    });
  }

  bool _isFavori(String id) => _favoriIdler.contains(id);

  DateTime? _parseDate(String raw) {
    final parts = raw.split('.');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;

    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  // Türkçe karakterleri normalize ederek arama kutusunda daha tutarlı eşleşme sağlar.
  String _normalizeForSearch(String value) {
    final lower = value.toLowerCase();
    return lower
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
  }

  List<Haber> _visibleHaberler() {
    final query = _normalizeForSearch(_searchController.text.trim());

    final filtered = _allHaberler.where((haber) {
      if (query.isEmpty) return true;

      final haystack = <String>[
        haber.baslik,
        haber.aciklama,
        haber.tarih,
        haber.saat,
      ].join(' ');
      final normalizedHaystack = _normalizeForSearch(haystack);
      return normalizedHaystack.contains(query);
    }).toList();

    filtered.sort((a, b) {
      if (_sort == 'title_asc') {
        return _normalizeForSearch(a.baslik).compareTo(
          _normalizeForSearch(b.baslik),
        );
      }

      final da = _parseDate(a.tarih);
      final db = _parseDate(b.tarih);
      final fallback = _normalizeForSearch(a.baslik).compareTo(
        _normalizeForSearch(b.baslik),
      );

      if (da == null && db == null) return fallback;
      if (da == null) return 1;
      if (db == null) return -1;

      if (_sort == 'date_asc') return da.compareTo(db);
      return db.compareTo(da);
    });

    return filtered;
  }

  Widget _buildHeaderControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Etkinlik ara...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey<String>('sort_$_sort'),
            initialValue: _sort,
            decoration: const InputDecoration(
              labelText: 'Sıralama',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem(value: 'date_desc', child: Text('Tarih (yeni)')),
              DropdownMenuItem(value: 'date_asc', child: Text('Tarih (eski)')),
              DropdownMenuItem(value: 'title_asc', child: Text('Başlık (A-Z)')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _sort = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Haber> visible) {
    return RefreshIndicator(
      onRefresh: () => _refreshAll(showLoading: false),
      child: visible.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const <Widget>[
                SizedBox(height: 120),
                Center(child: Text('Aramaya uygun etkinlik bulunamadı.')),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final haber = visible[index];
                final isFav = _isFavori(haber.id.toString());

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            haber.resim,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        haber.baslik,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                const SizedBox(height: 6),
                                Text('${haber.tarih} | ${haber.saat}'),
                                const SizedBox(height: 8),
                                Row(
                                  children: <Widget>[
                                    if (haber.videoURL != null)
                                      IconButton(
                                        icon: Image.asset(
                                          'assets/icons/tv_icon.png',
                                          width: 24,
                                        ),
                                        onPressed: () => launchUrl(
                                            Uri.parse(haber.videoURL!)),
                                      ),
                                    if (haber.egitimPdf != null)
                                      IconButton(
                                        icon: Image.asset(
                                          'assets/icons/pdf_icon.png',
                                          width: 24,
                                        ),
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
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleHaberler();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Altın Tohumlar'),
      ),
      body: Column(
        children: <Widget>[
          _buildHeaderControls(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(_errorMessage!),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _refreshAll(showLoading: true),
                              child: const Text('Tekrar dene'),
                            ),
                          ],
                        ),
                      )
                    : _buildList(visible),
          ),
        ],
      ),
    );
  }
}
