import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/supabase_config_dialog.dart';
import 'auth_screen.dart';

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
  List<Map<String, String>> _suggestions = [];

  Future<void> _submitAddAllergen(ProfileProvider profile, String val) async {
    final clean = val.trim();
    if (clean.isEmpty) return;

    final result = await profile.validateAndAddAllergen(clean);
    if (!mounted) return;

    _customController.clear();
    setState(() {
      _suggestions = [];
    });

    final isSuccess = result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result['message'] as String,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? const Color(0xFF006A43) : AppTheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

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
      case 'science':
        return Icons.science_outlined;
      case 'help':
        return Icons.help_outline;
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
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.cloud_sync_outlined, color: AppTheme.primary),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: SupabaseService.isConfigured ? Colors.green : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            tooltip: 'Koneksi Supabase',
            onPressed: () {
              final storage = Provider.of<StorageService>(context, listen: false);
              SupabaseConfigDialog.show(context, storage).then((_) {
                setState(() {});
              });
            },
          ),
          const Padding(
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
                  // Supabase Cloud Sync Banner
                  InkWell(
                    onTap: () {
                      final storage = Provider.of<StorageService>(context, listen: false);
                      SupabaseConfigDialog.show(context, storage).then((_) {
                        setState(() {});
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: SupabaseService.isConfigured
                            ? Colors.green.withValues(alpha: 0.08)
                            : Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: SupabaseService.isConfigured
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_done_outlined,
                            size: 20,
                            color: SupabaseService.isConfigured ? Colors.green[700] : Colors.orange[700],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  SupabaseService.isConfigured
                                      ? 'Tersambung ke Supabase (foodalert-db)'
                                      : 'Supabase Belum Dikonfigurasi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: SupabaseService.isConfigured ? Colors.green[900] : Colors.orange[900],
                                  ),
                                ),
                                Text(
                                  SupabaseService.isConfigured
                                      ? 'Profil & riwayat scan otomatis tersinkron ke cloud'
                                      : 'Ketuk untuk memasukkan Anon Key & hubungkan database',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: SupabaseService.isConfigured ? Colors.green[700] : Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: SupabaseService.isConfigured ? Colors.green : Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // User Account Card (Supabase Auth / Guest)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: SupabaseService.isAuthenticated
                              ? AppTheme.primary
                              : AppTheme.surfaceContainerHigh,
                          child: Icon(
                            SupabaseService.isAuthenticated ? Icons.person : Icons.person_outline,
                            color: SupabaseService.isAuthenticated ? Colors.white : AppTheme.outline,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      SupabaseService.effectiveUserName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: SupabaseService.isAuthenticated
                                          ? AppTheme.primaryContainer.withValues(alpha: 0.15)
                                          : AppTheme.surfaceContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      SupabaseService.isAuthenticated ? 'Terhubung' : 'Tamu',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: SupabaseService.isAuthenticated
                                            ? AppTheme.primary
                                            : AppTheme.outline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                SupabaseService.effectiveUserEmail.isNotEmpty
                                    ? SupabaseService.effectiveUserEmail
                                    : 'Mode Tamu / Offline',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (SupabaseService.isAuthenticated)
                          IconButton(
                            icon: const Icon(Icons.logout, size: 20, color: AppTheme.secondary),
                            tooltip: 'Keluar Akun',
                            onPressed: () async {
                              final storage = Provider.of<StorageService>(context, listen: false);
                              final navigator = Navigator.of(context);
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Keluar dari Akun?'),
                                  content: const Text(
                                    'Anda akan keluar dari sesi akun Supabase saat ini.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.secondary,
                                      ),
                                      child: const Text('Keluar'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await SupabaseService.signOut();
                                if (!mounted) return;
                                navigator.pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => AuthScreen(storageService: storage),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                          )
                        else
                          TextButton(
                            onPressed: () {
                              final storage = Provider.of<StorageService>(context, listen: false);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AuthScreen(storageService: storage),
                                ),
                              );
                            },
                            child: const Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

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
                      childAspectRatio: 1.95,
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

                  // Custom Allergen Search & Validation Section
                  const Row(
                    children: [
                      Icon(Icons.verified_outlined, color: AppTheme.primary, size: 20),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Cari & Tambah Alergen (Database BPOM/Codex)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hanya bahan yang terdaftar dalam database alergen resmi yang akan diterima sistem.',
                    style: TextStyle(fontSize: 11, color: AppTheme.outline),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customController,
                          decoration: InputDecoration(
                            hintText: 'Misal: Almond, Whey, Wijen, Terasi...',
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
                          onChanged: (val) {
                            setState(() {
                              _suggestions = profile.searchDatabaseSuggestions(val);
                            });
                          },
                          onSubmitted: (val) {
                            _submitAddAllergen(profile, val);
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
                          _submitAddAllergen(profile, _customController.text);
                        },
                        child: const Text('Tambah'),
                      ),
                    ],
                  ),

                  // Suggestions from database
                  if (_suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline, size: 14, color: AppTheme.primary),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Saran Bahan Terdaftar di Database (Ketuk untuk Menambahkan):',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _suggestions.map((s) {
                              return ActionChip(
                                backgroundColor: AppTheme.surfaceContainerLowest,
                                avatar: const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.primary),
                                label: Text(
                                  '${s['term']} → ${s['groupLabel']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                onPressed: () {
                                  _submitAddAllergen(profile, s['term']!);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

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
