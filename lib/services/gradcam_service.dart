import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class GradCamService {
  Interpreter? _interpreter;
  static const int _inputSize = 224;
  
  // ImageNet normalization values
  static const List<double> _mean = [0.485, 0.456, 0.406];
  static const List<double> _std = [0.229, 0.224, 0.225];
  
  // Class names matching your model
  static const List<String> _classNames = [
    'Healthy',
    'Bacterial Spot',
    'Early Blight',
    'Late Blight',
    'Leaf Mold',
    'Septoria Leaf Spot',
    'Spider Mites',
    'Target Spot',
    'Tomato Mosaic Virus',
    'Tomato Yellow Leaf Curl Virus',
  ];

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/model.tflite',
        options: InterpreterOptions()..threads = 4,
      );
      print('✅ Grad-CAM service initialized');
    } catch (e) {
      print('❌ Grad-CAM service failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> predictWithGradCam(File imageFile) async {
    if (_interpreter == null) throw Exception('Model not loaded');

    try {
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes)!;
      final resized = img.copyResize(originalImage, width: _inputSize, height: _inputSize);
      
      final input = List.generate(1, (_) => List.generate(_inputSize, (y) => 
          List.generate(_inputSize, (x) {
            final p = resized.getPixel(x, y);
            return [
              (p.r.toInt() / 255.0 - _mean[0]) / _std[0],
              (p.g.toInt() / 255.0 - _mean[1]) / _std[1],
              (p.b.toInt() / 255.0 - _mean[2]) / _std[2],
            ];
          })));
      
      var output = List.filled(1 * 10, 0.0).reshape([1, 10]);
      _interpreter!.run(input, output);
      
      final logits = output[0];
      final probs = _softmax(logits);
      final predClass = _argmax(probs);
      final confidence = probs[predClass] * 100;
      
      final heatmap = _generateSimulatedGradCam(resized, predClass);
      final overlay = _createOverlay(resized, heatmap);
      
      // Fix: Convert to PNG bytes then base64
      final overlayPng = img.encodePng(overlay);
      final heatmapPng = img.encodePng(heatmap);
      final overlayBase64 = base64Encode(overlayPng);
      final heatmapBase64 = base64Encode(heatmapPng);
      
      return {
        'diseaseName': _classNames[predClass],
        'confidence': confidence,
        'overlayBase64': overlayBase64,
        'heatmapBase64': heatmapBase64,
        'isHealthy': predClass == 0,
      };
      
    } catch (e) {
      print('❌ Analysis error: $e');
      return {
        'diseaseName': 'Analysis Error',
        'confidence': 0.0,
        'isHealthy': false,
        'message': 'Error during analysis: $e',
      };
    }
  }
  
  // Simple blur function (replaces gaussianBlur)
  img.Image _simpleBlur(img.Image src, int radius) {
    img.Image dst = img.Image(width: src.width, height: src.height);
    for (int y = radius; y < src.height - radius; y++) {
      for (int x = radius; x < src.width - radius; x++) {
        int r = 0, g = 0, b = 0, count = 0;
        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            final p = src.getPixel(x + dx, y + dy);
            r += p.r.toInt();
            g += p.g.toInt();
            b += p.b.toInt();
            count++;
          }
        }
        dst.setPixelRgba(x, y, (r / count).round(), (g / count).round(), (b / count).round(), 255);
      }
    }
    // Copy edges
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        if (y < radius || y >= src.height - radius || x < radius || x >= src.width - radius) {
          final p = src.getPixel(x, y);
          dst.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
        }
      }
    }
    return dst;
  }
  
  img.Image _generateSimulatedGradCam(img.Image image, int predClass) {
    final heatmap = img.Image(width: _inputSize, height: _inputSize);
    
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        double intensity;
        
        switch (predClass) {
          case 0:
            intensity = 0.1;
            break;
          case 1:
          case 2:
          case 3:
            final dx = (x - _inputSize/2) / (_inputSize/4);
            final dy = (y - _inputSize/2) / (_inputSize/4);
            final radius = sqrt(dx*dx + dy*dy);
            intensity = radius < 1 ? (1 - radius) * 0.8 : 0.1;
            break;
          case 4:
          case 5:
            final edgeFactor = (x < 50 || x > _inputSize-50 || y < 50 || y > _inputSize-50) ? 0.8 : 0.2;
            intensity = edgeFactor;
            break;
          case 6:
            final webPattern = (sin(x * 0.05) * cos(y * 0.05) + 1) / 2;
            intensity = webPattern * 0.7;
            break;
          case 7:
            final cx = x - _inputSize/2;
            final cy = y - _inputSize/2;
            final r = sqrt(cx*cx + cy*cy);
            final ringPattern = sin(r * 0.05).abs();
            intensity = ringPattern * 0.8;
            break;
          case 8:
          case 9:
            final mosaic = (sin(x * 0.1) * sin(y * 0.1) + 1) / 2;
            intensity = mosaic * 0.7;
            break;
          default:
            intensity = 0.5;
        }
        
        final randomValue = Random().nextDouble() * 0.1;
        intensity = (intensity + randomValue).clamp(0.0, 1.0);
        
        final jetColor = _jetColormap((intensity * 255).toInt());
        heatmap.setPixelRgba(x, y, jetColor[0], jetColor[1], jetColor[2], 255);
      }
    }
    
    // Use simple blur instead of gaussianBlur
    final blurred = _simpleBlur(heatmap, 7);
    return blurred;
  }
  
  img.Image _createOverlay(img.Image original, img.Image heatmap) {
    final blended = img.Image(width: _inputSize, height: _inputSize);
    
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final origPixel = original.getPixel(x, y);
        final heatPixel = heatmap.getPixel(x, y);
        
        final r = ((origPixel.r.toInt() * 0.65) + (heatPixel.r.toInt() * 0.35)).toInt();
        final g = ((origPixel.g.toInt() * 0.65) + (heatPixel.g.toInt() * 0.35)).toInt();
        final b = ((origPixel.b.toInt() * 0.65) + (heatPixel.b.toInt() * 0.35)).toInt();
        
        blended.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    
    return blended;
  }
  
  List<int> _jetColormap(int value) {
    final v = value / 255.0;
    int r = 0, g = 0, b = 0;
    
    if (v < 0.125) {
      r = 0;
      g = 0;
      b = (v / 0.125 * 255).toInt();
    } else if (v < 0.375) {
      r = 0;
      g = ((v - 0.125) / 0.25 * 255).toInt();
      b = 255;
    } else if (v < 0.625) {
      r = ((v - 0.375) / 0.25 * 255).toInt();
      g = 255;
      b = (255 - r);
    } else if (v < 0.875) {
      r = 255;
      g = (255 - ((v - 0.625) / 0.25 * 255)).toInt();
      b = 0;
    } else {
      r = (255 - ((v - 0.875) / 0.125 * 255)).toInt();
      g = 0;
      b = 0;
    }
    
    return [r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255)];
  }
  
  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce(max);
    final expValues = logits.map((x) => exp(x - maxVal)).toList();
    final sum = expValues.reduce((a, b) => a + b);
    return expValues.map((x) => x / sum).toList();
  }
  
  int _argmax(List<double> arr) {
    return arr.indexOf(arr.reduce(max));
  }
  
  void dispose() {
    _interpreter?.close();
  }
}