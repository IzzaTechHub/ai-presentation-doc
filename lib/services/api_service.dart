import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/slide_model.dart';
import '../models/template_model.dart';
import 'app_exception.dart';
import 'error_handler.dart';

class ApiService {
  // Deployed production Vercel backend URL
  static String get baseUrl => 'https://ai-presentation-backend.vercel.app';

  // Request timeout thresholds
  static const Duration _fetchTimeout = Duration(seconds: 15);
  static const Duration _promptTimeout = Duration(seconds: 20);
  static const Duration _generateTimeout = Duration(seconds: 45);
  static const Duration _compileTimeout = Duration(seconds: 40);

  /// Fetches the list of all available presentation templates from the backend.
  static Future<List<TemplateModel>> fetchTemplates() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/templates'))
          .timeout(_fetchTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((item) => TemplateModel.fromJson(item)).toList();
      }

      if (response.statusCode >= 500) {
        throw const AppException(
          title: "Templates Unavailable",
          message: "The presentation templates could not be loaded from the server. Please try again shortly.",
          type: ErrorType.server,
        );
      }

      throw const AppException(
        title: "Connection Notice",
        message: "Unable to retrieve templates. Please check your connection and tap retry.",
        type: ErrorType.client,
      );
    } catch (e) {
      throw ErrorHandler.parse(e);
    }
  }

  /// Sends the presentation topic parameters to the backend to generate the slides JSON structures.
  static Future<List<SlideModel>> generateSlides({
    required String topic,
    required int slideCount,
    String language = 'en',
  }) async {
    final trimmedTopic = topic.trim();
    if (trimmedTopic.isEmpty) {
      throw const AppException(
        title: "Missing Topic",
        message: "Please enter a topic or description for your presentation.",
        type: ErrorType.client,
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/generate'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'topic': trimmedTopic,
              'slideCount': slideCount,
              'language': language,
            }),
          )
          .timeout(_generateTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        if (jsonList.isEmpty) {
          throw const AppException(
            title: "Empty Presentation",
            message: "The AI did not produce any slides for this topic. Please try with more descriptive details.",
            type: ErrorType.parse,
          );
        }
        return jsonList.map((item) => SlideModel.fromJson(item)).toList();
      }

      if (response.statusCode == 429) {
        throw const AppException(
          title: "Generation Cooldown",
          message: "Too many presentations requested in a short time. Please wait a minute before generating again.",
          type: ErrorType.rateLimit,
        );
      }

      if (response.statusCode >= 500) {
        throw const AppException(
          title: "AI Service Busy",
          message: "The slide generation engine is currently experiencing high demand. Please try again in a few moments.",
          type: ErrorType.server,
        );
      }

      // Check for user-friendly error string in JSON body if provided
      String? friendlyMessage;
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('error')) {
          final errStr = decoded['error'].toString();
          // Shield internal technical messages
          if (!errStr.contains('http') &&
              !errStr.contains('{') &&
              !errStr.contains('.vercel') &&
              errStr.length < 100) {
            friendlyMessage = errStr;
          }
        }
      } catch (_) {}

      throw AppException(
        title: "Generation Notice",
        message: friendlyMessage ?? "Unable to complete slide generation. Please check your topic and try again.",
        type: ErrorType.client,
      );
    } catch (e) {
      throw ErrorHandler.parse(e);
    }
  }

  /// Sends the edited slides list and template to compile and download the PPTX binary.
  static Future<Uint8List> generatePPTX({
    required List<SlideModel> slides,
    required String templateId,
  }) async {
    if (slides.isEmpty) {
      throw const AppException(
        title: "No Slides to Export",
        message: "Your presentation has no slides to compile. Add at least one slide before exporting.",
        type: ErrorType.client,
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/generate'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'slides': slides.map((s) => s.toJson()).toList(),
              'templateId': templateId,
            }),
          )
          .timeout(_compileTimeout);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }

      if (response.statusCode >= 500) {
        throw const AppException(
          title: "Compiler Temporarily Offline",
          message: "The PPTX PowerPoint compiler is currently unavailable. Please try again in a few moments.",
          type: ErrorType.server,
        );
      }

      throw const AppException(
        title: "Compilation Issue",
        message: "Unable to assemble presentation file. Please try again.",
        type: ErrorType.client,
      );
    } catch (e) {
      throw ErrorHandler.parse(e);
    }
  }

  /// Sends the presentation prompt parameters to the backend to optimize/perfect it.
  static Future<String> perfectPrompt({
    required String prompt,
    String language = 'en',
  }) async {
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      throw const AppException(
        title: "Empty Prompt",
        message: "Please write an initial prompt before optimizing.",
        type: ErrorType.client,
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/perfect-prompt'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'prompt': trimmedPrompt,
              'language': language,
            }),
          )
          .timeout(_promptTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final perfected = responseData['perfectedPrompt'];
        if (perfected != null && perfected.toString().trim().isNotEmpty) {
          return perfected.toString();
        }
        throw const AppException(
          title: "Optimization Incomplete",
          message: "The AI did not return an enhanced prompt. Please try again.",
          type: ErrorType.parse,
        );
      }

      if (response.statusCode == 429) {
        throw const AppException(
          title: "Please Wait",
          message: "Prompt enhancer is cooling down. Please wait a moment before trying again.",
          type: ErrorType.rateLimit,
        );
      }

      if (response.statusCode >= 500) {
        throw const AppException(
          title: "Enhancer Temporarily Offline",
          message: "The prompt optimization assistant is temporarily busy. Please try again shortly.",
          type: ErrorType.server,
        );
      }

      throw const AppException(
        title: "Optimization Failed",
        message: "Unable to optimize prompt at this moment. Please try again.",
        type: ErrorType.client,
      );
    } catch (e) {
      throw ErrorHandler.parse(e);
    }
  }
}
