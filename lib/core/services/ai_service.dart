import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/constants/app_constants.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/daily_log_model.dart';
import '../utils/logger.dart';

class AIService {
  // Groq Models
  static const String chatModel = 'llama-3.3-70b-versatile';
  static const String visionModel = 'llama-3.2-90b-vision-preview';
  static const String whisperModel = 'whisper-large-v3';

  Future<String> getAIResponse(
    String message, {
    UserModel? user,
    DailyLog? todayLog,
    String? base64Image,
  }) async {
    try {
      String userContext = "";
      if (user != null) {
        userContext =
            "User Info: Name: ${user.name}, Age: ${user.age ?? 'N/A'}, Weight: ${user.weight ?? 'N/A'}kg, Target: ${user.targetWeight ?? 'N/A'}kg. ";
      }
      if (todayLog != null) {
        userContext +=
            "Today's Stats: Calories: ${todayLog.calories ?? 0}, Cigarettes: ${todayLog.cigarettes ?? 0}, Exercise: ${todayLog.exerciseMinutes ?? 0}m. ";
      }

      final List<Map<String, dynamic>> messages = [
        {
          'role': 'system',
          'content':
              'You are the "Better You" AI health assistant. $userContext'
              'Your goal is to provide encouraging, science-based, and practical health advice. '
              'CRITICAL: Always respond in the same language as the user\'s message. '
              'ONLY translate to another language if the user explicitly asks you to translate. '
              'Answer in short, professional, and direct terms. Use bullet points if helpful. '
              'Be empathetic but highly efficient.',
        },
      ];

      if (base64Image != null) {
        messages.add({
          'role': 'user',
          'content': [
            {'type': 'text', 'text': message},
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
                'detail': 'low',
              },
            },
          ],
        });
      } else {
        messages.add({'role': 'user', 'content': message});
      }

      final response = await http.post(
        Uri.parse(AppConstants.groqApiUrl),
        headers: {
          'Authorization': 'Bearer ${AppConstants.groqToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': base64Image != null ? visionModel : chatModel,
          'messages': messages,
          'temperature': 0.5,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ??
            'I\'m here to help with your health journey!';
      } else {
        final errorData = jsonDecode(response.body);
        AppLogger.e('Groq API Error: ${response.statusCode} - $errorData');
        return 'Sorry, I\'m having trouble connecting to my brain right now. Please try again later.';
      }
    } catch (e, stack) {
      AppLogger.e('AI Service Exception', e, stack);
      return 'Error connecting to AI service. Please check your connection.';
    }
  }

  Future<String?> transcribeAudio(String filePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions'),
      );

      request.headers['Authorization'] = 'Bearer ${AppConstants.groqToken}';
      request.fields['model'] = whisperModel;

      if (kIsWeb) {
        final response = await http.get(Uri.parse(filePath));
        final bytes = response.bodyBytes;
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'audio.m4a',
            contentType: MediaType('audio', 'mpeg'),
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            filePath,
            contentType: MediaType('audio', 'mpeg'),
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        return data['text'];
      } else {
        AppLogger.e(
          'Groq Transcription Error: ${response.statusCode} - $responseData',
        );
        return null;
      }
    } catch (e, stack) {
      AppLogger.e('Transcription Exception', e, stack);
      return null;
    }
  }

  Future<Map<String, dynamic>?> parseQuickLog(String message) async {
    try {
      final prompt =
          """
        You are a health data parser for the "Better You" app.
        The user said: "$message"

        Extract health data into a JSON format with the following keys if present:
        - "calories" (integer)
        - "protein_g" (double)
        - "fat_g" (double)
        - "carbs_g" (double)
        - "water_glasses" (integer)
        - "exercise_minutes" (integer)
        - "cigarettes" (integer)
        - "sleep_hours" (double)
        - "alcohol_units" (double)
        - "steps" (integer)
        - "meal_description" (string)

        Return ONLY a JSON object. If no data is found, return an empty JSON object {}.
        Example: "I had a sandwich (400 cal), ran for 20 mins and took 5000 steps" -> {"calories": 400, "exercise_minutes": 20, "steps": 5000, "meal_description": "Sandwich"}
        """;

      final response = await http.post(
        Uri.parse(AppConstants.groqApiUrl),
        headers: {
          'Authorization': 'Bearer ${AppConstants.groqToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': chatModel,
          'messages': [
            {'role': 'system', 'content': 'You are a precise JSON extractor.'},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.1,
          'max_tokens': 150,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'] ?? "{}";
        AppLogger.d('Raw AI Response: $content');

        // Extract JSON if AI added extra text
        if (content.contains('{')) {
          content = content.substring(
            content.indexOf('{'),
            content.lastIndexOf('}') + 1,
          );
        }

        try {
          final decoded = jsonDecode(content);
          return decoded;
        } catch (e) {
          AppLogger.e('JSON Parse Error: $e. Content was: $content');
          return null;
        }
      } else {
        AppLogger.e(
          'Groq API Error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e, stack) {
      AppLogger.e('Parse Quick Log Exception', e, stack);
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzeFoodImage(String base64Image) async {
    try {
      final prompt = """
        You are an expert nutritionist. Analyze this food image with extremely high precision. 
        Identify the dish, estimate the exact portion size visually, and calculate the precise macronutrients based on professional nutritional databases.
        Return ONLY a valid JSON object with these keys and exact data types:
        - "name" (string, the specific food name + estimated portion, e.g., "Grilled Salmon (150g)")
        - "calories" (integer, strictly numeric total calories)
        - "protein" (double, strictly numeric protein in grams)
        - "carbs" (double, strictly numeric total carbohydrates in grams)
        - "fat" (double, strictly numeric total fat in grams)

        Example: {"name": "Chicken Salad (300g)", "calories": 345, "protein": 26.5, "carbs": 12.0, "fat": 14.5}
        DO NOT include any markdown, code blocks, or introductory text. Return ONLY the raw JSON object.
        """;

      final apiKey = AppConstants.geminiToken;
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
             'responseMimeType': 'application/json',
             'temperature': 0.1,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['candidates'][0]['content']['parts'][0]['text'] ?? "{}";
        AppLogger.d('Raw Food Analysis Response: $content');

        if (content.contains('{')) {
          content = content.substring(
            content.indexOf('{'),
            content.lastIndexOf('}') + 1,
          );
        }

        try {
          return jsonDecode(content);
        } catch (e) {
          AppLogger.e('Food Analysis JSON Parse Error: $e. Content: $content');
          return null;
        }
      } else {
        AppLogger.e('Food Analysis API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stack) {
      AppLogger.e('Food Analysis Exception', e, stack);
      return null;
    }
  }

}

