import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/history_provider.dart';
import '../services/ocr_service.dart';
import '../services/allergen_matcher.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class AnalyzingScreen extends StatefulWidget {
  final File? imageFile;
  final String? directText;
  final String productName;

  const AnalyzingScreen({
    super.key,
    this.imageFile,
    this.directText,
    this.productName = 'Produk tanpa nama',
  });

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final IOcrService _ocrService = MlKitOcrService();
  bool _isCancelled = false;
  int _currentStep = 1; // 1: Ekstraksi teks, 2: Pencocokan kamus, 3: Verifikasi jejak

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _startAnalysis();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    try {
      String text = widget.directText ?? '';

      if (widget.imageFile != null && text.isEmpty) {
        // Step 1: OCR
        setState(() => _currentStep = 1);
        text = await _ocrService.readText(widget.imageFile!);
      }

      if (_isCancelled) return;

      // Step 2: Matcher
      setState(() => _currentStep = 2);
      await Future.delayed(const Duration(milliseconds: 600));

      if (_isCancelled) return;

      // Step 3: Verification
      setState(() => _currentStep = 3);
      await Future.delayed(const Duration(milliseconds: 400));

      if (_isCancelled || !mounted) return;

      final profile = Provider.of<ProfileProvider>(context, listen: false);
      final history = Provider.of<HistoryProvider>(context, listen: false);

      final result = AllergenMatcher.analyze(
        text,
        profile.activeAllergens,
        productName: widget.productName,
        imagePath: widget.imageFile?.path,
      );

      // Auto save to history
      await history.addScan(result);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kendala saat analisis: $e'),
            backgroundColor: AppTheme.secondary,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context);
    final activeLabels = profile.activeAllergens.map((a) => a.label).join(', ');

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
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Product preview pill
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.document_scanner, color: AppTheme.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pindai Baru Selesai',
                            style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            widget.productName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
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
              const SizedBox(height: 24),

              // Animated Radar Icon
              ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                  CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                ),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryFixed.withOpacity(0.2),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary,
                      ),
                      child: const Icon(
                        Icons.filter_center_focus,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Menganalisis Komposisi...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mencocokkan bahan dengan profil alergen kamu ($activeLabels)...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              // Step Progress Rail
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  children: [
                    _buildStepRow(1, 'Ekstraksi teks bahan', _currentStep > 1, _currentStep == 1),
                    const Divider(color: Color(0xFFEEEEEE), height: 16),
                    _buildStepRow(2, 'Mencocokkan kamus alergen', _currentStep > 2, _currentStep == 2),
                    const Divider(color: Color(0xFFEEEEEE), height: 16),
                    _buildStepRow(3, 'Verifikasi peringatan jejak produksi', _currentStep > 3, _currentStep == 3),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Reassurance note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sistem kami membaca label "Mungkin mengandung" dan varian nama ilmiah seperti casein dan lecithin.',
                        style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextButton(
                onPressed: () {
                  _isCancelled = true;
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Batalkan Pemindaian',
                  style: TextStyle(color: AppTheme.outline, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(int step, String title, bool isDone, bool isActive) {
    Color iconBg = AppTheme.surfaceContainer;
    Color iconColor = AppTheme.outline;
    Widget statusWidget = const Text('Menunggu', style: TextStyle(fontSize: 11, color: AppTheme.outline));

    if (isDone) {
      iconBg = AppTheme.primaryFixed;
      iconColor = AppTheme.onPrimaryFixedVariant;
      statusWidget = const Text('Selesai', style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600));
    } else if (isActive) {
      iconBg = AppTheme.primary;
      iconColor = Colors.white;
      statusWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.primaryFixed.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Proses', style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
      );
    }

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.check : (isActive ? Icons.sync : Icons.radio_button_unchecked),
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: AppTheme.onSurface,
            ),
          ),
        ),
        statusWidget,
      ],
    );
  }
}
