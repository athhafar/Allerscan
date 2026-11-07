import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';

class PermissionService {
  /// Memeriksa dan meminta permission secara interaktif.
  /// Jika ditolak permanen, menampilkan dialog navigasi ke App Settings.
  static Future<bool> ensurePermission(
    BuildContext context,
    Permission permission, {
    required String title,
    required String reason,
  }) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    // Belum pernah ditolak permanen: minta permission
    if (!status.isPermanentlyDenied) {
      status = await permission.request();
      if (status.isGranted || status.isLimited) return true;
    }

    // Ditolak permanen (atau baru ditolak lagi dan sudah tidak bisa diminta)
    if (status.isPermanentlyDenied && context.mounted) {
      final goToSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(reason),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      );
      if (goToSettings == true) {
        await openAppSettings();
      }
    }
    return false;
  }

  /// Helper untuk izin Kamera
  static Future<bool> ensureCamera(BuildContext context) async {
    return ensurePermission(
      context,
      Permission.camera,
      title: 'Izin Kamera Dibutuhkan',
      reason:
          'Aplikasi AllerScan membutuhkan akses kamera untuk memindai label bahan & komposisi pada kemasan makanan. Aktifkan izin kamera di Pengaturan perangkat Anda.',
    );
  }

  /// Helper untuk izin Galeri / Foto
  static Future<bool> ensurePhotos(BuildContext context) async {
    // Pada permission_handler Android, Permission.photos menangani Android 13+ (READ_MEDIA_IMAGES)
    // dan fallback ke READ_EXTERNAL_STORAGE di Android 12 ke bawah
    return ensurePermission(
      context,
      Permission.photos,
      title: 'Izin Akses Foto Dibutuhkan',
      reason:
          'Aplikasi AllerScan membutuhkan izin untuk memilih gambar komposisi makanan dari album galeri Anda. Aktifkan izin foto di Pengaturan.',
    );
  }

  /// Helper untuk cek langsung status izin kamera tanpa memicu dialog
  static Future<bool> isCameraGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted || status.isLimited;
  }
}
