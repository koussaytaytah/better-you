import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../shared/models/daily_log_model.dart';

class AIFoodDetectionScreen extends ConsumerStatefulWidget {
  const AIFoodDetectionScreen({super.key});

  @override
  ConsumerState<AIFoodDetectionScreen> createState() => _AIFoodDetectionScreenState();
}

class _AIFoodDetectionScreenState extends ConsumerState<AIFoodDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _detectedMacros;

  Future<void> _analyzeImage(XFile image) async {
    setState(() {
      _selectedImage = image;
      _isAnalyzing = true;
    });

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await ref.read(aiServiceProvider).analyzeFoodImage(base64Image);

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          if (result != null) {
            _detectedMacros = result;
          } else {
            _detectedMacros = {
              'calories': 0,
              'protein': 0.0,
              'carbs': 0.0,
              'fat': 0.0,
              'name': 'Detection failed. Please try again.',
            };
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _detectedMacros = {
            'calories': 0,
            'protein': 0.0,
            'carbs': 0.0,
            'fat': 0.0,
            'name': 'Error: $e',
          };
        });
      }
    }
  }

  Future<void> _updateLogAndPop(Map<String, dynamic> detectedItems) async {
    final user = ref.read(currentUserAsyncProvider).value;
    final lastLog = ref.read(todayLogProvider).value;

    if (user == null) return;

    if (lastLog != null) {
      final data = {
        'calories': (lastLog.calories ?? 0) + (detectedItems['calories'] as num).toInt(),
        'protein': (lastLog.protein ?? 0) + (detectedItems['protein'] as num).toDouble(),
        'carbs': (lastLog.carbs ?? 0) + (detectedItems['carbs'] as num).toDouble(),
        'fat': (lastLog.fat ?? 0) + (detectedItems['fat'] as num).toDouble(),
      };
      await ref.read(dailyLogRepositoryProvider).updateDailyLog(user.uid, DateTime.now(), data);
      ref.invalidate(todayLogProvider);

      // Award XP for logging a whole meal via AI!
      await ref.read(userRepositoryProvider).addXP(user.uid, 50);
      await ref.read(userRepositoryProvider).checkAndAwardBadges(user.uid);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${detectedItems['calories']} calories to your log!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Food Detection',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  await _analyzeImage(image);
                }
              },
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 8,
                  ),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(File(_selectedImage!.path)),
                          fit: BoxFit.cover,
                        )
                      : const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1546069901-ba9599a7e63c'),
                          fit: BoxFit.cover,
                        ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  await _analyzeImage(image);
                }
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('Upload from Gallery'),
            ),
            if (_isAnalyzing) ...[
              const SizedBox(height: 40),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Analyzing food with AI...', style: GoogleFonts.poppins()),
            ] else if (_detectedMacros != null) ...[
              const SizedBox(height: 40),
              Text(
                _detectedMacros!['name'] ?? 'Unknown Dish',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Plate Breakdown (Macros)',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        children: [
                          CircularProgressIndicator(
                            value: 0.85,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                          const Center(
                            child: Icon(Icons.pie_chart, color: AppColors.primary, size: 36),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildMacroRow('Calories', '${_detectedMacros!['calories']} kcal', Colors.orange),
                          _buildMacroRow('Protein', '${_detectedMacros!['protein']}g', Colors.blue),
                          _buildMacroRow('Carbs', '${_detectedMacros!['carbs']}g', Colors.green),
                          _buildMacroRow('Fat', '${_detectedMacros!['fat']}g', Colors.red),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Go Back'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _detectedMacros == null || _detectedMacros!['calories'] == 0
                        ? null
                        : () => _updateLogAndPop(_detectedMacros!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Add to Log', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department, color: color, size: 16),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
