import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onSaved;

  const ProfileScreen({
    super.key,
    this.isOnboarding = false,
    this.onSaved,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _customController = TextEditingController();

  IconData _getAllergenIcon(String iconName) {
    switch (iconName) {
      case 'nutrition':
        return Icons.eco;
      case 'local_cafe':
        return Icons.local_cafe_outlined;
      case 'egg':
        return Icons.egg_outlined;
      case 'grain':
        return Icons.grain;
      case 'set_meal':
        return Icons.set_meal;
      case 'eco':
        return Icons.spa_outlined;
      case 'bubble_chart':
        return Icons.bubble_chart_outlined;
      case 'phishing':
        return Icons.phishing;
      default:
        return Icons.shield_outlined;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context);
    final selectedCount = profile.selectedAllergenIds.length;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppTheme.primary, size: 24),
            SizedBox(width: 8),
            Text(
              'Kelola Alergen Pengguna',
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
      body: profile.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator if onboarding
                  if (widget.isOnboarding) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Langkah 1/3',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Badge & Title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryFixed,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.health_and_safety, size: 16, color: AppTheme.onPrimaryFixedVariant),
                        SizedBox(width: 4),
                        Text(
                          'Personalisasi Cerdas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onPrimaryFixedVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Profil Alergen Kamu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pilih bahan makanan yang memicu alergi kamu untuk perlindungan personal saat memindai produk.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sensitivity Filter Info Card
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
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryFixed.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.verified, color: AppTheme.primary, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filter Sensitivitas Aktif',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Sistem akan otomatis memberi peringatan bahaya saat bahan terdeteksi pada kemasan.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.thumb_up_alt_outlined, color: AppTheme.primary, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Pilihan Alergen Populer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryFixedDim.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$selectedCount Dipilih',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Allergen Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.1,
                    ),
                    itemCount: profile.allAllergens.length,
                    itemBuilder: (context, index) {
                      final item = profile.allAllergens.values.toList()[index];
                      final isSelected = profile.isSelected(item.id);

                      return InkWell(
                        onTap: () => profile.toggleAllergen(item.id),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryFixed.withOpacity(0.25)
                                : AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : const Color(0xFFEEEEEE),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryFixed
                                      : AppTheme.surfaceContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getAllergenIcon(item.icon),
                                  size: 20,
                                  color: isSelected
                                      ? AppTheme.onPrimaryFixed
                                      : AppTheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item.label,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      item.subtitle.isNotEmpty ? item.subtitle : 'Alergen',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected ? AppTheme.primary : AppTheme.outline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 14,
                                  color: isSelected ? Colors.white : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Custom Allergen Section
                  const Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Tambah Alergen Khusus',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customController,
                          decoration: InputDecoration(
                            hintText: 'Misal: Seledri, Pewarna Kuning FCF...',
                            hintStyle: const TextStyle(color: AppTheme.outline, fontSize: 13),
                            prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.outline),
                            filled: true,
                            fillColor: AppTheme.surfaceContainerLowest,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              profile.addCustomAllergen(val);
                              _customController.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(80, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (_customController.text.trim().isNotEmpty) {
                            profile.addCustomAllergen(_customController.text);
                            _customController.clear();
                          }
                        },
                        child: const Text('Tambah'),
                      ),
                    ],
                  ),

                  // Custom chips
                  if (profile.customAllergens.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.customAllergens.map((c) {
                        return Chip(
                          backgroundColor: AppTheme.primary,
                          label: Text(
                            c.label,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                          onDeleted: () => profile.removeCustomAllergen(c.id),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.tertiaryContainer, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kamu dapat mengubah daftar alergen ini kapan saja di tab Profil. Informasi ini disimpan di perangkat demi privasimu.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profil alergen berhasil disimpan!'),
                          backgroundColor: AppTheme.primary,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      if (widget.onSaved != null) {
                        widget.onSaved!();
                      }
                    },
                    icon: const Icon(Icons.shield, size: 20),
                    label: Text('Simpan Profil ($selectedCount Dipilih)'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
