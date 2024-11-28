class Hymn {
  final String number;
  final String title;
  final String titleWithHymnNumber;
  final String chorus; // Will default to an empty string if missing or false
  final List<String> verses;
  final String sound;
  final String category;

  Hymn({
    required this.number,
    required this.title,
    required this.titleWithHymnNumber,
    required this.chorus,
    required this.verses,
    required this.sound,
    required this.category,
  });

  factory Hymn.fromJson(
      Map<String, dynamic> json, Map<String, List<int>> categories) {
    // Determine the category dynamically if necessary
    String hymnCategory = json['category'] as String? ??
        categories.entries
            .firstWhere(
              (entry) => entry.value.contains(int.parse(json['number'])),
              orElse: () => const MapEntry('Uncategorized', []),
            )
            .key;
    // print(json['titleWithHymnNumber']);
    return Hymn(
      number: json['number'] as String,
      title: json['title'] as String,
      titleWithHymnNumber: json['titleWithHymnNumber'] as String,
      chorus: json['chorus'] is String
          ? json['chorus'] as String
          : "", // Handle absent or false chorus
      verses: List<String>.from(json['verses']), // Convert list of verses
      sound: json['sound'] as String? ?? "", // Default empty sound
      category: hymnCategory,
    );
  }
}
