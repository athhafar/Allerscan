import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/history_provider.dart';
import '../services/allergen_matcher.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class ManualInputScreen extends StatefulWidget {
  final String? initialText;
  final String? initialProductName;

  const ManualInputScreen({
    super.key,
    this.initialText,
    this.initialProductName,
  });

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  late TextEditingController _textController;
  late TextEditingController _nameController;

  final List<String> _quickChips = [
    'Tepung terigu',
    'Susu bubuk skim',
    'Lesitin kedelai',
    'Putih telur',
    'Kacang tanah',
    'Udang bubuk',
    'Kacang almond',
    'Wijen sangrai',
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText ?? '');
    _nameController = TextEditingController(text: widget.initialProductName ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _insertChip(String word) {
    final current = _textController.text.trim();
    if (current.isEmpty) {
      _textController.text = word;
    } else if (current.endsWith(',')) {
      _textController.text = '$current $word';
    } else {
      _textController.text = '$current, $word';
    }
    setState(() {});
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      final current = _textController.text.trim();
      if (current.isEmpty) {
        _textController.text = data.text!.trim();
      } else {
        _textController.text = '$current, ${data.text!.trim()}';
      }
      setState(() {});
    } else {
      // Fallback sample text if clipboard is empty
      const sample = 'Tepung terigu, gula pasir, minyak kelapa sawit, susu bubuk skim (3%), pasta kacang tanah (2%), pengemulsi nabati lesitin kedelai.';
      _textController.text = sample;
      setState(() {});
    }
  }

  void _analyze() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan ketik atau tempel komposisi terlebih dahulu'),
          backgroundColor: AppTheme.tertiary,
        ),
      );
      return;
    }

    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final history = Provider.of<HistoryProvider>(context, listen: false);

    final pName = _nameController.text.trim().isEmpty
        ? 'Produk tanpa nama'
        : _nameController.text.trim();

    final result = AllergenMatcher.analyze(
      text,
      profile.activeAllergens,
      productName: pName,
    );

    // Auto save to history
    history.addScan(result);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(result: result),
      ),
    );
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
              'Input Manual Komposisi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Allergen Reminder Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security, size: 16, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Memeriksa terhadap:',
                          style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                        ),
                        Text(
                          activeLabels.isNotEmpty ? activeLabels : 'Belum ada alergen aktif',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 30),
                    ),
                    child: const Text('Ubah', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Optional Product Name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Nama Produk (Opsional)',
                  labelStyle: TextStyle(color: AppTheme.outline, fontSize: 13),
                  hintText: 'Contoh: Biskuit Gandum Cokelat',
                  hintStyle: TextStyle(color: AppTheme.outline, fontSize: 13),
                  prefixIcon: Icon(Icons.label_outline, color: AppTheme.outline, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Main Text Input Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.format_list_bulleted, color: AppTheme.primary, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Daftar Bahan / Komposisi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: _pasteFromClipboard,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.content_paste, size: 14, color: AppTheme.primary),
                              SizedBox(width: 4),
                              Text(
                                'Tempel',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _textController,
                    maxLines: 7,
                    maxLength: 2000,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText:
                          'Ketik atau tempel daftar komposisi di sini...\n\nContoh: Tepung terigu, gula, minyak nabati, susu bubuk skim (2%), pasta kacang tanah (1.5%), pengemulsi lesitin kedelai...',
                      hintStyle: TextStyle(color: AppTheme.outline, fontSize: 13, height: 1.4),
                      counterText: '',
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_textController.text.isNotEmpty)
                        InkWell(
                          onTap: () {
                            _textController.clear();
                            setState(() {});
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.delete_outline, size: 16, color: AppTheme.outline),
                              SizedBox(width: 4),
                              Text('Bersihkan', style: TextStyle(color: AppTheme.outline, fontSize: 12)),
                            ],
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Text(
                        '${_textController.text.length} / 2000 karakter',
                        style: const TextStyle(fontSize: 12, color: AppTheme.outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Insert Chips
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SISIPKAN CEPAT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'Tekan untuk menambahkan',
                  style: TextStyle(fontSize: 11, color: AppTheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickChips.map((chipText) {
                return InkWell(
                  onTap: () => _insertChip(chipText),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          chipText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Tip Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pastikan ejaan sesuai dengan label kemasan. Sistem kami mengenali nama ilmiah serta turunan alergen umum secara otomatis.',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // CTA Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _textController.text.trim().isEmpty ? null : _analyze,
              icon: const Icon(Icons.search, size: 20),
              label: const Text('Analisis Komposisi'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
