import React, { useState } from 'react';
import { FileCode, Copy, Check, Terminal, FolderTree } from 'lucide-react';

interface CodeFile {
  name: string;
  path: string;
  language: string;
  description: string;
  content: string;
}

const FLUTTER_CODE_FILES: CodeFile[] = [
  {
    name: 'allergen_matcher.dart',
    path: 'lib/services/allergen_matcher.dart',
    language: 'dart',
    description: 'Logika inti Pure Dart: normalisasi OCR, pemisahan klausul jejak, word boundary, dan Levenshtein distance 1.',
    content: `import 'dart:math';
import '../models/allergen_profile.dart';
import '../models/scan_result.dart';

/// Pure Dart Allergen Matcher Engine (Tanpa dependensi Flutter)
class AllergenMatcher {
  static const List<String> tracePhrases = [
    'mungkin mengandung', 'may contain', 'contains traces',
    'mengandung jejak', 'diproduksi di fasilitas', 'diproduksi pada peralatan',
    'produced in a facility', 'produced on equipment'
  ];

  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1.codeUnitAt(i) == s2.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= s2.length; j++) v0[j] = v1[j];
    }
    return v1[s2.length];
  }

  static ScanResult analyze(String ocrText, List<AllergenDef> activeAllergens, {String productName = 'Produk tanpa nama'}) {
    // 1. Normalisasi teks OCR
    // 2. Pisahkan klausul jejak (mainText vs traceText)
    // 3. Matcher dengan word-boundary & fuzzy Levenshtein (panjang >= 6)
    // 4. Hitung risiko: TINGGI / SEDANG / AMAN
    ...
  }
}`,
  },
  {
    name: 'result_screen.dart',
    path: 'lib/screens/result_screen.dart',
    language: 'dart',
    description: 'Satu widget ResultScreen untuk 3 varian risiko (Tinggi, Sedang, Aman) sesuai aturan kejujuran UI.',
    content: `class ResultScreen extends StatefulWidget {
  final ScanResult result;
  const ResultScreen({super.key, required this.result});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

// Menampilkan:
// - Varian TINGGI: Peringatan bahaya merah, pemicu medis, highlight kata kunci
// - Varian SEDANG: Peringatan fasilitas / jejak / ambigu
// - Varian AMAN: "Tidak ditemukan alergen dari teks yang terbaca" (Bukan "dijamin aman")
// - Peringatan teks < 15 karakter: "Teks sulit terbaca"
// - Disclaimer medis dan tombol edit teks / share`,
  },
  {
    name: 'allergens.json',
    path: 'assets/allergens.json',
    language: 'json',
    description: 'Kamus 8 alergen populer: sinonim Indonesia + Inggris, turunan, dan ambiguous keywords.',
    content: `{
  "kacang_tanah": {
    "label": "Kacang Tanah",
    "keywords": ["kacang tanah", "peanut", "peanuts", "arachis", "pasta kacang tanah"],
    "ambiguous": ["kacang"]
  },
  "susu": {
    "label": "Susu",
    "keywords": ["susu", "milk", "whey", "kasein", "casein", "laktosa", "susu bubuk skim"],
    "ambiguous": []
  },
  "gluten": {
    "label": "Gluten",
    "keywords": ["gluten", "terigu", "gandum", "wheat", "barley", "oat", "tepung terigu"],
    "ambiguous": []
  },
  "udang": {
    "label": "Udang",
    "keywords": ["udang", "shrimp", "krustasea", "terasi", "kepiting", "lobster"],
    "ambiguous": ["seafood"]
  }
}`,
  },
  {
    name: 'allergen_matcher_test.dart',
    path: 'test/allergen_matcher_test.dart',
    language: 'dart',
    description: 'Unit test minimal 6 kasus uji: susu & kacang, kacang almond, jejak fasilitas, teks kosong, salah baca kaseln, dan kata ambigu.',
    content: `void main() {
  group('AllergenMatcher Core Tests', () {
    test('Case 1: susu & pasta kacang tanah -> TINGGI, 2 temuan', () { ... });
    test('Case 2: "kacang almond" tidak memicu kacang_tanah -> AMAN', () { ... });
    test('Case 3: Klausul jejak "Diproduksi pada peralatan..." -> SEDANG', () { ... });
    test('Case 4: Teks kosong -> AMAN dengan isTextTooShort = true', () { ... });
    test('Case 5: Salah baca OCR "kaseln" -> TINGGI (Levenshtein 1)', () { ... });
    test('Case 6: Kata ambiguous "kacang" -> SEDANG', () { ... });
  });
}`,
  },
  {
    name: 'pubspec.yaml',
    path: 'pubspec.yaml',
    language: 'yaml',
    description: 'Spesifikasi dependensi: provider, shared_preferences, google_mlkit_text_recognition, image_picker, google_fonts, share_plus, intl.',
    content: `name: allerscan
version: 1.0.0+1
environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  shared_preferences: ^2.2.3
  google_mlkit_text_recognition: ^0.13.0
  image_picker: ^1.1.2
  google_fonts: ^6.2.1
  share_plus: ^9.0.0
  intl: ^0.19.0

flutter:
  assets:
    - assets/allergens.json`,
  },
];

