import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// Free media hosting via Cloudinary (25 GB storage + 25 GB bandwidth/month
/// on the free tier — no credit card required).
///
/// Setup:
/// 1. Sign up at https://cloudinary.com — free
/// 2. From the dashboard copy your **Cloud Name**
/// 3. Settings → Upload → Add upload preset → Signing mode = **Unsigned**
///    Give it a name (e.g. `better_you_unsigned`) and save
/// 4. Add to your .env file:
///       CLOUDINARY_CLOUD_NAME=your_cloud_name
///       CLOUDINARY_UPLOAD_PRESET=better_you_unsigned
class CloudinaryService {
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  bool get isConfigured => _cloudName.isNotEmpty && _uploadPreset.isNotEmpty;

  /// Uploads a file and returns its public secure URL, or null on failure.
  /// [resourceType] is one of: image, video, raw, auto. For audio use `video`
  /// (Cloudinary treats audio under the `video` resource type).
  /// [folder] organises uploads inside Cloudinary (e.g. "chat_images/roomId").
  Future<String?> uploadFile(
    String filePath, {
    String resourceType = 'image',
    String? folder,
    String? publicId,
  }) async {
    if (!isConfigured) {
      AppLogger.e('Cloudinary not configured. Set CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET in .env');
      return null;
    }

    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      if (folder != null) request.fields['folder'] = folder;
      if (publicId != null) request.fields['public_id'] = publicId;

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        AppLogger.e('Cloudinary upload failed (${response.statusCode}): ${response.body}');
        return null;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      return body['secure_url'] as String?;
    } catch (e, st) {
      AppLogger.e('Cloudinary upload error', e, st);
      return null;
    }
  }

  /// Convenience: upload an image (jpeg/png/webp).
  Future<String?> uploadImage(String filePath, {String? folder}) {
    return uploadFile(filePath, resourceType: 'image', folder: folder);
  }

  /// Convenience: upload an audio file (m4a, mp3, wav...).
  /// Cloudinary stores audio under resource_type=video.
  Future<String?> uploadAudio(String filePath, {String? folder}) {
    return uploadFile(filePath, resourceType: 'video', folder: folder);
  }

  /// Quick file size check before upload to avoid wasted bandwidth.
  Future<int> getFileSizeBytes(String filePath) async {
    return await File(filePath).length();
  }
}
