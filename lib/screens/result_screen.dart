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
  bool _showRawText = false;

  void _shareResult() {
    final res = widget.result;
    final buffer = StringBuffer();
    buffer.writeln('Hasil Pemeriksaan AllerScan:');
    buffer.writeln('Produk: ${res.productName}');
    buffer.writeln('Status Risiko: ${res.riskLevel.label}');

    if (res.aiSummary != null && res.aiSummary!.isNotEmpty) {
      buffer.writeln('\nRingkasan Cerdas AI:');
      buffer.writeln(res.aiSummary);
    }

    if (res.findings.isNotEmpty) {
      buffer.writeln('\nBahan pemicu yang terdeteksi:');
      for (final f in res.findings) {
        buffer.writeln(
            '- ${f.allergenLabel} (Kata cocok: "${f.matchedWord}") [${f.location}]');
      }
    } else {
      buffer.writeln('\nTidak ditemukan alergen dari teks yang terbaca.');
    }

    if (res.cleanedIngredients.isNotEmpty) {
      buffer.writeln('\nDaftar Komposisi:');
      buffer.writeln(res.cleanedIngredients.join(', '));
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
                Expanded(
                  child: Row(
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
                ),
                const SizedBox(width: 8),
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

            // AI SMART INSIGHT CARD (Google Gemini)
            _buildAiInsightCard(res),

            // 2. TRIGGER INGREDIENTS LIST
            if (res.findings.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Bahan Pemicu Terdeteksi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                  ),
                  const SizedBox(width: 8),
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
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: (f.location == 'main'
                                            ? AppTheme.secondaryFixed
                                            : AppTheme.tertiaryFixed)
                                        .withValues(alpha: 0.6),
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        f.allergenLabel,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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

            // 3. COLLAPSIBLE FULL COMPOSITION WITH INGREDIENT CHIPS & AI FORMATTING
            _buildIngredientsSection(res, isHigh, isMedium),
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

            // Status tersimpan otomatis
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryFixed.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_done_outlined, size: 18, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Pemeriksaan otomatis tersimpan di tab Riwayat',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Memeriksa apakah bahan makanan tertentu memicu alergen pengguna
  bool _isIngredientFlagged(String ingredient, ScanResult res) {
    final lowerIng = ingredient.toLowerCase();
    // 1. Cek dari flaggedIngredients Gemini
    for (final flag in res.flaggedIngredients) {
      if (flag.toLowerCase().contains(lowerIng) || lowerIng.contains(flag.toLowerCase())) {
        return true;
      }
    }
    // 2. Cek dari findings database matcher
    for (final finding in res.findings) {
      final mw = finding.matchedWord.toLowerCase();
      final kw = finding.keywordMatched.toLowerCase();
      if ((mw.isNotEmpty && lowerIng.contains(mw)) ||
          (kw.isNotEmpty && lowerIng.contains(kw))) {
        return true;
      }
    }
    return false;
  }

  /// Kartu Analisis Cerdas AI (Google Gemini)
  Widget _buildAiInsightCard(ScanResult res) {
    if (res.aiSummary == null || res.aiSummary!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF5F3FF), // Soft violet
            Color(0xFFFFFFFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD6FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Analisis Cerdas AI',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4C1D95),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC4B5FD)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt, size: 12, color: Color(0xFF6D28D9)),
                    SizedBox(width: 3),
                    Text(
                      'Gemini AI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6D28D9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            res.aiSummary!,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: Color(0xFF1E1B4B),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// Bagian Komposisi Lengkap yang Rapi (Chips & Trace Warnings)
  Widget _buildIngredientsSection(ScanResult res, bool isHigh, bool isMedium) {
    final hasCleaned = res.cleanedIngredients.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryFixed.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Daftar Komposisi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              if (hasCleaned) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${res.cleanedIngredients.length} bahan',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            hasCleaned
                                ? 'Dibersihkan & dirapikan oleh Gemini AI'
                                : 'Teks hasil pembacaan kemasan',
                            style: const TextStyle(
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
                  if (hasCleaned) ...[
                    // Tampilan Chips Rapi
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: res.cleanedIngredients.map((ingredient) {
                        final isFlagged = _isIngredientFlagged(ingredient, res);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isFlagged
                                ? AppTheme.riskHighContainer
                                : AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isFlagged
                                  ? AppTheme.riskHighBorder
                                  : const Color(0xFFE2E8F0),
                              width: isFlagged ? 1.2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isFlagged) ...[
                                const Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.secondary),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                ingredient,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isFlagged ? FontWeight.w600 : FontWeight.w400,
                                  color: isFlagged ? AppTheme.secondary : AppTheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    // Peringatan Jejak Fasilitas Pabrik (Trace Warnings)
                    if (res.traceWarnings.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.riskMediumContainer.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.riskMediumBorder.withOpacity(0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.factory_outlined, size: 15, color: AppTheme.tertiary),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Peringatan Jejak / Fasilitas Produksi:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.tertiary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: res.traceWarnings.map((warning) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.riskMediumBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.info_outline, size: 11, color: AppTheme.tertiary),
                                      const SizedBox(width: 4),
                                      Text(
                                        warning,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.tertiary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    // Toggle untuk melihat teks mentah OCR
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showRawText = !_showRawText;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              _showRawText ? Icons.expand_less : Icons.expand_more,
                              size: 16,
                              color: AppTheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _showRawText ? 'Sembunyikan teks mentah OCR' : 'Lihat teks mentah OCR kamera',
                              style: const TextStyle(fontSize: 11, color: AppTheme.outline),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showRawText) ...[
                      const SizedBox(height: 8),
                      _buildRawTextBox(res, isHigh, isMedium),
                    ],
                  ] else ...[
                    // Jika belum/tidak ada analisis AI, tampilkan teks mentah langsung
                    _buildRawTextBox(res, isHigh, isMedium),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Kotak teks mentah OCR asli
  Widget _buildRawTextBox(ScanResult res, bool isHigh, bool isMedium) {
    return Column(
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
            res.rawText.isNotEmpty ? res.rawText : '(Teks komposisi kosong)',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.onSurface,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isHigh
                      ? AppTheme.secondary
                      : (isMedium ? AppTheme.tertiary : AppTheme.primary),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Teks mentah pemindai kamera',
                  style: TextStyle(fontSize: 11, color: AppTheme.outline),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _editInManualInput,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              icon: const Icon(Icons.edit, size: 14, color: AppTheme.primary),
              label: const Text('Edit teks',
                  style: TextStyle(fontSize: 12, color: AppTheme.primary)),
            ),
          ],
        ),
      ],
    );
  }
}
