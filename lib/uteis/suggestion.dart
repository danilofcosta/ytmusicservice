// suggestion.dart

import 'package:ytmusicservice/uteis/types.dart';

class Suggestion {
  final String type;
  final String name;
  final String? artist;
  final List<Thumb>? thumbnails;
  final String? videoId;
  final String? artistId;

  Suggestion({
    required this.type,
    required this.name,
    this.artist,
    this.thumbnails,
    this.videoId,
    this.artistId,
  });

  factory Suggestion.empty() {
    return Suggestion(type: 'TEXT', name: 'Sem resultados');
  }

  @override
  String toString() {
    return 'Suggestion(type: $type, title: $name, artist: $artist, videoId: $videoId)';
  }
}
