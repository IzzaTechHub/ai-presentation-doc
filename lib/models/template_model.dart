class TemplateModel {
  final String id;
  final String name;
  final TemplateColors colors;
  final TemplateFonts fonts;
  final List<String> layouts;
  final String style;

  TemplateModel({
    required this.id,
    required this.name,
    required this.colors,
    required this.fonts,
    required this.layouts,
    required this.style,
  });

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    return TemplateModel(
      id: json['id'] as String? ?? 'minimal',
      name: json['name'] as String? ?? 'Minimal',
      colors: TemplateColors.fromJson(json['colors'] as Map<String, dynamic>? ?? {}),
      fonts: TemplateFonts.fromJson(json['fonts'] as Map<String, dynamic>? ?? {}),
      layouts: (json['layouts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ["title_only", "title_bullets", "title_image_right", "two_column", "image_full"],
      style: json['style'] as String? ?? 'minimal',
    );
  }
}

class TemplateColors {
  final String background;
  final String? backgroundStart;
  final String? backgroundEnd;
  final String title;
  final String body;
  final String accent;

  TemplateColors({
    required this.background,
    this.backgroundStart,
    this.backgroundEnd,
    required this.title,
    required this.body,
    required this.accent,
  });

  factory TemplateColors.fromJson(Map<String, dynamic> json) {
    return TemplateColors(
      background: json['background'] as String? ?? '#FFFFFF',
      backgroundStart: json['backgroundStart'] as String?,
      backgroundEnd: json['backgroundEnd'] as String?,
      title: json['title'] as String? ?? '#000000',
      body: json['body'] as String? ?? '#333333',
      accent: json['accent'] as String? ?? '#5C6BC0',
    );
  }
}

class TemplateFonts {
  final FontConfig title;
  final FontConfig body;

  TemplateFonts({
    required this.title,
    required this.body,
  });

  factory TemplateFonts.fromJson(Map<String, dynamic> json) {
    return TemplateFonts(
      title: FontConfig.fromJson(json['title'] as Map<String, dynamic>? ?? {}, defaultSize: 36, defaultBold: true),
      body: FontConfig.fromJson(json['body'] as Map<String, dynamic>? ?? {}, defaultSize: 18, defaultBold: false),
    );
  }
}

class FontConfig {
  final String? name;
  final double size;
  final bool bold;

  FontConfig({
    this.name,
    required this.size,
    required this.bold,
  });

  factory FontConfig.fromJson(Map<String, dynamic> json, {required double defaultSize, required bool defaultBold}) {
    return FontConfig(
      name: json['name'] as String?,
      size: (json['size'] as num?)?.toDouble() ?? defaultSize,
      bold: json['bold'] as bool? ?? defaultBold,
    );
  }
}
