import 'dart:async';

import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/note.dart';
import '../services/settings_service.dart';
import 'note_form_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isDark;
  final Future<void> Function() onToggleTheme;
  final Future<List<Note>> Function({bool newestFirst})? loadNotes;
  const HomeScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    this.loadNotes,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  bool _loading = true;
  bool _newestFirst = true;
  String _query = '';
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _newestFirst = await SettingsService.isNewestFirst().timeout(
        const Duration(seconds: 15),
      );
    } on Exception catch (error, stackTrace) {
      debugPrint('Gagal memuat pengaturan urutan: $error\n$stackTrace');
    }
    await _load();
  }

  /// Memuat catatan dari SQLite secara asinkron dan menampilkan indikator loading.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final data = await (widget.loadNotes ?? DatabaseHelper.instance.getNotes)(
        newestFirst: _newestFirst,
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _notes = data;
        _loading = false;
      });
    } on Exception catch (error, stackTrace) {
      debugPrint('Gagal memuat catatan: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _loadError = error is TimeoutException
            ? 'Waktu memuat habis. Periksa database lalu coba lagi.'
            : error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleSort() async {
    _newestFirst = !_newestFirst;
    await SettingsService.setNewestFirst(_newestFirst);
    await _load();
  }

  Future<void> _openForm([Note? note]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NoteFormScreen(note: note)),
    );
    if (saved == true) await _load();
  }

  Future<bool> _confirmDelete(Note n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('"${n.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    await DatabaseHelper.instance.delete(n.id!);
    if (!mounted) return false;
    setState(() => _notes.removeWhere((x) => x.id == n.id));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Catatan dihapus')));
    return true;
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final shown = _notes
        .where(
          (n) =>
              n.title.toLowerCase().contains(_query.toLowerCase()) ||
              n.content.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Harian'),
        actions: [
          IconButton(
            tooltip: _newestFirst ? 'Terbaru dulu' : 'Terlama dulu',
            icon: Icon(
              _newestFirst ? Icons.arrow_downward : Icons.arrow_upward,
            ),
            onPressed: _toggleSort,
          ),
          IconButton(
            tooltip: 'Ganti tema',
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari catatan...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'Gagal memuat catatan: $_loadError',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                : shown.isEmpty
                ? const Center(child: Text('Belum ada catatan'))
                : ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (_, i) {
                      final n = shown[i];
                      return Dismissible(
                        key: ValueKey(n.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDelete(n),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(
                              n.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${n.content}\n${_fmt(n.createdAt)}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isThreeLine: true,
                            onTap: () => _openForm(n),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Catatan'),
      ),
    );
  }
}
