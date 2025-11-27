import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/haber.dart';
import '../core/local_storage.dart';

class DetailScreen extends StatefulWidget {
  final Haber haber;
  const DetailScreen({Key? key, required this.haber}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  bool isFav = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    LocalStorage.isFavorite(widget.haber.id.toString()).then((value) {
      if (mounted) setState(() => isFav = value);
    });
  }

  void toggleFavorite() async {
    if (isFav) {
      await LocalStorage.removeFavorite(widget.haber.id.toString());
    } else {
      await LocalStorage.addFavorite(widget.haber.id.toString());
    }
    if (mounted) setState(() => isFav = !isFav);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // HTML içindeki inline style/color kaynaklı görünmeme sorunlarını azalt
  String _cleanHtml(String? raw) {
    if (raw == null) return '';
    var html = raw.trim();
    if (html.toLowerCase() == 'null') return '';

    // 🔧 inline flag (?i) yerine caseSensitive:false kullan
    html = html.replaceAll(
      RegExp(r'style="[^"]*"', caseSensitive: false),
      '',
    );
    html = html.replaceAll(
      RegExp(r"style='[^']*'", caseSensitive: false),
      '',
    );
    html = html.replaceAll(
      RegExp(r'color\s*:\s*#[0-9a-f]{3,6}', caseSensitive: false),
      '',
    );

    html = html.replaceAll('&nbsp;', ' ');
    return html;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bağlantı açılamadı: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final haber = widget.haber;
    final defaultTextColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(haber.baslik, maxLines: 2, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
            onPressed: toggleFavorite,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((haber.resim).isNotEmpty)
            Image.network(
              haber.resim,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Etkinlik Açıklaması'),
              Tab(text: 'Basın Yansımaları'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // --- Etkinlik Açıklaması ---
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (haber.tarih.isNotEmpty || haber.saat.isNotEmpty) ...[
                        Text(
                          "${haber.tarih}${haber.saat.isNotEmpty ? ' | ${haber.saat}' : ''}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Html(
                        data: _cleanHtml(haber.aciklama),
                        extensions: const [TableHtmlExtension()],
                        onLinkTap: (url, _, __) {
                          if (url != null) _openUrl(url);
                        },
                        style: {
                          "*": Style(
                            color: defaultTextColor,
                            fontSize: FontSize(16),
                            lineHeight: const LineHeight(1.4),
                            backgroundColor: Colors.transparent,
                          ),
                          "table": Style(
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
                          "td": Style(
                            padding: HtmlPaddings.all(6),
                            border: const Border(
                              right: BorderSide(color: Colors.black12),
                              bottom: BorderSide(color: Colors.black12),
                            ),
                          ),
                          "img": Style(margin: Margins.symmetric(vertical: 8)),
                          "p": Style(margin: Margins.only(bottom: 12)),
                          "a": Style(textDecoration: TextDecoration.underline),
                        },
                      ),
                    ],
                  ),
                ),

                // --- Basın Yansımaları ---
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: (haber.basin != null &&
                          haber.basin!.trim().isNotEmpty &&
                          haber.basin!.trim().toLowerCase() != "null")
                      ? Html(
                          data: _cleanHtml(haber.basin),
                          extensions: const [TableHtmlExtension()],
                          onLinkTap: (url, _, __) {
                            if (url != null) _openUrl(url);
                          },
                          style: {
                            "*": Style(
                              color: defaultTextColor,
                              fontSize: FontSize(16),
                              lineHeight: const LineHeight(1.4),
                              backgroundColor: Colors.transparent,
                            ),
                            "table": Style(
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
                            "td": Style(
                              padding: HtmlPaddings.all(6),
                              border: const Border(
                                right: BorderSide(color: Colors.black12),
                                bottom: BorderSide(color: Colors.black12),
                              ),
                            ),
                            "img":
                                Style(margin: Margins.symmetric(vertical: 8)),
                            "p": Style(margin: Margins.only(bottom: 12)),
                            "a":
                                Style(textDecoration: TextDecoration.underline),
                          },
                        )
                      : const Center(
                          child: Text("Basın yansımaları bulunamadı.")),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
