
import 'package:ytmusicservice/uteis/album_parse.dart';
import 'package:ytmusicservice/uteis/artist_parse.dart';
import 'package:ytmusicservice/uteis/playlist_parser.dart';
import 'package:ytmusicservice/uteis/song_parser.dart';
import 'package:ytmusicservice/uteis/traverse.dart';
import 'package:ytmusicservice/uteis/types.dart';
import 'package:ytmusicservice/uteis/video_parse.dart';

class SearchParser {
  static SearchResult? parse(dynamic item) {
    final flexColumns = traverseList(item, ["flexColumns"]);
    final type =
        traverseList(flexColumns[1], ["runs", "text"]).firstOrNull as String?;

    final parsers = {
      "Song": SongParser.parseSearchResult,
      "Video": VideoParser.parseSearchResult,
      "Artist": ArtistParser.parseSearchResult,
      "EP": AlbumParser.parseSearchResult,
      "Single": AlbumParser.parseSearchResult,
      "Album": AlbumParser.parseSearchResult,
      "Playlist": PlaylistParser.parseSearchResult,
    };

    if (parsers.containsKey(type)) {
      final parsedResult = parsers[type]!(item);
      return parsedResult as SearchResult;
    } else {
      return null;
    }
  }
}
