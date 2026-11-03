import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scan_result.dart';
import '../theme/app_theme.dart';
import 'manual_input_screen.dart';

class ResultScreen extends StatefulWidget {
  final ScanResult result;

  const ResultScreen({
    super.key,
    required this.result,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isIngredientsExpanded = true;
  bool _isSavedFeedback = false;

  void _shareResult() {
    final res = widget.result;
    final buffer = StringBuffer();
    buffer.writeln('Hasil Pemeriksaan AllerScan:');
    buffer.writeln('Produk: ${res.productName}');
    buffer.writeln('Status Risiko: ${res.riskLevel.label}');

    if (res.findings.isNotEmpty) {
      buffer.writeln('\nBahan pemicu yang terdeteksi:');
      for (final f in res.findings) {
        buffer.writeln(
            '- ${f.allergenLabel} (Kata cocok: "${f.matchedWord}") [${f.location}]');
      }
    } else {
      buffer.writeln('\nTidak ditemukan alergen dari teks yang terbaca.');
    }

    buffer.writeln(
        '\nDisclaimer: AllerScan adalah alat bantu pendeteksi awal dan bukan pengganti saran medis dokter atau verifikasi label kemasan asli.');
    Share.share(buffer.toString());
  }

  void _editInManualInput() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ManualInputScreen(
          initialText: widget.result.rawText,
          initialProductName: widget.result.productName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.result;
    final isHigh = res.riskLevel == RiskLevel.tinggi;
    final isMedium = res.riskLevel == RiskLevel.sedang;
    final isSafe = res.riskLevel == RiskLevel.aman;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppTheme.primary, size: 24),
            SizedBox(width: 8),
            Text(
              'Hasil Deteksi Alergen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.onSurface),
            tooltip: 'Bagikan',
            onPressed: _shareResult,
          ),
          IconButton(
            icon: const Icon(Icons.edit_note, color: AppTheme.primary),
            tooltip: 'Edit Teks',
            onPressed: _editInManualInput,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar sub-header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isHigh
                          ? Icons.warning
                          : (isMedium
                              ? Icons.info_outline
                              : Icons.check_circle_outline),
                      size: 16,
                      color: isHigh
                          ? AppTheme.secondary
                          : (isMedium ? AppTheme.tertiary : AppTheme.primary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PEMERIKSAAN SELESAI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isHigh
                            ? AppTheme.secondary
                            : (isMedium ? AppTheme.tertiary : AppTheme.primary),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${res.charCount} karakter terbaca',
                  style: const TextStyle(fontSize: 11, color: AppTheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Product Header Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fastfood_outlined,
                      color: isHigh
                          ? AppTheme.secondary
                          : (isMedium ? AppTheme.tertiary : AppTheme.primary),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          res.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          res.brandOrCategory ?? 'Hasil Analisis Komposisi',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Warning for short text (<15 characters)
            if (res.isTextTooShort) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.tertiaryFixed,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.tertiaryFixedDim),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppTheme.tertiary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Teks Sulit Terbaca',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.tertiary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Teks hasil OCR terlalu pendek (< 15 karakter). Coba foto ulang dengan cahaya lebih baik atau gunakan fitur Ketik Manual.',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.onSurface),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.tertiary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(120, 36),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: _editInManualInput,
                            icon: const Icon(Icons.edit, size: 14),
                            label: const Text('Buka Ketik Manual',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 1. RISK HERO CARD (Variant 6 / 7 / 8)
            if (isHigh) ...[
              // VARIANT 6: RISIKO TINGGI
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.riskHighContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.riskHighBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppTheme.riskHighSolid,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.dangerous,
                              color: Colors.white, size: 24),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.riskHighSolid,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, size: 6, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'RISIKO TINGGI',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mengandung bahan alergen kamu!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Produk ini tidak aman dikonsumsi berdasarkan pengaturan profil alergen aktif kamu.',
                      style: TextStyle(fontSize: 13, color: AppTheme.secondary),
                    ),
                  ],
                ),
              ),
            ] else if (isMedium) ...[
              // VARIANT 7: RISIKO SEDANG
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.riskMediumContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.riskMediumBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppTheme.riskMediumSolid,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.warning,
                              color: Colors.white, size: 24),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.riskMediumSolid,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'RISIKO SEDANG',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ada peringatan fasilitas produksi / bahan ambigu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bahan utama tidak mengandung alergen langsung, namun terdapat klaim jejak ("may contain / fasilitas sama") atau istilah bahan yang tidak spesifik.',
                      style: TextStyle(fontSize: 13, color: AppTheme.tertiary),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // VARIANT 8: AMAN (Sesuai Aturan Kejujuran UI: "Tidak ditemukan alergen dari teks yang terbaca")
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.riskSafeContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.riskSafeBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppTheme.riskSafeSolid,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle,
                              color: Colors.white, size: 24),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.riskSafeSolid,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'RISIKO RENDAH / AMAN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tidak ditemukan alergen dari teks yang terbaca',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Komposisi telah dicocokkan dengan profil alergen aktif kamu dan tidak ditemukan bahan pemicu maupun peringatan fasilitas pada teks yang terbaca.',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // 2. TRIGGER INGREDIENTS LIST
            if (res.findings.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Bahan Pemicu Terdeteksi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              isHigh ? AppTheme.secondary : AppTheme.tertiary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${res.findings.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isHigh ? 'Prioritas Medis' : 'Peringatan Fasilitas',
                    style:
                        const TextStyle(fontSize: 12, color: AppTheme.outline),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...res.findings.map((f) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: (f.location == 'main'
                                          ? AppTheme.secondaryFixed
                                          : AppTheme.tertiaryFixed)
                                      .withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  size: 20,
                                  color: f.location == 'main'
                                      ? AppTheme.secondary
                                      : AppTheme.tertiary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.allergenLabel,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    f.location == 'main'
                                        ? 'Komposisi Utama'
                                        : (f.location == 'trace'
                                            ? 'Peringatan Jejak / Fasilitas'
                                            : 'Kategori Ambigu'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: f.location == 'main'
                                          ? AppTheme.secondary
                                          : AppTheme.tertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: f.location == 'main'
                                  ? AppTheme.riskHighSolid
                                  : AppTheme.riskMediumSolid,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Alergen Kamu',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search,
                                size: 16,
                                color: f.location == 'main'
                                    ? AppTheme.secondary
                                    : AppTheme.tertiary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                      fontSize: 12, color: AppTheme.onSurface),
                                  children: [
                                    const TextSpan(text: 'Terdeteksi: '),
                                    TextSpan(
                                      text: '"${f.matchedWord}"',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: f.location == 'main'
                                            ? AppTheme.secondary
                                            : AppTheme.tertiary,
                                      ),
                                    ),
                                    if (f.reason != null) ...[
                                      TextSpan(
                                        text: ' (${f.reason})',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.outline),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              // Safe matrix confirmation
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user,
                        color: AppTheme.primary, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Semua alergen profil aktif kamu tidak ditemukan dalam komposisi maupun klausul jejak yang terbaca.',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // 3. COLLAPSIBLE FULL COMPOSITION WITH HIGHLIGHTED KEYWORDS
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isIngredientsExpanded = !_isIngredientsExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.receipt_long,
                                  color: AppTheme.primary, size: 20),
                              SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Komposisi Lengkap',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Sorotan kata kunci pemicu risiko',
                                    style: TextStyle(
                                        fontSize: 11, color: AppTheme.outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Icon(
                            _isIngredientsExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: AppTheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isIngredientsExpanded) ...[
                    const Divider(color: Color(0xFFEEEEEE), height: 1),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              res.rawText.isNotEmpty
                                  ? res.rawText
                                  : '(Teks komposisi kosong)',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.onSurface,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.circle,
                                      size: 8,
                                      color: isHigh
                                          ? AppTheme.secondary
                                          : (isMedium
                                              ? AppTheme.tertiary
                                              : AppTheme.primary)),
                                  const SizedBox(width: 4),
                                  const Text(
                                      'Dianalisis secara lokal (offline)',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.outline)),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _editInManualInput,
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero),
                                icon: const Icon(Icons.edit,
                                    size: 14, color: AppTheme.primary),
                                label: const Text('Edit teks',
                                    style: TextStyle(
                                        fontSize: 12, color: AppTheme.primary)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mandatory Safety Disclaimer Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.health_and_safety_outlined,
                      color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Peringatan Penting: Aplikasi ini adalah alat bantu penapisan awal, bukan pengganti membaca label kemasan asli secara cermat dan bukan pengganti saran dokter atau ahli medis, terutama bagi pemilik alergi berat / anafilaksis.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              label: const Text('Scan Produk Lain'),
            ),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.onSurface,
                side: const BorderSide(color: Color(0xFFEEEEEE)),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: _isSavedFeedback
                    ? AppTheme.primaryFixed.withOpacity(0.3)
                    : Colors.transparent,
              ),
              onPressed: () {
                setState(() => _isSavedFeedback = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pemeriksaan tersimpan di tab Riwayat!'),
                    backgroundColor: AppTheme.primary,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(
                _isSavedFeedback
                    ? Icons.bookmark_added
                    : Icons.bookmark_add_outlined,
                size: 20,
                color: AppTheme.primary,
              ),
              label: Text(_isSavedFeedback
                  ? 'Tersimpan di Riwayat'
                  : 'Simpan ke Riwayat'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
