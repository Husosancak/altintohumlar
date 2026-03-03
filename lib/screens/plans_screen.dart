import 'package:flutter/material.dart';

import '../core/api_service.dart';
import '../core/app_events.dart';
import '../core/event_plan_storage.dart';
import '../models/haber.dart';
import 'detail_screen.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  bool _loading = true;
  String? _errorMessage;
  List<_NoteEntry> _entries = <_NoteEntry>[];

  @override
  void initState() {
    super.initState();
    AppEvents.notesVersion.addListener(_onNotesChanged);
    _loadNotes();
  }

  @override
  void dispose() {
    AppEvents.notesVersion.removeListener(_onNotesChanged);
    super.dispose();
  }

  void _onNotesChanged() {
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        ApiService().fetchHaberler(),
        EventPlanStorage.readAll(),
      ]);

      final allEvents = List<Haber>.from(results[0] as List<Haber>);
      final notesMap =
          Map<String, dynamic>.from(results[1] as Map<String, dynamic>);
      final eventById = <String, Haber>{
        for (final item in allEvents) item.id.toString(): item,
      };

      final entries = <_NoteEntry>[];

      notesMap.forEach((key, value) {
        if (value is! Map<String, dynamic>) return;

        final note = value['note']?.toString() ?? '';
        if (note.trim().isEmpty) return;

        final updatedAtRaw = value['updatedAt']?.toString() ?? '';
        final updatedAt = DateTime.tryParse(updatedAtRaw) ?? DateTime(1970);

        entries.add(
          _NoteEntry(
            eventId: key,
            note: note,
            title: value['title']?.toString() ?? 'Etkinlik',
            date: value['date']?.toString() ?? '-',
            time: value['time']?.toString() ?? '-',
            updatedAt: updatedAt,
            haber: eventById[key],
          ),
        );
      });

      entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Notlar yuklenemedi.';
      });
    }
  }

  Future<void> _removeEntry(String eventId) async {
    await EventPlanStorage.remove(eventId);
    AppEvents.notifyNotesChanged();
    await _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notlarim')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadNotes,
                        child: const Text('Tekrar dene'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotes,
                  child: _entries.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const <Widget>[
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'Henuz not eklenmemis.\nDetay ekraninda not birakabilirsiniz.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            final title = entry.haber?.baslik ?? entry.title;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _removeEntry(entry.eventId),
                                          icon:
                                              const Icon(Icons.delete_outline),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${entry.date} | ${entry.time}'),
                                    const SizedBox(height: 10),
                                    Text(
                                      entry.note,
                                      style: TextStyle(
                                          color: Colors.grey.shade800),
                                    ),
                                    if (entry.haber != null) ...<Widget>[
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => DetailScreen(
                                                    haber: entry.haber!),
                                              ),
                                            ).then((_) => _loadNotes());
                                          },
                                          icon: const Icon(Icons.open_in_new),
                                          label: const Text('Detaya git'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

class _NoteEntry {
  final String eventId;
  final String note;
  final String title;
  final String date;
  final String time;
  final DateTime updatedAt;
  final Haber? haber;

  _NoteEntry({
    required this.eventId,
    required this.note,
    required this.title,
    required this.date,
    required this.time,
    required this.updatedAt,
    required this.haber,
  });
}
