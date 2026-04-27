import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants.dart';
import '../models/disease_model.dart';
import '../models/scan_model.dart';
import '../data/disease_data.dart';
import '../services/storage_service.dart';

class AnalysisResultScreen extends StatefulWidget {
  final dynamic imageFile;
  final Map<String, dynamic> predictionResult;

  const AnalysisResultScreen({
    super.key,
    required this.imageFile,
    required this.predictionResult,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  bool _showGradCam = true;

  Future<void> _saveResult() async {
    try {
      if (widget.predictionResult['diseaseName'] == 'No Leaf Detected' || 
          widget.predictionResult['diseaseName'] == 'Analysis Error') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot save invalid image analysis'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final scan = ScanResult(
        id: const Uuid().v4(),
        plantName: 'Tomato',
        healthStatus: widget.predictionResult['diseaseName'] ?? 'Unknown',
        confidence: widget.predictionResult['confidence'] ?? 0.0,
        date: DateTime.now().toString().split(' ')[0],
        imagePath: widget.imageFile is File ? widget.imageFile.path : widget.imageFile.toString(),
        overlayImageBase64: widget.predictionResult['overlayBase64'],
        heatmapBase64: widget.predictionResult['heatmapBase64'],
      );
      
      await StorageService().saveScan(scan);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Result saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _shareResult() async {
    try {
      final diseaseName = widget.predictionResult['diseaseName'] as String? ?? 'Unknown';
      final confidence = widget.predictionResult['confidence'] as double? ?? 0.0;
      
      String shareText = "🌿 LeafDoctor AI Analysis Results\n\n";
      shareText += "🍅 Plant: Tomato\n";
      shareText += "🦠 Disease: $diseaseName\n";
      shareText += "📊 Confidence: ${confidence.toStringAsFixed(1)}%\n";
      shareText += "📅 Date: ${DateTime.now().toString().split(' ')[0]}\n\n";
      shareText += "Download LeafDoctor AI for accurate plant disease detection!";
      
      await Share.share(shareText);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final diseaseName = widget.predictionResult['diseaseName'] as String? ?? 'Unknown';
    
    if (diseaseName == 'No Leaf Detected') {
      return _buildMessageScreen(
        icon: LucideIcons.image,
        title: "No Leaf Detected",
        message: widget.predictionResult['message'] ?? 'No leaf detected in the image.',
        color: Colors.orange,
      );
    }
    
    if (diseaseName == 'Unable to Identify') {
      return _buildMessageScreen(
        icon: LucideIcons.helpCircle,
        title: "Unable to Identify",
        message: widget.predictionResult['message'] ?? 'Unable to confidently identify the disease.',
        color: Colors.orange,
      );
    }
    
    if (diseaseName == 'Analysis Error') {
      return _buildMessageScreen(
        icon: LucideIcons.alertTriangle,
        title: "Analysis Failed",
        message: widget.predictionResult['message'] ?? 'An error occurred during analysis.',
        color: Colors.red,
      );
    }
    
    return _buildResultScreen();
  }

  Widget _buildMessageScreen({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.imageFile is File)
                  Container(
                    height: 200,
                    width: 200,
                    margin: const EdgeInsets.only(bottom: 30),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: FileImage(widget.imageFile as File),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Icon(icon, size: 80, color: color),
                const SizedBox(height: 20),
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 16)),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.arrowLeft),
                  label: const Text("Try Again"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final diseaseName = widget.predictionResult['diseaseName'] as String? ?? 'Unknown';
    final confidence = widget.predictionResult['confidence'] as double? ?? 0.0;
    final isHealthy = widget.predictionResult['isHealthy'] as bool? ?? false;
    final hasGradCam = widget.predictionResult['overlayBase64'] != null;
    
    final disease = diseases.firstWhere(
      (d) => d.name.contains(diseaseName) || diseaseName.contains(d.name),
      orElse: () => diseases.first,
    );
    
    final typeColor = getTypeColor(disease.type);
    Uint8List? overlayImage = hasGradCam 
        ? base64Decode(widget.predictionResult['overlayBase64'])
        : null;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.arrowLeft, color: AppColors.lightTextPrimary),
                    ),
                    const SizedBox(width: 8),
                    Text("Analysis Result", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(onPressed: _saveResult, icon: const Icon(LucideIcons.save, color: AppColors.emerald)),
                    IconButton(onPressed: _shareResult, icon: const Icon(LucideIcons.share2)),
                  ],
                ),
              ),
              
              // Image with Grad-CAM toggle
              Stack(
                children: [
                  Container(
                    height: 280,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _showGradCam && overlayImage != null
                          ? Image.memory(overlayImage, fit: BoxFit.cover)
                          : widget.imageFile is File
                              ? Image.file(widget.imageFile as File, fit: BoxFit.cover)
                              : Image.network(widget.imageFile.toString(), fit: BoxFit.cover),
                    ),
                  ),
                  
                  // Grad-CAM Toggle Button
                  if (hasGradCam)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _showGradCam = !_showGradCam),
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _showGradCam ? LucideIcons.eye : LucideIcons.eyeOff,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _showGradCam ? "Grad-CAM++ ON" : "Original",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Confidence badge
                  Positioned(
                    top: 16,
                    right: 36,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified, size: 16, color: confidence > 90 ? Colors.green : Colors.orange),
                          const SizedBox(width: 4),
                          Text("${confidence.toStringAsFixed(1)}% Match", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Disease info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Detected Condition", style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.lightTextSecondary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isHealthy ? "Healthy Plant" : disease.name,
                            style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (!isHealthy)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: typeColor.withOpacity(0.3)),
                            ),
                            child: Text(disease.type, style: TextStyle(color: typeColor, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    
                    if (hasGradCam)
                      const SizedBox(height: 12),
                    if (hasGradCam)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.thermometer, size: 16, color: AppColors.emerald),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Grad-CAM++ visualization highlights regions that influenced the prediction",
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.lightTextSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              if (!isHealthy)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          icon: LucideIcons.info,
                          label: "Details",
                          color: Colors.blue,
                          onTap: () => Navigator.pushNamed(context, '/disease-detail', arguments: disease),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          icon: LucideIcons.activity,
                          label: "Treatment",
                          color: Colors.green,
                          onTap: () => _showTreatment(context, disease),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Disease description
              if (!isHealthy) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x1A000000)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("About ${disease.name}", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Text(disease.description, style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x1A000000)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Common Symptoms", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        ...disease.symptoms.map((symptom) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 6, color: typeColor),
                              const SizedBox(width: 8),
                              Expanded(child: Text(symptom, style: GoogleFonts.plusJakartaSans(fontSize: 14))),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 30),
              
              // New scan button
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                      Navigator.pushNamed(context, '/analyzer');
                    },
                    child: Ink(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.emerald, AppColors.emerald.withOpacity(0.7)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.camera, color: Colors.white),
                          const SizedBox(width: 8),
                          Text("New Scan", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  void _showTreatment(BuildContext context, DiseaseModel disease) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.lightSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0x1A000000),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Treatment",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          disease.treatment,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppColors.lightTextSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Prevention Tips",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...disease.preventionTips.map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.check, size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}