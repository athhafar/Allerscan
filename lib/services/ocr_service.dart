import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Abstraksi sederhana (interface) untuk OCR engine
/// Memungkinkan pergantian dari ML Kit ke ONNX atau mock tanpa mengubah business logic
abstract class IOcrService {
  Future<String> readText(File image);
  void dispose();
}

/// Implementasi default menggunakan Google ML Kit Text Recognition
class MlKitOcrService implements IOcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<String> readText(File image) async {
    final inputImage = InputImage.fromFile(image);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  @override
  void dispose() {
    _textRecognizer.close();
  }
}

/// Implementasi Mock/Fallback untuk testing tanpa hardware camera atau ONNX offline
class MockOcrService implements IOcrService {
  final String mockOutput;

  MockOcrService({this.mockOutput = 'Tepung terigu, gula, minyak nabati, susu bubuk skim (2%), pasta kacang tanah (1.5%)'});

  @override
  Future<String> readText(File image) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return mockOutput;
  }

  @override
  void dispose() {}
}
