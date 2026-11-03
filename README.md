# AllerScan - Food Allergen Detector (Android First)

AllerScan adalah aplikasi mobile Android & iOS (dibangun dengan Flutter) untuk mendeteksi bahan pemicu alergi pada label komposisi makanan kemasan secara **100% offline di perangkat**. Aplikasi ini mengutamakan ketelitian medis, kejelasan klinis, dan kejujuran UI tanpa ketergantungan pada API backend atau internet.

---

## 🚀 Cara Menjalankan

### 1. Menjalankan Aplikasi Flutter (Android / iOS)
Pastikan Flutter SDK (>= 3.10.0) dan Android Studio / Xcode sudah terpasang.

```bash
# 1. Unduh / pasang dependensi
flutter pub get

# 2. Jalankan tes unit allergen matcher
flutter test test/allergen_matcher_test.dart

# 3. Jalankan aplikasi pada emulator atau perangkat fisik Android
flutter run
```

### 2. Menjalankan Web Preview / Simulator Interaktif
Aplikasi ini juga dilengkapi dengan simulator interaktif web berbasis React SPA + TypeScript di port 3000:

```bash
npm install
npm run build
```

---

## 📁 Struktur Proyek

```
allerscan/
├── android/
│   └── app/src/main/AndroidManifest.xml    # Izin CAMERA & READ_MEDIA_IMAGES
├── assets/
│   └── allergens.json                     # Kamus 8 alergen utama + sinonim + ambiguous
├── lib/
│   ├── main.dart                          # Inisialisasi provider, storage & bottom navigation
│   ├── theme/
│   │   └── app_theme.dart                 # ThemeData & ColorScheme (Clinical Clarity, Inter font)
│   ├── models/
│   │   ├── allergen_profile.dart          # Model AllergenDef & kustomisasi pengguna
│   │   └── scan_result.dart               # Model ScanResult, AllergenFinding, & RiskLevel
│   ├── services/
│   │   ├── allergen_matcher.dart          # Pure Dart: normalisasi, Levenshtein, word boundary, trace
│   │   ├── ocr_service.dart               # Abstraksi IOcrService & implementasi Google ML Kit
│   │   └── storage_service.dart           # SharedPreferences untuk profil & riwayat lokal
│   ├── providers/
│   │   ├── profile_provider.dart          # State management profil & alergen aktif
│   │   └── history_provider.dart          # State management riwayat hasil scan
│   ├── screens/
│   │   ├── profile_screen.dart            # Layar 1: Profil Alergen (Langkah 1/3) & Custom Allergen
│   │   ├── input_method_screen.dart       # Layar 2: Pilih Metode Input (Kamera vs Manual)
│   │   ├── camera_screen.dart             # Layar 3: Kamera Pemindai (Panduan OCR & ImagePicker)
│   │   ├── manual_input_screen.dart       # Layar 4: Ketik Manual (2000 Karakter & Quick Insert)
│   │   ├── analyzing_screen.dart          # Layar 5: Proses Analisis (Radar Animation & Steps)
│   │   ├── result_screen.dart             # Layar 6/7/8: SATU Widget ResultScreen (Tinggi/Sedang/Aman)
│   │   └── history_screen.dart            # Layar 9: Riwayat Scan & Filter Kategori
│   └── widgets/
│       └── app_bottom_nav.dart            # Bottom navigation: Scan, Riwayat, Profil
├── test/
│   └── allergen_matcher_test.dart         # Unit test 6 kasus uji utama
└── pubspec.yaml                           # Konfigurasi dependensi Flutter
```

---

## 🔍 Logika Inti & Cara Kerja Matcher (`allergen_matcher.dart`)

1. **Normalisasi Teks**:
   - Teks diubah ke huruf kecil (*lowercase*).
   - Koreksi salah baca OCR umum: `|` diubah ke `l`, `0` di antara huruf alfabet diubah ke `o` (misal `c0ntains` → `contains`), dan `1` diubah ke `i` bila relevan.
   - Perapian spasi dan pembersihan karakter pemisah.

2. **Pemisahan Klausul Jejak Produksi**:
   - Sistem mendeteksi frasa penanda jejak/kontaminasi silang pabrik seperti *"mungkin mengandung"*, *"may contain"*, *"contains traces"*, *"diproduksi di fasilitas"*, *"diproses pada peralatan yang sama"*, dll.
   - Teks sebelum frasa diklasifikasikan sebagai `mainText` (komposisi utama).
   - Teks setelah frasa diklasifikasikan sebagai `traceText` (jejak produksi).

