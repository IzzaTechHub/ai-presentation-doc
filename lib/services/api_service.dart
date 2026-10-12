import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/slide_model.dart';
import '../models/template_model.dart';

class ApiService {
  // Deployed production Vercel backend URL
  static String get baseUrl => 'https://ai-presentation-backend.vercel.app';
  // static String get baseUrl => kDebugMode
  //     ? 'http://localhost:3000'
  //     : 'https://ai-presentation-backend.vercel.app';

  /// Fetches the list of all available presentation templates from the backend.
  static Future<List<TemplateModel>> fetchTemplates() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/templates'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((item) => TemplateModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load templates: Server returned status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }

  /// Sends the presentation topic parameters to Gemini to generate the slides JSON structures.
  static Future<List<SlideModel>> generateSlides({
    required String topic,
    required int slideCount,
    String language = 'en',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'topic': topic,
          'slideCount': slideCount,
          'language': language,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((item) => SlideModel.fromJson(item)).toList();
      } else {
        // Parse error message if available
        Map<String, dynamic>? errorJson;
        try {
          errorJson = json.decode(response.body);
        } catch (_) {}
        
        final errorMsg = errorJson?['error'] ?? 'Server returned status ${response.statusCode}';
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception('Failed to generate slides: $e');
    }
  }

  /// Sends the edited slides list and template to compile and download the PPTX binary.
  static Future<Uint8List> generatePPTX({
    required List<SlideModel> slides,
    required String templateId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'slides': slides.map((s) => s.toJson()).toList(),
          'templateId': templateId,
        }),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        Map<String, dynamic>? errorJson;
        try {
          errorJson = json.decode(response.body);
        } catch (_) {}
        final errorMsg = errorJson?['error'] ?? 'Server returned status ${response.statusCode}';
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception('Failed to compile PPTX presentation: $e');
    }
  }

  /// Sends the presentation prompt parameters to Gemini to optimize/perfect it.
  static Future<String> perfectPrompt({
    required String prompt,
    String language = 'en',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/perfect-prompt'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'prompt': prompt,
          'language': language,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['perfectedPrompt'] ?? '';
      } else {
        Map<String, dynamic>? errorJson;
        try {
          errorJson = json.decode(response.body);
        } catch (_) {}
        
        final errorMsg = errorJson?['error'] ?? 'Server returned status ${response.statusCode}';
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception('Failed to perfect prompt: $e');
    }
  }
}

