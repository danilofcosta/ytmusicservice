
import 'package:ytmusicservice/uteis/filters.dart';
import 'package:ytmusicservice/uteis/parser.dart';
import 'package:ytmusicservice/uteis/traverse.dart';
import 'package:ytmusicservice/uteis/types.dart';
Future<VideoDetailed> parsePlaylistVideoAsync(dynamic item) async {
  // Corrigido: acessa corretamente os "runs" de flexColumns e fixedColumns
  final flexColumns = (item['flexColumns'] as List)
      .map((col) => col['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] ?? [])
      .expand((e) => e)
      .toList();

  final fixedColumns = (item['fixedColumns'] as List?)
      ?.map((col) => col['musicResponsiveListItemFixedColumnRenderer']?['text']?['runs'] ?? [])
      .expand((e) => e)
      .toList() ?? [];

  final title = flexColumns.firstWhere(isTitle,
      orElse: () => flexColumns.isNotEmpty ? flexColumns[0] : null);
  final artist = flexColumns.firstWhere(isArtist,
      orElse: () => flexColumns.length > 1 ? flexColumns[1] : null);
  final duration = fixedColumns.firstWhere(isDuration, orElse: () => null);

  // Extração de videoId
  final videoId1 = traverseString(
    item,
    ["overlay", "musicItemThumbnailOverlayRenderer", "content", "musicPlayButtonRenderer", "playNavigationEndpoint", "watchEndpoint", "videoId"],
  );

  // Alternativa via thumbnail
  final videoId2 = RegExp(r"https:\/\/i\.ytimg\.com\/vi\/(.+)\/")
      .firstMatch(
        (item['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?)?.firstOrNull?['url'] ?? '',
      )
      ?.group(1);

  // Validação de videoId
  if ((videoId1?.isEmpty ?? true) && videoId2 == null) {
    throw Exception('Video ID não encontrado');
  }

  return VideoDetailed(
    type: "VIDEO",
    videoId: videoId1 ?? videoId2!,
    name: traverseString(title, ["text"]) ?? '',
    artist: ArtistBasic(
      name: traverseString(artist, ["text"]) ?? '',
      artistId: traverseString(artist, ["browseEndpoint", "browseId"]),
    ),
    duration: Parser.parseDuration(duration?['text']),
    thumbnails: (item['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?)
            ?.map((thumb) => ThumbnailFull.fromMap(thumb))
            .toList() ??
        [],
  );
}


class PlaylistParser {
  static PlaylistFull parse(dynamic data, String playlistId) {
    final artist = traverse(data, ["tabs", "straplineTextOne"]);

    return PlaylistFull(
      type: "PLAYLIST",
      playlistId: playlistId,
      name: traverseString(data, ["tabs", "title", "text"]) ?? '',
      artist: ArtistBasic(
        name: traverseString(artist, ["text"]) ?? '',
        artistId: traverseString(artist, ["browseId"]),
      ),
      videoCount: int.tryParse(
              traverseList(data, ["tabs", "secondSubtitle", "text"])
                  .elementAt(2)
                  .split(" ")
                  .first
                  .replaceAll(",", "")) ??
          0,
      thumbnails: traverseList(data, ["tabs", "thumbnails"])
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
    );
  }

  static PlaylistDetailed parseSearchResult(dynamic item) {
    final columns = traverseList(item, ["flexColumns", "runs"])
        .expand((e) => e is List ? e : [e])
        .toList();

    // No specific way to identify the title
    final title = columns[0];
    final artist = columns.firstWhere(
      isArtist,
      orElse: () => columns.length > 2
          ? columns[3]
          : AlbumBasic(
              albumId: '',
              name: '',
            ),
    );

    return PlaylistDetailed(
      type: "PLAYLIST",
      playlistId: traverseString(item, ["overlay", "playlistId"]) ?? '',
      name: traverseString(title, ["text"]) ?? '',
      artist: ArtistBasic(
        name: traverseString(artist, ["text"]) ?? '',
        artistId: traverseString(artist, ["browseId"]),
      ),
      thumbnails: traverseList(item, ["thumbnails"])
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
    );
  }

  static PlaylistDetailed parseArtistFeaturedOn(
      dynamic item, ArtistBasic artistBasic) {
    return PlaylistDetailed(
      type: "PLAYLIST",
      playlistId:
          traverseString(item, ["navigationEndpoint", "browseId"]) ?? '',
      name: traverseString(item, ["runs", "text"]) ?? '',
      artist: artistBasic,
      thumbnails: traverseList(item, ["thumbnails"])
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
    );
  }

  static PlaylistDetailed parseHomeSection(dynamic item) {
    final artist = traverse(item, ["subtitle", "runs"]);

    return PlaylistDetailed(
      type: "PLAYLIST",
      playlistId:
          traverseString(item, ["navigationEndpoint", "playlistId"]) ?? '',
      name: traverseString(item, ["runs", "text"]) ?? '',
      artist: ArtistBasic(
        name: traverseString(artist, ["text"]) ?? '',
        artistId: traverseString(artist, ["browseId"]),
      ),
      thumbnails: traverseList(item, ["thumbnails"])
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
    );
  }
}

class PlaylistFullSongas{
  final String type;
  final String playlistId;
  final String name;
  final ArtistBasic artist;
  final List<ThumbnailFull> thumbnails;
  final List songs;

  PlaylistFullSongas({
    required this.type,
    required this.playlistId,
    required this.name,
    required this.artist,
    required this.thumbnails,
    required this.songs,
  });

}

 PlaylistFullSongas parsePlaylistFullSongas(dynamic item, List<VideoDetailed> songs) {

  final artist = traverse(item, ["subtitle", "runs"]);

 // print(item);
  return PlaylistFullSongas(

    type: "PLAYLIST",
    playlistId:
        traverseString(item, ["navigationEndpoint", "playlistId"]) ?? '',
    name: traverse(item, ['content','title' ,'runs','text'])[0].toString() ,
    artist: ArtistBasic(
      name:traverse(item, ['content','facepile' ,'text','content'])?? '',
      artistId: traverseString(artist, ["browseId"]),
    ),
    thumbnails: traverseList(item, ["thumbnails"])
        .map((item) => ThumbnailFull.fromMap(item))
        .toList(),
    songs: songs
  );
}

