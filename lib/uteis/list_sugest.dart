import 'package:ytmusicservice/uteis/traverse.dart';
import 'package:ytmusicservice/uteis/types.dart';

class SongSugest {
  String type;
  String name;
  Artist artist;
  String videoId;
  List<ThumbnailFull> thumbnails;
  String playlistId;
  String duration;
  SongSugest(
    this.type,
    this.name,
    this.artist,
    this.videoId,
    this.thumbnails,
    this.playlistId,
    this.duration,
  );

  factory SongSugest.fromJson(Map<String, dynamic> data) {
    var nome = traverse(data, ['title', 'runs', 'text'])[0];
    var artista = traverse(data, ['longBylineText', 'runs', 'text'])[0];
    var videoId =
        traverse(data, ['navigationEndpoint', 'watchEndpoint', 'videoId'])[0];
    var playlistId = traverse(data, ['navigationEndpoint', 'playlistId'])[0];
    var items = traverseList(data, ['thumbnail']);
    var thumbnails =
        traverseList(items, [
          "thumbnails",
        ]).map((item) => ThumbnailFull.fromMap(item)).toList();
    var duration = traverse(data, ['lengthText', 'runs', 'text']);

    var json = {
      'title': nome,
      'artist': artista,
      'videoId': videoId,
      'thumbnails': thumbnails,
      'playlistId': playlistId,
      'duration': duration,
    };
    return SongSugest(
      'SONG',
      json['title'],
      Artist(json['artist']),
      json['videoId'],
      json['thumbnails'],

      json['playlistId'],
      json['duration'],
    );
  }
}

class Artist {
  String name;
  Artist(this.name);
}
