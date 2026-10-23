# Berkas laporan Catatan Harian

- `Laporan_Catatan_Harian_Muhammad_Alif_Mujaddid.docx`: laporan Word yang dapat diedit, 12 halaman dengan 8 screenshot tertanam.
- `Laporan_Catatan_Harian_Muhammad_Alif_Mujaddid.pdf`: salinan PDF untuk pratinjau dan pencetakan.
- `screenshots/`: delapan screenshot PNG tanpa kompresi Word.
- `Screenshots_Catatan_Harian.zip`: kumpulan screenshot terpisah.
- `hasil_analisis.txt`: hasil analisis statis Flutter.
- `hasil_pengujian.txt`: hasil 14 tes fungsional.

Sampul telah diisi atas nama Muhammad Alif Mujaddid, NIM 240605110082, UIN Maulana Malik Ibrahim Malang. Kolom kelas dan dosen pengampu masih berupa isian yang dapat dilengkapi pada Word.

Screenshot dirender dari widget aplikasi asli melalui lingkungan pengujian Flutter menggunakan data contoh. Ukuran viewport 420 x 860 piksel logis; PNG 840 x 1720 piksel. Screenshot bukan pengambilan dari perangkat Android fisik. Tidak ada data pribadi pengguna yang dimuat untuk pengambilan screenshot.

Pengambilan ulang screenshot pada lingkungan yang sama:

```sh
flutter test --no-pub tools/report_capture_test.dart
```

Harness screenshot menggunakan lokasi font SDK Flutter pada komputer pengembangan; sesuaikan lokasi tersebut jika dipindah ke komputer lain.

Skrip `tools/create_report.py` menyusun Word. `tools/render_report.py` mengekspor PDF melalui Microsoft Word dalam instance terpisah yang tidak terlihat. Dependensi Python pembuat laporan dipasang secara lokal pada `build/report_tools`, bukan ditambahkan ke dependensi aplikasi Flutter.
