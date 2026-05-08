import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/open_food_facts_service.dart';

/// Search screen backed by Open Food Facts (free, no API key).
class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _searchController = TextEditingController();
  final _service = OpenFoodFactsService();

  Timer? _debounce;
  bool _loading = false;
  List<OffProduct> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final results = await _service.searchByName(query);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Database'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search food (e.g. Coca Cola, banana)',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _results = []);
                        },
                      ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _results.isEmpty && !_loading
                ? _buildEmpty(isDark)
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _results.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _ProductTile(
                      product: _results[i],
                      onTap: () => _showDetails(_results[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_outlined,
                size: 80, color: Colors.grey[isDark ? 700 : 300]),
            const SizedBox(height: 16),
            Text('Search 3M+ foods worldwide',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Powered by Open Food Facts — free & open data',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(OffProduct p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProductDetailSheet(product: p),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final OffProduct product;
  final VoidCallback onTap;
  const _ProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 56,
            height: 56,
            child: product.imageUrl != null
                ? Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => _placeholder(),
                  )
                : _placeholder(),
          ),
        ),
        title: Text(product.name,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            if (product.brand.isNotEmpty) product.brand,
            '${product.caloriesPer100g.toStringAsFixed(0)} kcal / 100g',
          ].join('  •  '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.fastfood, color: Colors.grey),
      );
}

class _ProductDetailSheet extends StatefulWidget {
  final OffProduct product;
  const _ProductDetailSheet({required this.product});

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  double _grams = 100;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final macros = p.macrosFor(_grams);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (p.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(p.imageUrl!, width: 64, height: 64, fit: BoxFit.cover),
                  ),
                if (p.imageUrl != null) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: GoogleFonts.inter(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      if (p.brand.isNotEmpty)
                        Text(p.brand, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Portion: ${_grams.toStringAsFixed(0)} g',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            Slider(
              min: 10,
              max: 500,
              divisions: 49,
              value: _grams,
              label: '${_grams.toStringAsFixed(0)} g',
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _grams = v),
            ),
            const SizedBox(height: 16),
            _macroRow('Calories', '${macros['calories']!.toStringAsFixed(0)} kcal', Colors.orange),
            _macroRow('Protein', '${macros['protein']!.toStringAsFixed(1)} g', Colors.red),
            _macroRow('Carbs', '${macros['carbs']!.toStringAsFixed(1)} g', Colors.blue),
            _macroRow('Fat', '${macros['fat']!.toStringAsFixed(1)} g', Colors.purple),
            if (macros['sugars']! > 0)
              _macroRow('Sugars', '${macros['sugars']!.toStringAsFixed(1)} g', Colors.pink),
            if (macros['fiber']! > 0)
              _macroRow('Fiber', '${macros['fiber']!.toStringAsFixed(1)} g', Colors.green),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.pop(context, {
                    'name': p.name,
                    'brand': p.brand,
                    'grams': _grams,
                    ...macros,
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Add to my log',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Data: Open Food Facts (CC-BY-SA)',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }
}
