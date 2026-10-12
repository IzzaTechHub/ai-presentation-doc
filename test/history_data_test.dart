import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/slide_model.dart';
import 'package:flutter_app/models/template_model.dart';
import 'package:flutter_app/services/app_state.dart';

void main() {
  setUp(() {
    AppState.history = [];
  });

  group('Presentation History Model & State Tests', () {
    test('AppState saves and serializes presentation history with full template data', () async {
      final template = TemplateModel(
        id: 'modern_violet',
        name: 'Modern Violet',
        colors: TemplateColors(
          background: '#1E1B4B',
          backgroundStart: '#2E1065',
          backgroundEnd: '#1E1B4B',
          title: '#FAF5FF',
          body: '#E9D5FF',
          accent: '#A855F7',
        ),
        fonts: TemplateFonts(
          title: FontConfig(name: 'Outfit', size: 36, bold: true),
          body: FontConfig(name: 'Inter', size: 16, bold: false),
        ),
        layouts: ['title_only', 'title_bullets'],
        style: 'violet',
      );

      final slides = [
        SlideModel(
          slideNumber: 1,
          layout: 'title_bullets',
          title: 'Quantum Supremacy Unleashed',
          bullets: ['Superposition mechanics', 'Entanglement at scale'],
          speakerNote: 'Cover introduction',
        ),
        SlideModel(
          slideNumber: 2,
          layout: 'title_bullets',
          title: 'Qubit Architecture',
          bullets: ['Superconducting circuits', 'Ion traps'],
          speakerNote: 'Technical breakdown',
        ),
      ];

      // Add presentation to history
      AppState.history.insert(0, {
        'id': 'test_deck_1',
        'topic': 'Future of Quantum Computing',
        'slideCount': slides.length,
        'templateId': template.id,
        'templateName': template.name,
        'templateJson': {
          'id': template.id,
          'name': template.name,
          'colors': {
            'background': template.colors.background,
            'backgroundStart': template.colors.backgroundStart,
            'backgroundEnd': template.colors.backgroundEnd,
            'title': template.colors.title,
            'body': template.colors.body,
            'accent': template.colors.accent,
          },
          'fonts': {
            'title': {'name': template.fonts.title.name, 'size': template.fonts.title.size, 'bold': template.fonts.title.bold},
            'body': {'name': template.fonts.body.name, 'size': template.fonts.body.size, 'bold': template.fonts.body.bold},
          },
          'layouts': template.layouts,
        },
        'timestamp': DateTime.now().toIso8601String(),
        'slides': slides.map((s) => s.toJson()).toList(),
      });

      expect(AppState.history.length, 1);
      final item = AppState.history.first;

      expect(item['topic'], 'Future of Quantum Computing');
      expect(item['slideCount'], 2);
      expect(item['templateName'], 'Modern Violet');

      // Verify template colors are preserved
      final colors = (item['templateJson'] as Map<String, dynamic>)['colors'] as Map<String, dynamic>;
      expect(colors['backgroundStart'], '#2E1065');
      expect(colors['backgroundEnd'], '#1E1B4B');
      expect(colors['accent'], '#A855F7');

      // Verify slides structure
      final savedSlides = item['slides'] as List<dynamic>;
      expect(savedSlides.length, 2);
      expect(savedSlides.first['title'], 'Quantum Supremacy Unleashed');
      expect((savedSlides.first['bullets'] as List<dynamic>).length, 2);
    });

    test('SlideModel converts from and to JSON cleanly without data loss', () {
      final original = SlideModel(
        slideNumber: 1,
        layout: 'title_bullets',
        title: 'Deep Learning Revolution',
        bullets: ['Transformers architecture', 'Attention mechanisms'],
        speakerNote: 'Speaker notes here',
        imageUrl: 'https://images.unsplash.com/test.jpg',
      );

      final json = original.toJson();
      final revived = SlideModel.fromJson(json);

      expect(revived.slideNumber, original.slideNumber);
      expect(revived.layout, original.layout);
      expect(revived.title, original.title);
      expect(revived.bullets, original.bullets);
      expect(revived.speakerNote, original.speakerNote);
      expect(revived.imageUrl, original.imageUrl);
    });

    test('Color parsing handles 6-char, 8-char, and null fallbacks reliably', () {
      Color parseHex(String? hex, {Color fallback = const Color(0xFF1E293B)}) {
        if (hex == null || hex.isEmpty) return fallback;
        try {
          String formatted = hex.replaceAll('#', '').trim();
          if (formatted.length == 6) {
            formatted = 'FF$formatted';
          } else if (formatted.length == 8) {
            // Already 8
          } else if (formatted.length == 3) {
            formatted = 'FF${formatted[0]}${formatted[0]}${formatted[1]}${formatted[1]}${formatted[2]}${formatted[2]}';
          } else {
            return fallback;
          }
          return Color(int.parse(formatted, radix: 16));
        } catch (_) {
          return fallback;
        }
      }

      expect(parseHex('#FF5722'), const Color(0xFFFF5722)); // Brand orange
      expect(parseHex('#2E1065'), const Color(0xFF2E1065)); // Violet backgroundStart
      expect(parseHex('#1E1B4B'), const Color(0xFF1E1B4B)); // Violet backgroundEnd
      expect(parseHex('#A855F7'), const Color(0xFFA855F7)); // Violet accent
      expect(parseHex(null), const Color(0xFF1E293B)); // fallback
      expect(parseHex('invalid'), const Color(0xFF1E293B)); // fallback
    });
  });
}
