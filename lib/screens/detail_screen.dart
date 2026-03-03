import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_events.dart';
import '../core/event_plan_storage.dart';
import '../core/local_storage.dart';
import '../models/haber.dart';

class DetailScreen extends StatefulWidget {
  final Haber haber;
  const DetailScreen({super.key, required this.haber});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  bool isFav = false;
  late final TabController _tabController;
  final TextEditingController _noteController = TextEditingController();

  bool _savingNote = false;
  bool _noteLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorite();
    _loadNote();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorite() async {
    final value = await LocalStorage.isFavorite(widget.haber.id.toString());
    if (mounted) setState(() => isFav = value);
  }

  Future<void> _loadNote() async {
    final plan = await EventPlanStorage.readById(widget.haber.id.toString());
    if (!mounted) return;
    setState(() {
      _noteController.text = (plan?['note'] as String?) ?? '';
      _noteLoaded = true;
    });
  }

  Future<void> _saveNote({required bool showMessage}) async {
    if (_savingNote) return;
    setState(() => _savingNote = true);

    await EventPlanStorage.upsert(
      haber: widget.haber,
      status: 'none',
      note: _noteController.text,
    );
    AppEvents.notifyNotesChanged();

    if (!mounted) return;
    setState(() => _savingNote = false);
    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not kaydedildi.')),
      );
    }
  }

  Future<void> _clearNote() async {
    if (_savingNote) return;
    await EventPlanStorage.remove(widget.haber.id.toString());
    AppEvents.notifyNotesChanged();
    if (!mounted) return;
    setState(() => _noteController.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Not silindi.')),
    );
  }

  Future<void> _toggleFavorite() async {
    if (isFav) {
      await LocalStorage.removeFavorite(widget.haber.id.toString());
    } else {
      await LocalStorage.addFavorite(widget.haber.id.toString());
    }
    AppEvents.notifyFavoritesChanged();
    if (mounted) setState(() => isFav = !isFav);
  }

  String _cleanHtml(String? raw) {
    if (raw == null) return '';
    var html = raw.trim();
    if (html.toLowerCase() == 'null') return '';
    html = html.replaceAll(RegExp(r'style="[^"]*"', caseSensitive: false), '');
    html = html.replaceAll(RegExp(r"style='[^']*'", caseSensitive: false), '');
    html = html.replaceAll(
      RegExp(r'color\s*:\s*#[0-9a-f]{3,6}', caseSensitive: false),
      '',
    );
    return html.replaceAll('&nbsp;', ' ');
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Baglanti acilamadi: $url')),
      );
    }
  }

  Map<String, Style> _htmlStyle(Color defaultTextColor) {
    return <String, Style>{
      '*': Style(
        color: defaultTextColor,
        fontSize: FontSize(16),
        lineHeight: const LineHeight(1.4),
        backgroundColor: Colors.transparent,
      ),
      'table': Style(
        width: Width.auto(),
        margin: Margins.symmetric(vertical: 8),
        padding: HtmlPaddings.all(6),
        border: const Border(
          top: BorderSide(color: Colors.black12),
          right: BorderSide(color: Colors.black12),
          bottom: BorderSide(color: Colors.black12),
          left: BorderSide(color: Colors.black12),
        ),
      ),
      'td': Style(
        padding: HtmlPaddings.all(6),
        border: const Border(
          right: BorderSide(color: Colors.black12),
          bottom: BorderSide(color: Colors.black12),
        ),
      ),
      'img': Style(margin: Margins.symmetric(vertical: 8)),
      'p': Style(margin: Margins.only(bottom: 12)),
      'a': Style(textDecoration: TextDecoration.underline),
    };
  }

  Widget _buildNotesPanel() {
    if (!_noteLoaded) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Notlarim',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Kisa bir not ekleyin...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: _savingNote
                      ? null
                      : () {
                          _saveNote(showMessage: true);
                        },
                  icon: _savingNote
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Notu kaydet'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _savingNote ? null : _clearNote,
                  child: const Text('Temizle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedContent(Haber haber, Color defaultTextColor) {
    if (_tabController.index == 1) {
      if (haber.basin != null &&
          haber.basin!.trim().isNotEmpty &&
          haber.basin!.trim().toLowerCase() != 'null') {
        return Html(
          data: _cleanHtml(haber.basin),
          extensions: const <HtmlExtension>[TableHtmlExtension()],
          onLinkTap: (url, _, __) {
            if (url != null) _openUrl(url);
          },
          style: _htmlStyle(defaultTextColor),
        );
      }
      return const Text('Basin yansimalari bulunamadi.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (haber.tarih.isNotEmpty || haber.saat.isNotEmpty) ...<Widget>[
          Text(
            '${haber.tarih}${haber.saat.isNotEmpty ? ' | ${haber.saat}' : ''}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
        ],
        Html(
          data: _cleanHtml(haber.aciklama),
          extensions: const <HtmlExtension>[TableHtmlExtension()],
          onLinkTap: (url, _, __) {
            if (url != null) _openUrl(url);
          },
          style: _htmlStyle(defaultTextColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final haber = widget.haber;
    final defaultTextColor = Theme.of(context).colorScheme.onSurface;
    final screenSize = MediaQuery.sizeOf(context);
    final isLandscape = screenSize.width > screenSize.height;
    final imageHeight = isLandscape
        ? (screenSize.height * 0.48).clamp(260.0, 440.0)
        : (screenSize.width * 0.56).clamp(180.0, 360.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(haber.baslik, maxLines: 2, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (haber.resim.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: imageHeight,
                child: Image.network(
                  haber.resim,
                  width: double.infinity,
                  height: imageHeight,
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            _buildNotesPanel(),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              onTap: (_) => setState(() {}),
              tabs: const <Tab>[
                Tab(text: 'Etkinlik Aciklamasi'),
                Tab(text: 'Basin Yansimalari'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSelectedContent(haber, defaultTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
