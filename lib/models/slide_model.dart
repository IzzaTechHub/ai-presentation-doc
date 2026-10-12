class SlideModel {
  int slideNumber;
  String layout;
  String title;
  List<String> bullets;
  String speakerNote;
  String imageSearchKeyword;
  String imageUrl;

  SlideModel({
    required this.slideNumber,
    required this.layout,
    required this.title,
    required this.bullets,
    required this.speakerNote,
    this.imageSearchKeyword = '',
    this.imageUrl = '',
  });

  factory SlideModel.fromJson(Map<String, dynamic> json) {
    return SlideModel(
      slideNumber: json['slideNumber'] as int? ?? 1,
      layout: json['layout'] as String? ?? 'title_bullets',
      title: json['title'] as String? ?? '',
      bullets: (json['bullets'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      speakerNote: json['speakerNote'] as String? ?? '',
      imageSearchKeyword: json['imageSearchKeyword'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slideNumber': slideNumber,
      'layout': layout,
      'title': title,
      'bullets': bullets,
      'speakerNote': speakerNote,
      'imageSearchKeyword': imageSearchKeyword,
      'imageUrl': imageUrl,
    };
  }

  // Helper method to create a deep copy of the slide (useful for state changes)
  SlideModel copy() {
    return SlideModel(
      slideNumber: slideNumber,
      layout: layout,
      title: title,
      bullets: List.from(bullets),
      speakerNote: speakerNote,
      imageSearchKeyword: imageSearchKeyword,
      imageUrl: imageUrl,
    );
  }
}
