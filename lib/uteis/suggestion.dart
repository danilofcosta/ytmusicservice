import 'package:ytmusicservice/uteis/list_sugest.dart';
import 'package:ytmusicservice/uteis/types.dart';

enum SuggestionType {
  SONG,
  PLAYLIST,
  ARTIST,
  TEXT,
}

class Suggestion {
  final SuggestionType type;
  final String name;
  final Artist? artist;
  final String? playlistId;
  final List<ThumbnailFull>? thumbnails;
  final String? videoId;
  final String? album;
  final String? duration;

  Suggestion({
    required this.type,
    required this.name,
    this.artist,
    this.thumbnails,
    this.playlistId,
    this.videoId,
    this.album,
    this.duration,
  });

  factory Suggestion.empty() {
    return Suggestion(type: SuggestionType.TEXT, name: 'Sem resultados');
  }

  @override
  String toString() {
    return 'Suggestion(type: $type, title: $name, artist: $artist, videoId: $videoId)';
  }
}
