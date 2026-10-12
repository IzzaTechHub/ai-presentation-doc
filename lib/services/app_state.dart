import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/slide_model.dart';
import '../models/template_model.dart';

class AppState {
  static List<SlideModel>? activeSlides;
  static TemplateModel? selectedTemplate;
  static String currentTopic = '';
  static int currentSlideCount = 8;
  
  static List<Map<String, dynamic>> history = [];

  // Load history from local JSON file
  static Future<void> loadHistoryFromStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/presentation_history.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> decoded = json.decode(contents);
        history = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {}
  }

  // Save history to local JSON file
  static Future<void> saveHistoryToStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/presentation_history.json');
      final contents = json.encode(history);
      await file.writeAsString(contents);
    } catch (_) {}
  }

  // Add a new presentation to history
  static Future<void> addPresentationToHistory({
    required String topic,
    required List<SlideModel> slides,
    required TemplateModel template,
  }) async {
    // Check if it already exists to prevent duplicate entries
    history.removeWhere((item) => item['topic'] == topic);

    final item = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'topic': topic,
      'slideCount': slides.length,
      'templateId': template.id,
      'templateName': template.name,
      'templateJson': {
        'id': template.id,
        'name': template.name,
        'colors': {
          'background': template.colors.background,
          'title': template.colors.title,
          'body': template.colors.body,
          'accent': template.colors.accent,
        },
        'fonts': {
          'title': { 'name': template.fonts.title.name, 'size': template.fonts.title.size, 'bold': template.fonts.title.bold },
          'body': { 'name': template.fonts.body.name, 'size': template.fonts.body.size, 'bold': template.fonts.body.bold }
        },
        'layouts': template.layouts,
      },
      'timestamp': DateTime.now().toIso8601String(),
      'slides': slides.map((s) => s.toJson()).toList(),
    };

    history.insert(0, item);
    await saveHistoryToStorage();
  }
}
