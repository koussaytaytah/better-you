import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class AIService {
  Future<String> getAIResponse(String message) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${AppConstants.huggingFaceApiUrl}${AppConstants.huggingFaceModel}',
        ),
        headers: {
          'Authorization': 'Bearer ${AppConstants.huggingFaceToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': message,
          'parameters': {'max_length': 100, 'temperature': 0.7},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0]['generated_text'] ??
              'I\'m here to help with your health journey!';
        }
      }
      return 'Sorry, I couldn\'t generate a response right now. Please try again.';
    } catch (e) {
      return 'Error connecting to AI service. Please check your connection.';
    }
  }
}
