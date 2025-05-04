// suggestion.dart

class Suggestion {
  final String type;
  final String title;
  final String? artist;
  final String? thumb;
  final String? videoId;
  final String? artistId;

  Suggestion({
    required this.type,
    required this.title,
    this.artist,
    this.thumb,
    this.videoId,
    this.artistId,
  });

  factory Suggestion.empty() {
    return Suggestion(type: 'TEXT', title: 'Sem resultados');
  }

  @override
  String toString() {
    return 'Suggestion(type: $type, title: $title, artist: $artist, videoId: $videoId)';
  }
}
