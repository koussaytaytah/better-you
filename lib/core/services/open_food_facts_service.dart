import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// Open Food Facts is a free, open, crowdsourced food database.
/// No API key required. https://world.openfoodfacts.org/data
class OpenFoodFactsService {
  static const _base = 'https://world.openfoodfacts.org';
  // OFF asks every consumer to set a descriptive User-Agent.
  static const _userAgent = 'BetterYou/1.0 (Flutter; abdou.ouni.001@gmail.com)';

  static const _headers = {
    'User-Agent': _userAgent,
    'Accept': 'application/json',
  };

  /// Search by free text. Returns up to [pageSize] products.
  Future<List<OffProduct>> searchByName(String query, {int pageSize = 20}) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse(
      '$_base/cgi/search.pl'
      '?search_terms=${Uri.encodeQueryComponent(query)}'
      '&search_simple=1&action=process&json=1&page_size=$pageSize'
      '&fields=code,product_name,brands,image_small_url,nutriments,serving_size,quantity',
    );
    try {
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final body = json.decode(res.body) as Map<String, dynamic>;
      final products = (body['products'] as List?) ?? const [];
      return products
          .map((e) => OffProduct.fromJson(e as Map<String, dynamic>))
          .where((p) => p.name.isNotEmpty)
          .toList();
    } catch (e) {
      AppLogger.e('OpenFoodFacts search failed', e);
      return [];
    }
  }

  /// Look up a product by barcode (EAN/UPC).
  Future<OffProduct?> getByBarcode(String barcode) async {
    final uri = Uri.parse('$_base/api/v2/product/$barcode.json');
    try {
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body) as Map<String, dynamic>;
      if (body['status'] != 1) return null;
      final product = body['product'] as Map<String, dynamic>;
      return OffProduct.fromJson({...product, 'code': barcode});
    } catch (e) {
      AppLogger.e('OpenFoodFacts barcode lookup failed', e);
      return null;
    }
  }
}

/// Lightweight DTO covering the fields we use.
class OffProduct {
  final String barcode;
  final String name;
  final String brand;
  final String? imageUrl;
  final String? servingSize;
  final String? quantity;

  /// Per 100g unless noted.
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double sugarsPer100g;
  final double fiberPer100g;

  OffProduct({
    required this.barcode,
    required this.name,
    required this.brand,
    this.imageUrl,
    this.servingSize,
    this.quantity,
    this.caloriesPer100g = 0,
    this.proteinPer100g = 0,
    this.carbsPer100g = 0,
    this.fatPer100g = 0,
    this.sugarsPer100g = 0,
    this.fiberPer100g = 0,
  });

  factory OffProduct.fromJson(Map<String, dynamic> j) {
    final n = (j['nutriments'] as Map<String, dynamic>?) ?? const {};
    double d(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    return OffProduct(
      barcode: (j['code'] ?? '').toString(),
      name: (j['product_name'] ?? '').toString().trim(),
      brand: (j['brands'] ?? '').toString().trim(),
      imageUrl: (j['image_small_url'] ?? j['image_url'])?.toString(),
      servingSize: j['serving_size']?.toString(),
      quantity: j['quantity']?.toString(),
      caloriesPer100g: d(n['energy-kcal_100g'] ?? n['energy-kcal'] ?? 0),
      proteinPer100g: d(n['proteins_100g']),
      carbsPer100g: d(n['carbohydrates_100g']),
      fatPer100g: d(n['fat_100g']),
      sugarsPer100g: d(n['sugars_100g']),
      fiberPer100g: d(n['fiber_100g']),
    );
  }

  /// Returns macros scaled to a chosen weight (grams).
  Map<String, double> macrosFor(double grams) {
    final factor = grams / 100.0;
    return {
      'calories': caloriesPer100g * factor,
      'protein': proteinPer100g * factor,
      'carbs': carbsPer100g * factor,
      'fat': fatPer100g * factor,
      'sugars': sugarsPer100g * factor,
      'fiber': fiberPer100g * factor,
    };
  }
}
