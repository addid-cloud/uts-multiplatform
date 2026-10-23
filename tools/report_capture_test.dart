import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uts/models/note.dart';
import 'package:uts/screens/home_screen.dart';
import 'package:uts/screens/note_form_screen.dart';
import 'package:uts/theme/app_theme.dart';

final demoNotes = [
  Note(
    id: 1,
    title: 'Persiapan UTS Multiplatform',
    content:
        'Pelajari widget Flutter, navigasi halaman, SQLite, dan Shared Preferences. Siapkan demo aplikasi beserta laporan.',
    category: 'Kuliah',
    isPinned: true,
    colorIndex: 0,
    createdAt: DateTime(2026, 10, 23, 9, 15),
  ),
  Note(
    id: 2,
    title: 'Ide proyek berikutnya',
    content:
        'Membuat aplikasi pengingat kegiatan dengan tampilan yang sederhana dan nyaman digunakan.',
    category: 'Ide',
    colorIndex: 1,
    createdAt: DateTime(2026, 10, 23, 8, 30),
  ),
  Note(
    id: 3,
    title: 'Rencana akhir pekan',
    content:
        'Merapikan meja belajar, membaca buku, dan menyiapkan agenda minggu depan.',
    category: 'Pribadi',
    colorIndex: 2,
    createdAt: DateTime(2026, 10, 22, 16),
  ),
];

Future<void> fonts(WidgetTester tester) async {
  await tester.runAsync(() async {
    const base = 'A:/Code/flutter/flutter/bin/cache/artifacts/material_fonts';
    for (final entry in {
      'MaterialIcons': ['materialicons-regular.otf'],
      'Roboto': [
        'roboto-regular.ttf',
        'roboto-medium.ttf',
        'roboto-bold.ttf',
        'roboto-black.ttf',
      ],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final name in entry.value) {
        loader.addFont(
          File(
            '$base/$name',
          ).readAsBytes().then((bytes) => bytes.buffer.asByteData()),
        );
      }
      await loader.load();
    }
  });
}

Future<GlobalKey> mount(
  WidgetTester tester,
  Widget screen, {
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(420, 860);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // Harness dokumentasi ini dijalankan melalui flutter test.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  await fonts(tester);
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(dark ? Brightness.dark : Brightness.light),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

HomeScreen home({bool dark = false}) => HomeScreen(
  isDark: dark,
  onToggleTheme: () async {},
  loadNotes: ({bool newestFirst = true}) async => demoNotes,
);

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await boundary.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    await File(
      'laporan/screenshots/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    img.dispose();
  });
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('report home light', (tester) async {
    final key = await mount(tester, home());
    await capture(tester, key, '01_beranda_terang');
  });
  testWidgets('report home dark', (tester) async {
    final key = await mount(tester, home(dark: true), dark: true);
    await capture(tester, key, '02_beranda_gelap');
  });
  testWidgets('report editor', (tester) async {
    final key = await mount(tester, NoteFormScreen(note: demoNotes.first));
    await capture(tester, key, '03_editor_catatan');
  });
  testWidgets('report options', (tester) async {
    final key = await mount(tester, NoteFormScreen(note: demoNotes.first));
    await tester.tap(find.byTooltip('Atur catatan'));
    await tester.pumpAndSettle();
    await capture(tester, key, '04_pengaturan_catatan');
  });
  testWidgets('report search', (tester) async {
    final key = await mount(tester, home());
    await tester.enterText(find.byType(TextField), 'UTS');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await capture(tester, key, '05_pencarian');
  });
  testWidgets('report category and pin', (tester) async {
    final key = await mount(tester, home());
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Kuliah'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Kuliah'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Disematkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Disematkan'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 900));
    await tester.pumpAndSettle();
    await capture(tester, key, '06_filter_kategori_sematan');
  });
  testWidgets('report validation', (tester) async {
    final key = await mount(tester, const NoteFormScreen());
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await capture(tester, key, '07_validasi_form');
  });
  testWidgets('report delete confirmation', (tester) async {
    final key = await mount(tester, home());
    final menu = find.byTooltip('Opsi catatan').first;
    await tester.ensureVisible(menu);
    await tester.pumpAndSettle();
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus catatan'));
    await tester.pumpAndSettle();
    await capture(tester, key, '08_konfirmasi_hapus');
  });
}