3. **Pencocokan Kata Kunci Berbatas Kata (*Word Boundary*)**:
   - Menghindari *false positive* (contoh: kata "susu" tidak akan cocok sembarangan di dalam kata lain).
   - Kata ambigu seperti *"kacang"* hanya memicu risiko **SEDANG** dengan keterangan "jenis kacang tidak jelas". Jika diikuti oleh kacang non-tanah (misal *"kacang almond"*, *"kacang hijau"*, *"kacang mete"*), pencocokan kacang tanah **TIDAK** dipicu.

4. **Fuzzy Matching Levenshtein Distance 1**:
   - Untuk kata kunci dengan panjang $\ge 6$ karakter, sistem mentolerir 1 kesalahan karakter (contoh: salah baca OCR `"kaseln"` tetap cocok dengan `"kasein"`).
   - Kata kunci pendek ($< 6$ karakter) wajib cocok persis demi mencegah salah penafsiran klinis.

5. **Klasifikasi Tingkat Risiko**:
   - **TINGGI**: Ditemukan kata kunci alergen aktif di dalam `mainText`.
   - **SEDANG**: Ditemukan kata kunci di dalam `traceText` atau hanya cocok pada kata `ambiguous`.
   - **AMAN**: Tidak ditemukan kecocokan sama sekali pada profil alergen aktif.

---

## 📖 Cara Menambah Alergen / Sinonim di `assets/allergens.json`

Format kamus alergen disimpan dalam file `assets/allergens.json`:

```json
{
  "kacang_tanah": {
    "label": "Kacang Tanah",
    "subtitle": "Peanuts",
    "icon": "nutrition",
    "keywords": [
      "kacang tanah",
      "peanut",
      "peanuts",
      "arachis",
      "groundnut",
      "pasta kacang tanah",
      "minyak kacang tanah"
    ],
    "ambiguous": [
      "kacang"
    ]
  }
}
```

### Langkah Menambah:
1. Buka file `assets/allergens.json`.
2. Tambahkan entri baru dengan ID unik (contoh: `"seledri"` atau `"mustard"`).
3. Isi `keywords` dengan nama umum, terjemahan bahasa Inggris, turunan dagang, atau nama ilmiah lazim.
4. Jika ada sebutan umum yang belum spesifik jenisnya, masukkan ke array `ambiguous` (akan memicu risiko SEDANG alih-alih TINGGI).
5. Pengguna juga dapat langsung menambahkan alergen khusus pada **Layar 1 (Profil)** secara langsung di aplikasi tanpa mengubah kode sumber.

---

## ⚖️ Keputusan Desain & Perubahan dari Desain Stitch

1. **Penyatuan Layar 6, 7, dan 8 Menjadi 1 Widget `ResultScreen`**:
   - Mengikuti prinsip DRY (*Don't Repeat Yourself*), layar Hasil Risiko Tinggi, Hasil Risiko Sedang, dan Hasil Aman disatukan dalam satu widget `ResultScreen` yang merender tata letak kondisional berdasarkan `result.riskLevel`.

2. **Aturan Kejujuran UI & Penghapusan Angka AI Palsu**:
   - Sesuai instruksi keamanan, angka persentase fiktif (seperti *"AI Presisi 99.4%"*) pada desain awal dihilangkan dan diganti dengan data nyata yang dapat diverifikasi: **jumlah karakter yang terbaca**.
   - Varian AMAN berbunyi *"Tidak ditemukan alergen dari teks yang terbaca"*, bukan *"dijamin aman"*.
   - Jika teks yang terbaca kurang dari 15 karakter, aplikasi tidak menampilkan AMAN melainkan memunculkan kartu peringatan *"Teks sulit terbaca, coba foto ulang atau ketik manual"*.
   - Ditambahkan disclaimer medis resmi di bagian bawah layar hasil.

3. **Abstraksi `IOcrService`**:
   - OCR dibungkus dalam interface `IOcrService` sehingga implementasi `MlKitOcrService` dapat diganti dengan model ONNX lokal atau alternatif lain di masa depan tanpa mengubah kode layar atau matcher.
