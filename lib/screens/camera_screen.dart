import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'analyzing_screen.dart';
import 'manual_input_screen.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCameraLoading = true;
  bool _isPermissionDenied = false;
  String? _errorMessage;

  bool _isFlashOn = false;
  bool _isCapturing = false;

  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  Offset? _focusPoint;
  bool _showFocusRing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Animasi garis pemindai laser (laser scanner line)
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(
        parent: _scanAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Saat pengguna kembali dari Pengaturan HP:
      // Cek ulang apakah izin kamera sekarang sudah diberikan
      if (!_isCameraInitialized) {
        PermissionService.isCameraGranted().then((granted) {
          if (granted && mounted) {
            _initCamera(requestPermission: false);
          }
        });
      } else {
        _initCamera(requestPermission: false);
      }
    } else if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanAnimationController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera({bool requestPermission = true}) async {
    setState(() {
      _isCameraLoading = true;
      _errorMessage = null;
      _isPermissionDenied = false;
    });

    if (requestPermission) {
      final hasPermission = await PermissionService.ensureCamera(context);
      if (!hasPermission) {
        if (!mounted) return;
        setState(() {
          _isCameraLoading = false;
          _isCameraInitialized = false;
          _isPermissionDenied = true;
          _errorMessage =
              'Akses kamera belum diizinkan. Aktifkan izin kamera di Pengaturan untuk memindai label komposisi makanan.';
        });
        return;
      }
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _isCameraLoading = false;
          _isCameraInitialized = false;
          _errorMessage = 'Tidak ada sensor kamera terdeteksi pada perangkat ini.';
        });
        return;
      }

      // Utamakan kamera belakang untuk pemindaian komposisi
      final backCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isCameraInitialized = true;
        _isCameraLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCameraLoading = false;
        _isCameraInitialized = false;
        _errorMessage = 'Gagal mengakses kamera: $e';
      });
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      if (_isFlashOn) {
        await controller.setFlashMode(FlashMode.off);
        setState(() => _isFlashOn = false);
      } else {
        await controller.setFlashMode(FlashMode.torch);
        setState(() => _isFlashOn = true);
      }
    } catch (e) {
      debugPrint('[CameraScreen] Gagal mengubah lampu flash: $e');
    }
  }

  Future<void> _onTapToFocus(TapDownDetails details, BoxConstraints constraints) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final offset = details.localPosition;
    final point = Offset(
      offset.dx / constraints.maxWidth,
      offset.dy / constraints.maxHeight,
    );

    setState(() {
      _focusPoint = offset;
      _showFocusRing = true;
    });

    try {
      await controller.setFocusPoint(point);
      await controller.setExposurePoint(point);
    } catch (e) {
      debugPrint('[CameraScreen] Error set focus: $e');
    }

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() => _showFocusRing = false);
      }
    });
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      // Jika kamera belum siap, berikan opsi buka galeri
      _pickFromGallery();
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final XFile photo = await controller.takePicture();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AnalyzingScreen(
            imageFile: File(photo.path),
          ),
        ),
      );
    } catch (e) {
      debugPrint('[CameraScreen] Gagal mengambil gambar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: AppTheme.secondary,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final granted = await PermissionService.ensurePhotos(context);
    if (!granted) return;

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 92,
      );

      if (photo != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AnalyzingScreen(
              imageFile: File(photo.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar dari galeri: $e'),
            backgroundColor: AppTheme.secondary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141B2B), // Tampilan gelap khas pemindai klinis
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Column(
                    children: [
                      Text(
                        'Pindai Komposisi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: AppTheme.primaryFixed),
                          SizedBox(width: 4),
                          Text(
                            'KAMERA LIVE SCANNER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.outlineVariant,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: _isFlashOn
                        ? AppTheme.primary
                        : Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      tooltip: _isFlashOn ? 'Matikan Senter' : 'Nyalakan Senter',
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                      ),
                      onPressed: _isCameraInitialized ? _toggleFlash : null,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Viewfinder Target Frame dengan Live Camera di dalamnya
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              width: double.infinity,
              height: 360,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryFixed.withValues(alpha: 0.6),
                  width: 2,
                ),
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Live Camera Preview Stream
                    if (_isCameraInitialized && _controller != null)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final previewSize = _controller!.value.previewSize;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) => _onTapToFocus(details, constraints),
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: previewSize?.height ?? constraints.maxWidth,
                                height: previewSize?.width ?? constraints.maxHeight,
                                child: CameraPreview(_controller!),
                              ),
                            ),
                          );
                        },
                      )
                    else if (_isCameraLoading)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AppTheme.primaryFixed,
                              strokeWidth: 2.5,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Menyiapkan sensor kamera...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Fallback jika kamera tidak tersedia / simulator
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.no_photography_outlined,
                                size: 48,
                                color: AppTheme.outlineVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage ?? 'Kamera tidak tersedia.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_isPermissionDenied) ...[
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.settings, size: 16),
                                  label: const Text('Buka Pengaturan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                  ),
                                  onPressed: () => openAppSettings(),
                                ),
                                const SizedBox(height: 10),
                              ],
                              OutlinedButton.icon(
                                icon: const Icon(Icons.photo_library, size: 16),
                                label: const Text('Pilih dari Galeri'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                ),
                                onPressed: _pickFromGallery,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 2. Animated Laser Scanner Line
                    if (_isCameraInitialized)
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 360 * _scanAnimation.value,
                            left: 8,
                            right: 8,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryFixed.withValues(alpha: 0.0),
                                    AppTheme.primaryFixed,
                                    Colors.white,
                                    AppTheme.primaryFixed,
                                    AppTheme.primaryFixed.withValues(alpha: 0.0),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryFixed.withValues(alpha: 0.75),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // 3. Corner Accent Brackets
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppTheme.primaryFixed, width: 3.5),
                            left: BorderSide(color: AppTheme.primaryFixed, width: 3.5),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppTheme.primaryFixed, width: 3.5),
                            right: BorderSide(color: AppTheme.primaryFixed, width: 3.5),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 14,
                      left: 14,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppTheme.primaryFixed, width: 3.5),
                            left: BorderSide(color: AppTheme.primaryFixed, width: 3.5),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 14,
                      right: 14,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppTheme.primaryFixed, width: 3.5),
                            right: BorderSide(color: AppTheme.primaryFixed, width: 3.5),
                          ),
                        ),
                      ),
                    ),

                    // 4. Tap-To-Focus Indicator Ring
                    if (_showFocusRing && _focusPoint != null)
                      Positioned(
                        left: _focusPoint!.dx - 28,
                        top: _focusPoint!.dy - 28,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primaryFixed, width: 2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                    // 5. Center Guidance Pill
                    Align(
                      alignment: Alignment.center,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.center_focus_strong,
                                  size: 16, color: AppTheme.primaryFixed),
                              SizedBox(width: 8),
                              Text(
                                'Arahkan ke label komposisi',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 6. Bottom Info Status Strip
                    Positioned(
                      bottom: 12,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, size: 14, color: AppTheme.primaryFixed),
                              SizedBox(width: 4),
                              Text(
                                'Live OCR Ready',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'AUTO FOCUS',
                              style: TextStyle(
                                color: AppTheme.primaryFixed,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 7. Shutter Flash / Progress Overlay
                    if (_isCapturing)
                      Container(
                        color: Colors.black.withValues(alpha: 0.6),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Mengambil Foto...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, color: AppTheme.primaryFixed, size: 16),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Ketuk kotak untuk fokus atau tombol bulat untuk memindai',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom Shutter & Controls
            Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Gallery Button
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _pickFromGallery,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.photo_library, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 4),
                        const Text('Galeri', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),

                  // Big Camera Shutter Button (Live Custom Capture)
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(22),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(
                                Icons.qr_code_scanner,
                                color: Colors.white,
                                size: 34,
                              ),
                      ),
                    ),
                  ),

                  // Manual Mode Button
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const ManualInputScreen()),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.keyboard, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 4),
                        const Text('Manual', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
