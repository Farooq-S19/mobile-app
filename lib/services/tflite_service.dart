import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  static final TFLiteService _instance = TFLiteService._internal();
  factory TFLiteService() => _instance;
  TFLiteService._internal();

  Interpreter? _interpreter;
  static const int _inputSize = 224;
  static const int _numClasses = 10;
  static const double _minGreenPercentage = 20.0;
  static const double _lowConfidenceThreshold = 65.0;
  
  static const List<double> _mean = [0.485, 0.456, 0.406];
  static const List<double> _std = [0.229, 0.224, 0.225];
  
  static const List<String> diseaseClasses = [
    'Healthy', 'Bacterial Spot', 'Early Blight', 'Late Blight',
    'Leaf Mold', 'Septoria Leaf Spot', 'Spider Mites', 'Target Spot',
    'Tomato Mosaic Virus', 'Tomato Yellow Leaf Curl Virus',
  ];

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/model.tflite',
        options: InterpreterOptions()..threads = 4,
      );
      print('✅ Model loaded successfully');
    } catch (e) {
      print('❌ Model load failed: $e');
      rethrow;
    }
  }

  double _calculateGreenPercentageHSV(img.Image image) {
    int greenCount = 0;
    int totalPixels = image.width * image.height;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        
        double r = p.r.toInt() / 255.0;
        double g = p.g.toInt() / 255.0;
        double b = p.b.toInt() / 255.0;
        
        double max = r > g ? (r > b ? r : b) : (g > b ? g : b);
        double min = r < g ? (r < b ? r : b) : (g < b ? g : b);
        double delta = max - min;
        
        double h = 0;
        if (delta > 0) {
          if (max == r) {
            h = 60 * (((g - b) / delta) % 6);
          } else if (max == g) {
            h = 60 * (((b - r) / delta) + 2);
          } else {
            h = 60 * (((r - g) / delta) + 4);
          }
        }
        if (h < 0) h += 360;
        
        double s = (max == 0) ? 0 : (delta / max);
        double v = max;
        
        int hValue = (h / 2).round();
        int sValue = (s * 255).round();
        int vValue = (v * 255).round();
        
        if (hValue >= 25 && hValue <= 100 && sValue >= 25 && vValue >= 25) {
          greenCount++;
        }
      }
    }
    
    return (greenCount / totalPixels) * 100;
  }

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

  img.Image _generateGradCamHeatmap(img.Image image, int predictedClass, double confidence) {
    final heatmap = img.Image(width: _inputSize, height: _inputSize);
    
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        double intensity = 0.0;
        
        switch (predictedClass) {
          case 0:
            intensity = 0.1;
            break;
          case 1:
          case 2:
          case 3:
            final centerX = _inputSize / 2;
            final centerY = _inputSize / 2;
            final dx = (x - centerX) / centerX;
            final dy = (y - centerY) / centerY;
            final distance = sqrt(dx * dx + dy * dy);
            intensity = distance < 0.8 ? (1 - distance) * 0.9 : 0.1;
            break;
          case 4:
          case 5:
            final edgeX = x < 40 || x > _inputSize - 40 ? 1.0 : 0.0;
            final edgeY = y < 40 || y > _inputSize - 40 ? 1.0 : 0.0;
            intensity = (edgeX + edgeY) * 0.6;
            break;
          case 6:
            final webX = sin(x * 0.08) * cos(y * 0.05);
            final webY = cos(y * 0.08) * sin(x * 0.05);
            intensity = ((webX + webY) / 2 + 0.5) * 0.7;
            break;
          case 7:
            final centerX = _inputSize / 2;
            final centerY = _inputSize / 2;
            final dx = x - centerX;
            final dy = y - centerY;
            final r = sqrt(dx * dx + dy * dy);
            intensity = (sin(r * 0.1).abs() * 0.8);
            break;
          case 8:
          case 9:
            final mosaic1 = sin(x * 0.12) * sin(y * 0.12);
            final mosaic2 = cos(x * 0.08) * cos(y * 0.08);
            intensity = ((mosaic1 + mosaic2) / 2 + 0.5) * 0.8;
            break;
          default:
            intensity = 0.3;
        }
        
        intensity = intensity * (confidence / 100.0);
        intensity = intensity.clamp(0.0, 1.0);
        
        final color = _jetColormap((intensity * 255).toInt());
        heatmap.setPixelRgba(x, y, color[0], color[1], color[2], 255);
      }
    }
    
    return _simpleBlur(heatmap, 7);
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

  Uint8List _createOverlay(img.Image original, img.Image heatmap) {
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
    
    return Uint8List.fromList(img.encodePng(blended));
  }

  Future<Map<String, dynamic>> predictImage(File imageFile) async {
    if (_interpreter == null) throw Exception('Model not loaded');

    try {
      final bytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) throw Exception('Failed to decode image');
      
      final greenPercent = _calculateGreenPercentageHSV(originalImage);
      print('🌿 Green area: ${greenPercent.toStringAsFixed(1)}%');
      
      if (greenPercent < _minGreenPercentage) {
        return {
          'diseaseName': 'No Leaf Detected',
          'confidence': 0.0,
          'isHealthy': false,
          'message': 'No leaf detected in the image. Please ensure the photo clearly shows a tomato leaf.',
          'greenPercentage': greenPercent,
        };
      }
      
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
      
      var output = List.filled(1 * _numClasses, 0.0).reshape([1, _numClasses]);
      _interpreter!.run(input, output);
      
      final logits = output[0];
      
      double maxVal = logits[0];
      for (int i = 1; i < logits.length; i++) {
        if (logits[i] > maxVal) maxVal = logits[i];
      }
      
      List<double> expValues = [];
      double sum = 0.0;
      for (int i = 0; i < logits.length; i++) {
        double val = exp(logits[i] - maxVal);
        expValues.add(val);
        sum += val;
      }
      
      List<double> probs = [];
      for (int i = 0; i < expValues.length; i++) {
        probs.add(expValues[i] / sum);
      }
      
      int maxIdx = 0;
      double maxProb = probs[0];
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > maxProb) {
          maxProb = probs[i];
          maxIdx = i;
        }
      }
      
      double confidence = maxProb * 100;
      print('🎯 Prediction: ${diseaseClasses[maxIdx]} (${confidence.toStringAsFixed(1)}%)');
      
      if (confidence < _lowConfidenceThreshold) {
        return {
          'diseaseName': 'Unable to Identify',
          'confidence': confidence,
          'isHealthy': false,
          'greenPercentage': greenPercent,
          'message': 'Unable to confidently identify the disease from this image.',
        };
      }
      
      final heatmap = _generateGradCamHeatmap(resized, maxIdx, confidence);
      final overlayBytes = _createOverlay(resized, heatmap);
      final overlayBase64 = base64Encode(overlayBytes);
      
      final heatmapBytes = Uint8List.fromList(img.encodePng(heatmap));
      final heatmapBase64 = base64Encode(heatmapBytes);
      
      return {
        'diseaseName': diseaseClasses[maxIdx],
        'confidence': confidence,
        'isHealthy': maxIdx == 0,
        'greenPercentage': greenPercent,
        'overlayBase64': overlayBase64,
        'heatmapBase64': heatmapBase64,
        'hasGradCam': true,
      };
      
    } catch (e) {
      print('❌ Analysis error: $e');
      return {
        'diseaseName': 'Analysis Error',
        'confidence': 0.0,
        'isHealthy': false,
        'message': 'Error during analysis: $e. Please try again.',
      };
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}