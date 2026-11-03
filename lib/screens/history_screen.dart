import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scan_result.dart';
import '../providers/history_provider.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _activeFilter = 'semua'; // 'semua', 'tinggi', 'sedang', 'aman'

  @override
  Widget build(BuildContext context) {
    final historyProvider = Provider.of<HistoryProvider>(context);
    final allHistory = historyProvider.history;

    final filtered = allHistory.where((item) {
      if (_activeFilter == 'semua') return true;
      if (_activeFilter == 'tinggi') return item.riskLevel == RiskLevel.tinggi;
      if (_activeFilter == 'sedang') return item.riskLevel == RiskLevel.sedang;
      if (_activeFilter == 'aman') return item.riskLevel == RiskLevel.aman;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppTheme.primary, size: 24),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AllerScan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                Text(
                  'Riwayat',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (allHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.outline),
              tooltip: 'Hapus Riwayat',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Semua Riwayat?'),
                    content: const Text('Semua catatan scan pada perangkat akan dihapus secara permanen.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          historyProvider.clearAll();
                          Navigator.of(ctx).pop();
                        },
                        style: TextButton.styleFrom(foregroundColor: AppTheme.secondary),
                        child: const Text('Hapus Semua'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Scan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Daftar produk yang telah kamu periksa sebelumnya.',
                      style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${historyProvider.totalCount} Terdata',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weekly Safety Pulse card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.health_and_safety, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ringkasan Keamanan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          '${historyProvider.safeCount} produk sepenuhnya aman untuk profilmu',
                          style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Horizontal Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('semua', 'Semua', historyProvider.totalCount, null),
                  const SizedBox(width: 8),
                  _buildFilterChip('tinggi', 'Tinggi', historyProvider.highRiskCount, AppTheme.secondary),
                  const SizedBox(width: 8),
                  _buildFilterChip('sedang', 'Sedang', historyProvider.mediumRiskCount, AppTheme.tertiary),
                  const SizedBox(width: 8),
                  _buildFilterChip('aman', 'Rendah / Aman', historyProvider.safeCount, AppTheme.primary),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // List of history items
            if (filtered.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.folder_open, size: 28, color: AppTheme.outline),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum Ada Riwayat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tidak ada catatan scan dalam kategori filter ini.',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isItemHigh = item.riskLevel == RiskLevel.tinggi;
                  final isItemMedium = item.riskLevel == RiskLevel.sedang;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ResultScreen(result: item)),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.photo_camera, size: 14, color: AppTheme.outline),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.charCount} karakter • ${_formatDate(item.timestamp)}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.outline),
                                  padding: EdgeInsets.zero,
                                  onSelected: (val) {
                                    if (val == 'hapus') {
                                      historyProvider.removeScan(item.id);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'hapus',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 18, color: AppTheme.secondary),
                                          SizedBox(width: 8),
                                          Text('Hapus Item', style: TextStyle(color: AppTheme.secondary)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        item.brandOrCategory ?? 'Hasil Pindai',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.outline),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isItemHigh
                                        ? AppTheme.secondaryFixed
                                        : (isItemMedium ? AppTheme.tertiaryFixed : AppTheme.primaryFixed),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isItemHigh
                                            ? Icons.error_outline
                                            : (isItemMedium ? Icons.warning_amber_rounded : Icons.check_circle_outline),
                                        size: 13,
                                        color: isItemHigh
                                            ? AppTheme.secondary
                                            : (isItemMedium ? AppTheme.tertiary : AppTheme.primary),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.riskLevel.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isItemHigh
                                              ? AppTheme.secondary
                                              : (isItemMedium ? AppTheme.tertiary : AppTheme.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (item.findings.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: item.findings.take(3).map((f) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          size: 12,
                                          color: f.location == 'main' ? AppTheme.secondary : AppTheme.tertiary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          f.allergenLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: f.location == 'main' ? AppTheme.secondary : AppTheme.tertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Icon(Icons.shield, size: 14, color: AppTheme.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Bebas dari alergen pada profil kamu',
                                    style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, int count, Color? dotColor) {
    final isSelected = _activeFilter == key;

    return InkWell(
      onTap: () {
        setState(() {
          _activeFilter = key;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primary : const Color(0xFFEEEEEE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null && !isSelected) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryContainer : AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return 'Hari ini, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 2) {
      return 'Kemarin, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
