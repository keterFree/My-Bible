class Scripture {
  final int book;
  final int chapter;
  final List<int> verseNumbers;

  Scripture({required this.book, required this.chapter, required this.verseNumbers});

  factory Scripture.fromJson(Map<String, dynamic> json) {
    return Scripture(
      book: json['book'],
      chapter: json['chapter'],
      verseNumbers: List<int>.from(json['verseNumbers']),
    );
  }
}

class Sermon {
  final String title;
  final String speaker;
  final String notes;
  final List<Scripture> scriptures;

  Sermon({required this.title, required this.speaker, required this.notes, required this.scriptures});

  factory Sermon.fromJson(Map<String, dynamic> json) {
    return Sermon(
      title: json['title'],
      speaker: json['speaker'],
      notes: json['notes'],
      scriptures: (json['scriptures'] as List)
          .map((scripture) => Scripture.fromJson(scripture))
          .toList(),
    );
  }
}

class Devotion {
  final String title;
  final String content;
  final List<Scripture> scriptures;

  Devotion({required this.title, required this.content, required this.scriptures});

  factory Devotion.fromJson(Map<String, dynamic> json) {
    return Devotion(
      title: json['title'],
      content: json['content'],
      scriptures: (json['scriptures'] as List)
          .map((scripture) => Scripture.fromJson(scripture))
          .toList(),
    );
  }
}

class Service {
  final String title;
  final String date;
  final String location;
  final String theme;
  final List<String> images;
  final List<Devotion> devotions;
  final List<Sermon> sermons;

  Service({
    required this.title,
    required this.date,
    required this.location,
    required this.theme,
    required this.images,
    required this.devotions,
    required this.sermons,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      title: json['title'],
      date: json['date'],
      location: json['location'],
      theme: json['theme'],
      images: List<String>.from(json['images']),
      devotions: (json['devotions'] as List)
          .map((devotion) => Devotion.fromJson(devotion))
          .toList(),
      sermons: (json['sermons'] as List)
          .map((sermon) => Sermon.fromJson(sermon))
          .toList(),
    );
  }
}
