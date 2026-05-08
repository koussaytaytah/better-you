import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';

class EnhancedFoodDetectionScreen extends ConsumerStatefulWidget {
  const EnhancedFoodDetectionScreen({super.key});

  @override
  ConsumerState<EnhancedFoodDetectionScreen> createState() => _EnhancedFoodDetectionScreenState();
}

class _EnhancedFoodDetectionScreenState extends ConsumerState<EnhancedFoodDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _detectedData;
  bool _multiItemMode = true;
  List<Map<String, dynamic>> _selectedItems = [];

  Future<void> _analyzeImage(XFile image) async {
    setState(() {
      _selectedImage = image;
      _isAnalyzing = true;
      _detectedData = null;
      _selectedItems = [];
    });

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final aiService = ref.read(aiServiceProvider);
      
      if (_multiItemMode) {
        final result = await aiService.analyzeFoodImageMultiItem(base64Image);
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _detectedData = result ?? {
              'meal_name': 'Detection failed. Please try again.',
              'items': [],
              'total_calories': 0,
              'total_protein': 0.0,
              'total_carbs': 0.0,
              'total_fat': 0.0,
            };
            _selectedItems = List<Map<String, dynamic>>.from(
              (_detectedData!['items'] as List<dynamic>? ?? []),
            );
          });
        }
      } else {
        final result = await aiService.analyzeFoodImage(base64Image);
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _detectedData = result != null
                ? {
                    'meal_name': result['name'] ?? 'Unknown Dish',
                    'items': [result],
                    'total_calories': result['calories'] ?? 0,
                    'total_protein': result['protein'] ?? 0.0,
                    'total_carbs': result['carbs'] ?? 0.0,
                    'total_fat': result['fat'] ?? 0.0,
                  }
                : {
                    'meal_name': 'Detection failed. Please try again.',
                    'items': [],
                    'total_calories': 0,
                    'total_protein': 0.0,
                    'total_carbs': 0.0,
                    'total_fat': 0.0,
                  };
            _selectedItems = List<Map<String, dynamic>>.from(_detectedData!['items'] as List);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _detectedData = {
            'meal_name': 'Error: $e',
            'items': [],
            'total_calories': 0,
            'total_protein': 0.0,
            'total_carbs': 0.0,
            'total_fat': 0.0,
          };
        });
      }
    }
  }

  Future<void> _getRecipeFromImage() async {
    if (_selectedImage == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final aiService = ref.read(aiServiceProvider);
      final result = await aiService.getRecipeFromImage(base64Image);

      if (mounted && result != null) {
        _showRecipeDialog(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting recipe: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _showRecipeDialog(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recipe['dish_name'] ?? 'Recipe'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (recipe['description'] != null)
                Text(recipe['description'], style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              Text('Ingredients:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ...List<String>.from(recipe['ingredients'] ?? [])
                  .map((ing) => Text('• $ing')),
              const SizedBox(height: 16),
              Text('Instructions:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ...List<String>.from(recipe['instructions'] ?? [])
                  .asMap()
                  .entries
                  .map((e) => Text('${e.key + 1}. ${e.value}')),
              const SizedBox(height: 16),
              Text(
                '${recipe['calories_per_serving']} cal • ${recipe['prep_time_minutes'] + recipe['cook_time_minutes']} min',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _logSelectedItems() async {
    final user = ref.read(currentUserAsyncProvider).value;
    final lastLog = ref.read(todayLogProvider).value;

    if (user == null || lastLog == null) return;

    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final item in _selectedItems) {
      totalCalories += (item['calories'] as num).toInt();
      totalProtein += (item['protein'] as num).toDouble();
      totalCarbs += (item['carbs'] as num).toDouble();
      totalFat += (item['fat'] as num).toDouble();
    }

    final data = {
      'calories': (lastLog.calories ?? 0) + totalCalories,
      'protein': (lastLog.protein ?? 0) + totalProtein,
      'carbs': (lastLog.carbs ?? 0) + totalCarbs,
      'fat': (lastLog.fat ?? 0) + totalFat,
    };

    await ref.read(dailyLogRepositoryProvider).updateDailyLog(user.uid, DateTime.now(), data);
    ref.invalidate(todayLogProvider);

    await ref.read(userRepositoryProvider).addXP(user.uid, 50);
    await ref.read(userRepositoryProvider).checkAndAwardBadges(user.uid);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $totalCalories calories to your log!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _toggleItemSelection(Map<String, dynamic> item) {
    setState(() {
      final index = _selectedItems.indexWhere((i) => i['name'] == item['name']);
      if (index >= 0) {
        _selectedItems.removeAt(index);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = (_detectedData?['items'] as List<dynamic>?) ?? [];
    final hasResults = _detectedData != null && items.isNotEmpty;
    _selectedItems.fold<int>(
      0,
      (sum, item) => sum + (item['calories'] as num).toInt(),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppColors.primary,
            title: Text(
              'AI Food Detection',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildModeToggle(),
                  const SizedBox(height: 24),
                  _buildImagePicker(),
                  const SizedBox(height: 24),
                  if (_isAnalyzing) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _multiItemMode
                          ? 'Detecting multiple food items...'
                          : 'Analyzing food with AI...',
                      style: GoogleFonts.poppins(),
                    ),
                  ] else if (hasResults) ...[
                    _buildResultsHeader(),
                    const SizedBox(height: 16),
                    _buildItemsList(items),
                    const SizedBox(height: 16),
                    _buildTotalSummary(),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: hasResults
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectedItems.isEmpty ? null : _logSelectedItems,
                            icon: const Icon(Icons.add_circle),
                            label: Text('Log \$selectedTotalCalories cal'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _getRecipeFromImage,
                            icon: const Icon(Icons.restaurant_menu),
                            label: const Text('Get Recipe'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedItems.length} of ${items.length} items selected',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _multiItemMode = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _multiItemMode ? Colors.white : null,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _multiItemMode
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.grid_view,
                      size: 18,
                      color: _multiItemMode ? AppColors.primary : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Multi-Item',
                      style: TextStyle(
                        color: _multiItemMode ? AppColors.primary : Colors.grey,
                        fontWeight: _multiItemMode ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _multiItemMode = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_multiItemMode ? Colors.white : null,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: !_multiItemMode
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.crop_original,
                      size: 18,
                      color: !_multiItemMode ? AppColors.primary : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Single Item',
                      style: TextStyle(
                        color: !_multiItemMode ? AppColors.primary : Colors.grey,
                        fontWeight: !_multiItemMode ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            final XFile? image = await _picker.pickImage(source: ImageSource.camera);
            if (image != null) await _analyzeImage(image);
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
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () async {
            final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
            if (image != null) await _analyzeImage(image);
          },
          icon: const Icon(Icons.photo_library),
          label: const Text('Upload from Gallery'),
        ),
      ],
    );
  }

  Widget _buildResultsHeader() {
    return Column(
      children: [
        Text(
          _detectedData!['meal_name'] ?? 'Detected Meal',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap items to select which ones to log',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildItemsList(List<dynamic> items) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value as Map<String, dynamic>;
        final isSelected = _selectedItems.any((i) => i['name'] == item['name']);

        return GestureDetector(
          onTap: () => _toggleItemSelection(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? 'Unknown Item',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildMacroChip('${(item['calories'] as num).round()} cal', Colors.orange),
                          const SizedBox(width: 8),
                          _buildMacroChip('P: ${(item['protein'] as num).toStringAsFixed(1)}g', Colors.blue),
                          const SizedBox(width: 8),
                          _buildMacroChip('C: ${(item['carbs'] as num).toStringAsFixed(1)}g', Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMacroChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTotalSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Total Selected',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTotalItem('${_selectedItems.fold<int>(0, (sum, i) => sum + (i['calories'] as num).toInt())}', 'Calories', Colors.orange),
              _buildTotalItem('${_selectedItems.fold<double>(0, (sum, i) => sum + (i['protein'] as num).toDouble()).toStringAsFixed(1)}g', 'Protein', Colors.blue),
              _buildTotalItem('${_selectedItems.fold<double>(0, (sum, i) => sum + (i['carbs'] as num).toDouble()).toStringAsFixed(1)}g', 'Carbs', Colors.green),
              _buildTotalItem('${_selectedItems.fold<double>(0, (sum, i) => sum + (i['fat'] as num).toDouble()).toStringAsFixed(1)}g', 'Fat', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
