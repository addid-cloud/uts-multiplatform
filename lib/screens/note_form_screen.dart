import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

class NoteFormScreen extends StatefulWidget {
  final Note? note;
  final Future<void> Function(Note note)? onSave;
  const NoteFormScreen({super.key, this.note, this.onSave});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.note?.title);
  late final _content = TextEditingController(text: widget.note?.content);
  bool _saving = false;
  bool _allowPop = false;
  late String _category = widget.note?.category ?? Note.categories.first;
  late int _colorIndex =
      (widget.note?.colorIndex ?? 0) % AppTheme.noteColors.length;
  late bool _isPinned = widget.note?.isPinned ?? false;

  bool get _dirty =>
      _title.text != (widget.note?.title ?? '') ||
      _content.text != (widget.note?.content ?? '') ||
      _category != (widget.note?.category ?? Note.categories.first) ||
      _colorIndex != (widget.note?.colorIndex ?? 0) ||
      _isPinned != (widget.note?.isPinned ?? false);

  Future<void> _showOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Atur catatan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                const Text('Kategori'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: Note.categories
                      .map(
                        (category) => ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          onSelected: (_) {
                            setState(() => _category = category);
                            updateSheet(() {});
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                const Text('Warna kartu'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  children: List.generate(
                    AppTheme.noteColors.length,
                    (index) => Tooltip(
                      message: AppTheme.colorNames[index],
                      child: Semantics(
                        selected: _colorIndex == index,
                        button: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() => _colorIndex = index);
                            updateSheet(() {});
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.noteColors[index],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _colorIndex == index
                                    ? AppTheme.green
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: _colorIndex == index
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: AppTheme.green,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sematkan catatan'),
                  subtitle: const Text('Selalu tampil di bagian atas koleksi'),
                  value: _isPinned,
                  onChanged: (value) {
                    setState(() => _isPinned = value);
                    updateSheet(() {});
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Selesai'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestLeave() async {
    if (_saving) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tinggalkan catatan?'),
        content: const Text(
          'Perubahanmu belum disimpan. Tetap menulis atau tinggalkan perubahan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tetap menulis'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tinggalkan'),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  /// Menyimpan (insert/update) ke SQLite secara asinkron.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final note = Note(
      id: widget.note?.id,
      title: _title.text.trim(),
      content: _content.text.trim(),
      createdAt: widget.note?.createdAt,
      category: _category,
      colorIndex: _colorIndex,
      isPinned: _isPinned,
    );
    try {
      final onSave = widget.onSave;
      if (onSave != null) {
        await onSave(note).timeout(const Duration(seconds: 15));
      } else if (widget.note == null) {
        await DatabaseHelper.instance
            .insert(note)
            .timeout(const Duration(seconds: 15));
      } else {
        await DatabaseHelper.instance
            .update(note)
            .timeout(const Duration(seconds: 15));
      }
    } on Exception catch (error, stackTrace) {
      debugPrint('Gagal menyimpan catatan: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _saving = false);
      final message = error is TimeoutException
          ? 'Penyimpanan terlalu lama. Kembali ke daftar untuk memeriksa catatan.'
          : 'Gagal menyimpan catatan: $error';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final words = _content.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    return PopScope(
      canPop: _allowPop || (!_dirty && !_saving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.note == null ? 'Catatan Baru' : 'Edit Catatan',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              tooltip: 'Atur catatan',
              onPressed: _saving ? null : _showOptions,
              icon: Icon(Icons.tune_rounded, color: colors.primary),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: SizedBox(
                      height: math.max(460, constraints.maxHeight),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _isPinned
                                          ? '$_category · Disematkan'
                                          : _category,
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$words kata',
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppTheme.darkNoteColors
                                      : AppTheme.noteColors)[_colorIndex],
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: colors.outlineVariant.withValues(
                                      alpha: .5,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _title,
                                      enabled: !_saving,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      style: const TextStyle(
                                        fontSize: 27,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -.7,
                                      ),
                                      decoration: const InputDecoration(
                                        filled: false,
                                        hintText: 'Beri judul ceritamu...',
                                        labelText: 'Judul',
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                          ? 'Judul wajib diisi'
                                          : null,
                                    ),
                                    const Divider(height: 30),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _content,
                                        enabled: !_saving,
                                        maxLines: null,
                                        expands: true,
                                        textAlignVertical:
                                            TextAlignVertical.top,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          height: 1.8,
                                        ),
                                        decoration: const InputDecoration(
                                          filled: false,
                                          labelText: 'Isi catatan',
                                          hintText:
                                              'Apa yang ada di pikiranmu hari ini?',
                                          alignLabelWithHint: true,
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        onChanged: (_) => setState(() {}),
                                        validator: (value) =>
                                            value == null ||
                                                value.trim().isEmpty
                                            ? 'Isi wajib diisi'
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 13,
                                  color: colors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Disimpan lokal di perangkatmu',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _saving ? null : _save,
                                icon: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(
                                  _saving ? 'Menyimpan...' : 'Simpan',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
