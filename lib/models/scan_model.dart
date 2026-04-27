import 'dart:convert';
import 'dart:typed_data';

class ScanResult {
  final String id;
  final String plantName;
  final String healthStatus;
  final double confidence;
  final String date;
  final String imagePath;
  final String? overlayImageBase64;
  final String? heatmapBase64;

  ScanResult({
    required this.id,
    required this.plantName,
    required this.healthStatus,
    required this.confidence,
    required this.date,
    required this.imagePath,
    this.overlayImageBase64,
    this.heatmapBase64,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'plantName': plantName,
    'healthStatus': healthStatus,
    'confidence': confidence,
    'date': date,
    'imagePath': imagePath,
    'overlayImageBase64': overlayImageBase64,
    'heatmapBase64': heatmapBase64,
  };

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
    id: json['id'],
    plantName: json['plantName'],
    healthStatus: json['healthStatus'],
    confidence: json['confidence'],
    date: json['date'],
    imagePath: json['imagePath'],
    overlayImageBase64: json['overlayImageBase64'],
    heatmapBase64: json['heatmapBase64'],
  );
  
  Uint8List? get overlayImage => overlayImageBase64 != null 
      ? base64Decode(overlayImageBase64!) 
      : null;
  
  Uint8List? get heatmapImage => heatmapBase64 != null 
      ? base64Decode(heatmapBase64!) 
      : null;
}