import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../providers/profile_provider.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class SupabaseConfigDialog extends StatefulWidget {
  final StorageService storageService;

  const SupabaseConfigDialog({
    super.key,
    required this.storageService,
  });

  static Future<void> show(BuildContext context, StorageService storageService) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SupabaseConfigDialog(storageService: storageService),
    );
  }

  @override
  State<SupabaseConfigDialog> createState() => _SupabaseConfigDialogState();
}

class _SupabaseConfigDialogState extends State<SupabaseConfigDialog> {
  late TextEditingController _keyController;
  late TextEditingController _nameController;
  bool _isLoading = false;
  bool _obscureKey = true;
  String? _statusMessage;
  bool _isSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    final savedKey = widget.storageService.getSupabaseAnonKey() ??
        (SupabaseService.supabaseAnonKey.isNotEmpty ? SupabaseService.supabaseAnonKey : '');
    _keyController = TextEditingController(text: savedKey);
    _nameController = TextEditingController(text: widget.storageService.getUserName());
  }

  @override
  void dispose() {
    _keyController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _testAndConnect() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _statusMessage = 'Masukkan Anon Key terlebih dahulu.';
        _isSuccessMessage = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final res = await SupabaseService.updateAndConnect(key, widget.storageService);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = res['message'] as String;
        _isSuccessMessage = res['success'] as bool;
      });

      if (res['success'] == true) {
        // Sinkronkan provider
        final profile = Provider.of<ProfileProvider>(context, listen: false);
        final history = Provider.of<HistoryProvider>(context, listen: false);
        profile.syncWithSupabase();
        history.syncWithSupabase();
      }
    }
  }

  Future<void> _syncDatabaseAllergens() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final history = Provider.of<HistoryProvider>(context, listen: false);

    await profile.syncWithSupabase();
    await history.syncWithSupabase();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage =
            'Berhasil memuat ${profile.allAllergens.length} grup alergen & seluruh kata kunci murni dari Supabase!';
        _isSuccessMessage = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = SupabaseService.isConfigured && SupabaseService.isInitialized;
    final userId = widget.storageService.getOrCreateUserId();

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? AppTheme.primaryContainer
                        : AppTheme.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_sync_outlined,
                    color: isConnected ? AppTheme.primary : AppTheme.outline,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Koneksi Supabase DB',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        'foodalert-db',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 4,
                        backgroundColor: isConnected ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConnected ? 'Terhubung' : 'Belum Terhubung',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isConnected ? Colors.green[800] : Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Project URL Display
            const Text(
              'Supabase Project URL',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.outlineVariant),
              ),
              child: const SelectableText(
                SupabaseService.supabaseUrl,
                style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: AppTheme.onSurface),
              ),
            ),
            const SizedBox(height: 14),

            // Anon Key Input
            const Text(
              'Supabase Anon (Public) Key',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _keyController,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                hintText: 'eyJh......',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                suffixIcon: IconButton(
                  icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility, size: 20),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Dapat disalin dari Supabase Dashboard -> Project Settings -> API -> anon public key.',
              style: TextStyle(fontSize: 11, color: AppTheme.outline),
            ),

            const SizedBox(height: 16),

            // Nama Pengguna
            const Text(
              'Nama Pengguna (Tersimpan di tabel users)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Nama Anda',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (val) {
                widget.storageService.saveUserName(val);
              },
            ),
            const SizedBox(height: 4),
            Text(
              'ID Perangkat: $userId',
              style: const TextStyle(fontSize: 10, color: AppTheme.outline, fontFamily: 'monospace'),
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccessMessage
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccessMessage ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccessMessage ? Icons.check_circle : Icons.error_outline,
                      color: _isSuccessMessage ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isSuccessMessage ? Colors.green[900] : Colors.red[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.bolt),
                label: Text(_isLoading ? 'Menghubungkan...' : 'Simpan & Hubungkan ke Supabase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _testAndConnect,
              ),
            ),

            if (isConnected) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Tarik Ulang Kamus Alergen dari Supabase'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _syncDatabaseAllergens,
                ),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
