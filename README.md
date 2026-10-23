# Catatan Harian

Aplikasi catatan lokal berbasis Flutter dengan tema sage dan krem serta mode gelap.

## Fitur

- Tambah, edit, dan hapus catatan dengan konfirmasi.
- Cari berdasarkan judul atau isi, dengan tombol untuk membersihkan pencarian.
- Kategori Pribadi, Kuliah, Kerja, dan Ide serta filter kategori.
- Sematkan catatan penting agar selalu berada di atas, atau tampilkan hanya catatan yang disematkan.
- Empat pilihan warna kartu: Sage, Pasir, Langit, dan Rose.
- Tampilan grid atau daftar yang menyesuaikan lebar layar.
- Penghitung kata, ringkasan jumlah catatan, dan jumlah catatan hari ini.
- Konfirmasi sebelum meninggalkan perubahan yang belum disimpan.
- Tarik beranda ke bawah untuk memuat ulang catatan.
- Penyimpanan SQLite lokal dengan migrasi otomatis dari database versi lama.

Buka ikon pengaturan di kanan atas editor untuk memilih kategori, warna, dan sematan. Menu tiga titik pada kartu juga menyediakan aksi sematkan, edit, dan hapus.

## Menjalankan

Proyek ini menggunakan Flutter 3.35.5 / Dart 3.9.2. Gunakan SDK Flutter yang sama untuk pengambilan dependensi, analisis, pengujian, dan build.

```sh
flutter pub get
flutter run
```

SQLite pada konfigurasi saat ini ditujukan untuk Android, iOS, dan macOS. Web dan Windows memerlukan backend SQLite tambahan.

## Pemeriksaan

```sh
flutter analyze
flutter test
flutter build apk --debug
```

Pengujian mencakup CRUD, migrasi database lama, urutan sematan, pencarian, filter gabungan, pengaturan catatan, validasi, kegagalan penyimpanan, konfirmasi perubahan, dan tata letak layar kecil.
