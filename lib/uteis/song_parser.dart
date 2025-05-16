
import 'package:ytmusicservice/uteis/parser.dart';
import 'package:ytmusicservice/uteis/traverse.dart';
import 'package:ytmusicservice/uteis/types.dart';
import 'package:ytmusicservice/uteis/filters.dart';
class SongParser {
    static SongFull parse(dynamic data, {dynamic adaptiveFormats}) {
    return SongFull(
      type: "SONG",
      videoId: traverseString(data, ["videoDetails", "videoId"]) ?? '',
      name: traverseString(data, ["videoDetails", "title"]) ?? '',
      artist: ArtistBasic(
        name: traverseString(data, ["author"]) ?? '',
        artistId: traverseString(data, ["videoDetails", "channelId"]),
      ),
      duration: int.parse(
          traverseString(data, ["videoDetails", "lengthSeconds"]) ?? '0'),
      thumbnails: traverseList(data, ["videoDetails", "thumbnails"])
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
      formats: traverseList(data, ["streamingData", "formats"]),
      adaptiveFormats:adaptiveFormats ?? traverseList(data, ["streamingData", "adaptiveFormats"]),
    );
  }

  static SongDetailed parseSearchResult(dynamic item) {

    final columns = traverseList(item, ["flexColumns", "runs"]);
    // It is not possible to identify the title and author
    final title = columns[0];
    final artist = columns.firstWhere(isArtist, orElse: () => columns[3]);
    final album = columns.firstWhere(isAlbum, orElse: () => null);
   // final duration = columns.firstWhere(
        // (item) => isDuration(item) && item != title,
        // orElse: () => null);
final durations = traverseList(item, [
  'flexColumns',
  'musicResponsiveListItemFlexColumnRenderer',
  'text',
  'runs',
  'text'
]);

// Filtra as strings no formato mm:ss (por exemplo, "3:22")
final duration = durations.firstWhere(
  (v) => RegExp(r'^\d+:\d+$').hasMatch(v),
  orElse: () => null,
);
    return SongDetailed(
      type: "SONG",
      videoId: traverseString(item, ["playlistItemData", "videoId"]) ?? '',
      name: traverseString(title, ["text"]) ?? '',
      artist: ArtistBasic(
        name: traverseString(artist, ["text"]) ?? '',
        artistId: traverseString(artist, ["browseId"]),
      ),
      album: album != null
          ? AlbumBasic(
              name: traverseString(album, ["text"]) ?? '',
              albumId: traverseString(album, ["browseId"]) ?? '',
            )
          : null,
      // duration: Parser.parseDuration(item),
      duration:  duration
,
      thumbnails: traverseList(item, ["thumbnails"])
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
    );
  }

  static SongDetailed parseArtistSong(dynamic item, ArtistBasic artistBasic) {
    final columns = traverseList(item, ["flexColumns", "runs"])
        .expand((e) => e is List ? e : [e])
        .toList();

    final title = columns.firstWhere(isTitle, orElse: () => null);
    final album = columns.firstWhere(isAlbum, orElse: () => null);
    final duration = columns.firstWhere(isDuration, orElse: () => null);
    final cleanedDuration =
        duration?['text']?.replaceAll(RegExp(r'[^0-9:]'), '');

    return SongDetailed(
      type: "SONG",
      videoId: traverseString(item, ["playlistItemData", "videoId"]) ?? '',
      name: traverseString(title, ["text"]) ?? '',
      artist: artistBasic,
      album: album != null
          ? AlbumBasic(
              name: traverseString(album, ["text"]) ?? '',
              albumId: traverseString(album, ["browseId"]) ?? '',
            )
          : null,
      duration: Parser.parseDuration(cleanedDuration),
      thumbnails: traverseList(item, ["thumbnails"])
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
    );
  }

  static SongDetailed parseArtistTopSong(
      dynamic item, ArtistBasic artistBasic) {
    final columns = traverseList(item, ["flexColumns", "runs"])
        .expand((e) => e is List ? e : [e])
        .toList();

    final title = columns.firstWhere(isTitle, orElse: () => null);
    final album = columns.firstWhere(isAlbum, orElse: () => null);
final durations = traverseList(item, [
  'flexColumns',
  'musicResponsiveListItemFlexColumnRenderer',
  'text',
  'runs',
  'text'
]);

// Filtra as strings no formato mm:ss (por exemplo, "3:22")
final duration = durations.firstWhere(
  (v) => RegExp(r'^\d+:\d+$').hasMatch(v),
  orElse: () => null,
);
    return SongDetailed(
      type: "SONG",
      videoId: traverseString(item, ["playlistItemData", "videoId"]) ?? '',
      name: traverseString(title, ["text"]) ?? '',
      artist: artistBasic,
      album: album != null
          ? AlbumBasic(
              name: traverseString(album, ["text"]) ?? '',
              albumId: traverseString(album, ["browseId"]) ?? '',
            )
          : null,
      duration: duration,
      thumbnails: traverseList(item, ["thumbnails"])
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
    );
  }

  static SongDetailed parseAlbumSong(
    dynamic item,
    ArtistBasic artistBasic,
    AlbumBasic albumBasic,
    List<ThumbnailFull> thumbnails,
  ) {
    final title = traverseList(item, ["flexColumns", "runs"])
        .firstWhere(isTitle, orElse: () => null);
    final duration = traverseList(item, ["fixedColumns", "runs"])
        .firstWhere(isDuration, orElse: () => null);

    return SongDetailed(
      type: "SONG",
      videoId: traverseString(item, ["playlistItemData", "videoId"]) ?? '',
      name: traverseString(title, ["text"]) ?? '',
      artist: artistBasic,
      album: albumBasic,
      duration: Parser.parseDuration(duration?['text']),
      thumbnails: thumbnails,
    );
  }

  static SongDetailed parseHomeSection(dynamic item) {
    return parseSearchResult(item);
  }
}


