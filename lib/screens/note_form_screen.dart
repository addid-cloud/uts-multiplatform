import 'dart:async';

import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/note.dart';

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
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Catatan Baru' : 'Edit Catatan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Judul wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextFormField(
                  controller: _content,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'Isi catatan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Isi wajib diisi'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
