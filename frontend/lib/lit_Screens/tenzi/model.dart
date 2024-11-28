class Wimbo {
  final int songNumber;
  final String title;
  final String subtitle;
  final List<List<String>>
      stanzas; // List of stanzas, each stanza is a list of lines
  final List<String> chorus;

  Wimbo({
    required this.songNumber,
    required this.title,
    required this.subtitle,
    required this.stanzas,
    required this.chorus,
  });

  factory Wimbo.fromJson(Map<String, dynamic> json) {
    // Extract all stanzas dynamically
    final stanzas = <List<String>>[];
    for (var key in json.keys) {
      if (key.startsWith('stanza_')) {
        stanzas.add(List<String>.from(json[key] ?? []));
      }
    }

    return Wimbo(
      songNumber: json['song_number'],
      title: json['title'],
      subtitle: json['subtitle'] ?? '',
      stanzas: stanzas,
      chorus: List<String>.from(json['chorus'] ?? []),
    );
  }
}