export const FlutterCodeViewer: React.FC = () => {
  const [selectedIdx, setSelectedIdx] = useState(0);
  const [copied, setCopied] = useState(false);

  const currentFile = FLUTTER_CODE_FILES[selectedIdx];

  const handleCopy = () => {
    navigator.clipboard.writeText(currentFile.content);
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  };

  return (
    <div className="bg-slate-900 text-slate-100 rounded-2xl overflow-hidden border border-slate-800 shadow-xl flex flex-col h-[740px]">
      {/* Top Header */}
      <div className="bg-slate-950 px-4 py-3 border-b border-slate-800 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <FolderTree className="w-5 h-5 text-emerald-400" />
          <span className="font-semibold text-sm tracking-wide">Arsitektur Proyek Flutter Mobile</span>
          <span className="text-xs bg-emerald-950 text-emerald-300 border border-emerald-800 px-2 py-0.5 rounded-full">Android First</span>
        </div>
        <button
          onClick={handleCopy}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-xs font-medium text-slate-200 transition-colors"
        >
          {copied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
          <span>{copied ? 'Tersalin!' : 'Salin Kode'}</span>
        </button>
      </div>

      <div className="flex flex-1 overflow-hidden">
        {/* File Sidebar */}
        <div className="w-64 bg-slate-950/80 border-r border-slate-800 p-3 overflow-y-auto space-y-1">
          <div className="text-[11px] font-semibold text-slate-500 uppercase px-2 py-1 tracking-wider">
            File Sumber Kunci
          </div>
          {FLUTTER_CODE_FILES.map((file, idx) => (
            <button
              key={file.path}
              onClick={() => setSelectedIdx(idx)}
              className={`w-full text-left px-2.5 py-2 rounded-lg text-xs font-mono flex items-center gap-2 transition-all ${
                selectedIdx === idx
                  ? 'bg-emerald-600/20 text-emerald-300 border border-emerald-500/30'
                  : 'text-slate-400 hover:bg-slate-800/60 hover:text-slate-200'
              }`}
            >
              <FileCode className="w-3.5 h-3.5 shrink-0 text-emerald-400" />
              <span className="truncate">{file.name}</span>
            </button>
          ))}

          <div className="pt-4 px-2">
            <div className="p-2.5 rounded-lg bg-slate-900 border border-slate-800 text-[11px] text-slate-400 leading-relaxed">
              <div className="font-semibold text-slate-200 mb-1 flex items-center gap-1">
                <Terminal className="w-3.5 h-3.5 text-emerald-400" />
                <span>Cara Menjalankan:</span>
              </div>
              <p className="font-mono text-emerald-300 bg-black/40 p-1.5 rounded mb-1.5">
                flutter run
              </p>
              Semua file telah di-generate lengkap di direktori proyek <code className="text-emerald-300">lib/</code>, <code className="text-emerald-300">assets/</code>, dan <code className="text-emerald-300">test/</code>.
            </div>
          </div>
        </div>

        {/* Code Content */}
        <div className="flex-1 flex flex-col bg-slate-900 overflow-hidden">
          <div className="px-4 py-2.5 bg-slate-900/90 border-b border-slate-800 flex items-center justify-between">
            <div>
              <span className="text-xs font-mono text-emerald-400 font-semibold">{currentFile.path}</span>
              <p className="text-[11px] text-slate-400 mt-0.5">{currentFile.description}</p>
            </div>
          </div>

          <div className="flex-1 overflow-auto p-4 font-mono text-xs text-slate-200 leading-relaxed bg-[#0d1117]">
            <pre>
              <code>{currentFile.content}</code>
            </pre>
          </div>
        </div>
      </div>
    </div>
  );
};
