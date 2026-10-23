import 'dart:async';

import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
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
  bool _grid = true;
  String _category = 'Semua';
  bool _pinnedOnly = false;
  final Set<int> _pinning = {};
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
    if (mounted) await _load();
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
    if (saved == true && mounted) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan berhasil disimpan')),
      );
    }
  }

  Future<void> _togglePin(Note note) async {
    if (note.id == null || _pinning.contains(note.id)) return;
    setState(() => _pinning.add(note.id!));
    final updated = note.copyWith(isPinned: !note.isPinned);
    try {
      await DatabaseHelper.instance
          .update(updated)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        final index = _notes.indexWhere((item) => item.id == note.id);
        if (index >= 0) _notes[index] = updated;
      });
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status sematan belum tersimpan. Coba lagi.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pinning.remove(note.id));
    }
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
    try {
      await DatabaseHelper.instance
          .delete(n.id!)
          .timeout(const Duration(seconds: 15));
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan belum berhasil dihapus. Coba lagi.'),
          ),
        );
      }
      return false;
    }
    if (!mounted) return false;
    setState(() => _notes.removeWhere((x) => x.id == n.id));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Catatan dihapus')));
    return true;
  }

  String _fmt(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final query = _query.trim().toLowerCase();
    final shown =
        _notes
            .where(
              (note) =>
                  (note.title.toLowerCase().contains(query) ||
                      note.content.toLowerCase().contains(query)) &&
                  (_category == 'Semua' || note.category == _category) &&
                  (!_pinnedOnly || note.isPinned),
            )
            .toList()
          ..sort((a, b) {
            if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
            return _newestFirst
                ? b.createdAt.compareTo(a.createdAt)
                : a.createdAt.compareTo(b.createdAt);
          });
    final hasFilter = query.isNotEmpty || _category != 'Semua' || _pinnedOnly;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                color: colors.onPrimary,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catatan Harian',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.6,
                    ),
                  ),
                  Text(
                    'Ruang kecil untuk ide besar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Ganti tema',
            icon: Icon(
              widget.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 21,
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _hero(colors),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _search,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search_rounded),
                              hintText: 'Cari ide, cerita, atau catatan...',
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Hapus pencarian',
                                      onPressed: () {
                                        _search.clear();
                                        setState(() => _query = '');
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                            ),
                            onChanged: (value) =>
                                setState(() => _query = value),
                          ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                FilterChip(
                                  avatar: const Icon(
                                    Icons.push_pin_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Disematkan'),
                                  selected: _pinnedOnly,
                                  onSelected: (value) =>
                                      setState(() => _pinnedOnly = value),
                                ),
                                const SizedBox(width: 12),
                                ...['Semua', ...Note.categories].map(
                                  (category) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(category),
                                      selected: _category == category,
                                      onSelected: (_) =>
                                          setState(() => _category = category),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      query.isEmpty
                                          ? 'Koleksi catatan'
                                          : 'Hasil pencarian',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${shown.length} catatan',
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: _newestFirst
                                    ? 'Terbaru dulu'
                                    : 'Terlama dulu',
                                onPressed: _loading ? null : _toggleSort,
                                icon: Icon(
                                  _newestFirst
                                      ? Icons.south_rounded
                                      : Icons.north_rounded,
                                  size: 20,
                                ),
                              ),
                              IconButton.filledTonal(
                                tooltip: _grid
                                    ? 'Tampilan daftar'
                                    : 'Tampilan grid',
                                onPressed: () => setState(() => _grid = !_grid),
                                icon: Icon(
                                  _grid
                                      ? Icons.view_agenda_outlined
                                      : Icons.grid_view_rounded,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                  if (_loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_loadError != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _emptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Catatan belum bisa dimuat',
                        message: 'Gagal memuat catatan: $_loadError',
                        action: FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba lagi'),
                        ),
                      ),
                    )
                  else if (shown.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _emptyState(
                        icon: !hasFilter
                            ? Icons.edit_note_rounded
                            : Icons.search_off_rounded,
                        title: !hasFilter
                            ? 'Belum ada catatan'
                            : 'Catatan tidak ditemukan',
                        message: !hasFilter
                            ? 'Setiap cerita dimulai dari satu kata.\nYuk, tulis catatan pertamamu hari ini.'
                            : 'Coba kata kunci atau kategori lain untuk menemukan catatanmu.',
                        action: !hasFilter
                            ? TextButton.icon(
                                onPressed: () => _openForm(),
                                icon: const Icon(Icons.add),
                                label: const Text('Tulis catatan pertama'),
                              )
                            : TextButton(
                                onPressed: () {
                                  _search.clear();
                                  setState(() {
                                    _query = '';
                                    _category = 'Semua';
                                    _pinnedOnly = false;
                                  });
                                },
                                child: const Text('Reset filter'),
                              ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final columns = !_grid
                              ? 1
                              : constraints.crossAxisExtent >= 850
                              ? 3
                              : constraints.crossAxisExtent >= 520
                              ? 2
                              : 1;
                          return SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisExtent: _grid ? 238 : 186,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _noteCard(shown[index]),
                              childCount: shown.length,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tulis catatan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _hero(ColorScheme colors) {
    final today = DateTime.now();
    final todayCount = _notes
        .where(
          (n) =>
              n.createdAt.year == today.year &&
              n.createdAt.month == today.month &&
              n.createdAt.day == today.day,
        )
        .length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF284638)
            : const Color(0xFFE4ECDD),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny_outlined, size: 16, color: colors.primary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _fmt(today),
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.spa_outlined, color: colors.primary, size: 28),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Ide kecil hari ini,\ncerita besar esok hari.',
            style: TextStyle(
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Simpan pikiranmu. Beri ruang untuk hal baru.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              height: 1.5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _stat(
                Icons.layers_outlined,
                '${_notes.length} catatan tersimpan',
                colors,
              ),
              _stat(
                Icons.edit_outlined,
                '$todayCount ditulis hari ini',
                colors,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String text, ColorScheme colors) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: colors.surface.withValues(alpha: .65),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 36, color: colors.onPrimaryContainer),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.6),
          ),
          if (action != null) ...[const SizedBox(height: 12), action],
        ],
      ),
    );
  }

  Widget _noteCard(Note note) {
    final color = (widget.isDark
        ? AppTheme.darkNoteColors
        : AppTheme.noteColors)[note.colorIndex % AppTheme.noteColors.length];
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openForm(note),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    note.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.description_outlined,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _fmt(note.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Opsi catatan',
                    icon: const Icon(Icons.more_horiz_rounded, size: 21),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openForm(note);
                      } else if (value == 'pin') {
                        _togglePin(note);
                      } else {
                        _confirmDelete(note);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit catatan'),
                      ),
                      PopupMenuItem(
                        enabled: !_pinning.contains(note.id),
                        value: 'pin',
                        child: Text(
                          note.isPinned ? 'Lepas sematan' : 'Sematkan catatan',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus catatan'),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 9),
              Expanded(
                child: Text(
                  note.content,
                  maxLines: _grid ? 4 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.65,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${note.category} ? ${note.content.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} kata',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 17,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
