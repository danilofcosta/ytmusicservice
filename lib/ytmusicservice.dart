

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:ytmusicservice/youtube_explore.dart';
import 'package:ytmusicservice/uteis/album_parse.dart';
import 'package:ytmusicservice/uteis/artist_parse.dart';
import 'package:ytmusicservice/uteis/list_sugest.dart';
import 'package:ytmusicservice/uteis/playlist_parser.dart';
import 'package:ytmusicservice/uteis/search_parser.dart';
import 'package:ytmusicservice/uteis/suggestion.dart';
import 'package:ytmusicservice/uteis/traverse.dart';
import 'package:ytmusicservice/uteis/types.dart';
import 'package:ytmusicservice/uteis/song_parser.dart';

//import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YTMusicService {
  static final YTMusicService _instance = YTMusicService._internal();

  factory YTMusicService() {
    return _instance;
  }

  YTMusicService._internal() {
    cookieJar = CookieJar();
    youtubeExplodexInstance = youtubeExplodex;
    config = {};
    dio = Dio(
      BaseOptions(
        baseUrl: "https://music.youtube.com/",
        headers: {
          "User-Agent":
              "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.129 Safari/537.36",
          "Accept-Language": "en-US,en;q=0.5",
          "Accept-Enconding": "gzip",
          "Accept": "application/json, text/plain, */*",
          "Content-Type": 'application/json',
        },
        extra: {'withCredentials': true},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final cookies = await cookieJar.loadForRequest(
            Uri.parse(options.baseUrl),
          );
          final cookieString = cookies
              .map((cookie) => '${cookie.name}=${cookie.value}')
              .join('; ');
          if (cookieString.isNotEmpty) {
            options.headers['cookie'] = cookieString;
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final cookieStrings = response.headers['set-cookie'] ?? [];
          for (final cookieString in cookieStrings) {
            final cookie = Cookie.fromSetCookieValue(cookieString);
            cookieJar.saveFromResponse(
              Uri.parse(response.requestOptions.baseUrl),
              [cookie],
            );
          }
          return handler.next(response);
        },
      ),
    );
  }

  late CookieJar cookieJar;
  late Map<String, String> config;
  late final dynamic youtubeExplodexInstance;
  late Dio dio;
  bool hasInitialized = false;

  /// Initializes the YTMusicService instance with provided cookies, geolocation, and language.
  Future<YTMusicService> init({
    String? cookies,
    String? geo,
    String? lang,
  }) async {
    print('init class');
    if (hasInitialized) {
      return this;
    }
    if (cookies != null) {
      for (final cookieString in cookies.split("; ")) {
        final cookie = Cookie.fromSetCookieValue(cookieString);
        cookieJar.saveFromResponse(Uri.parse("https://www.youtube.com/"), [
          cookie,
        ]);
      }
    }

    await fetchConfig();

    if (geo != null) config['GL'] = geo;
    if (lang != null) config['HL'] = lang;

    hasInitialized = true;

    return this;
  }

  /// Busca os dados de configuração necessários para solicitações de API.
  Future<void> fetchConfig() async {
    if (config.isNotEmpty) return;
    try {
      final response = await dio.get('/');
      final html = response.data;
      config['VISITOR_DATA'] = _extractValue(html, r'"VISITOR_DATA":"(.*?)"');
      config['INNERTUBE_CONTEXT_CLIENT_NAME'] = _extractValue(
        html,
        r'"INNERTUBE_CONTEXT_CLIENT_NAME":\s*(-?\d+|\"(.*?)\")',
      );
      config['INNERTUBE_CLIENT_VERSION'] = _extractValue(
        html,
        r'"INNERTUBE_CLIENT_VERSION":"(.*?)"',
      );
      config['DEVICE'] = _extractValue(html, r'"DEVICE":"(.*?)"');
      config['PAGE_CL'] = _extractValue(
        html,
        r'"PAGE_CL":\s*(-?\d+|\"(.*?)\")',
      );
      config['PAGE_BUILD_LABEL'] = _extractValue(
        html,
        r'"PAGE_BUILD_LABEL":"(.*?)"',
      );
      config['INNERTUBE_API_KEY'] = _extractValue(
        html,
        r'"INNERTUBE_API_KEY":"(.*?)"',
      );
      config['INNERTUBE_API_VERSION'] = _extractValue(
        html,
        r'"INNERTUBE_API_VERSION":"(.*?)"',
      );
      config['INNERTUBE_CLIENT_NAME'] = _extractValue(
        html,
        r'"INNERTUBE_CLIENT_NAME":"(.*?)"',
      );
      config['GL'] = _extractValue(html, r'"GL":"(.*?)"');
      config['HL'] = _extractValue(html, r'"HL":"(.*?)"');
    } catch (e) {
      print('Error fetching data: ${e.toString()}');
    }
  }

  /// Extrai um valor do HTML usando uma expressão regular.
  String _extractValue(String html, String regex) {
    final match = RegExp(regex).firstMatch(html);
    return match != null ? match.group(1)! : '';
  }

  /// Constrói e executa uma solicitação de API para o ponto de extremidade especificado com parâmetros de corpo e consulta opcionais.
  Future<dynamic> constructRequest(
    String endpoint, {
    Map<String, dynamic> body = const {},
    Map<String, String> query = const {},
  }) async {
    final headers = <String, String>{
      ...dio.options.headers,
      "x-origin": "https://music.youtube.com/",
      "X-Goog-Visitor-Id": config['VISITOR_DATA'] ?? "",
      "X-YouTube-Client-Name": config['INNERTUBE_CONTEXT_CLIENT_NAME'] ?? '',
      "X-YouTube-Client-Version": config['INNERTUBE_CLIENT_VERSION'] ?? '',
      "X-YouTube-Device": config['DEVICE'] ?? '',
      "X-YouTube-Page-CL": config['PAGE_CL'] ?? '',
      "X-YouTube-Page-Label": config['PAGE_BUILD_LABEL'] ?? '',
      "X-YouTube-Utc-Offset":
          (-DateTime.now().timeZoneOffset.inMinutes).toString(),
      "X-YouTube-Time-Zone": DateTime.now().timeZoneName,
    };

    final searchParams = Uri.parse("?").replace(
      queryParameters: {
        ...query,
        "alt": "json",
        "key": config['INNERTUBE_API_KEY'],
      },
    );

    try {
      final response = await dio.post(
        "youtubei/${config['INNERTUBE_API_VERSION']}/$endpoint${searchParams.toString()}",
        data: {
          "context": {
            "capabilities": {},
            "client": {
              "clientName": config['INNERTUBE_CLIENT_NAME'],
              "clientVersion": config['INNERTUBE_CLIENT_VERSION'],
              "experimentIds": [],
              "experimentsToken": "",
              "gl": config['GL'],
              "hl": config['HL'],
              "locationInfo": {
                "locationPermissionAuthorizationStatus":
                    "LOCATION_PERMISSION_AUTHORIZATION_STATUS_UNSUPPORTED",
              },
              "musicAppInfo": {
                "musicActivityMasterSwitch":
                    "MUSIC_ACTIVITY_MASTER_SWITCH_INDETERMINATE",
                "musicLocationMasterSwitch":
                    "MUSIC_LOCATION_MASTER_SWITCH_INDETERMINATE",
                "pwaInstallabilityStatus": "PWA_INSTALLABILITY_STATUS_UNKNOWN",
              },
              "utcOffsetMinutes": -DateTime.now().timeZoneOffset.inMinutes,
            },
            "request": {
              "internalExperimentFlags": [
                {
                  "key": "force_music_enable_outertube_tastebuilder_browse",
                  "value": "true",
                },
                {
                  "key": "force_music_enable_outertube_playlist_detail_browse",
                  "value": "true",
                },
                {
                  "key": "force_music_enable_outertube_search_suggestions",
                  "value": "true",
                },
              ],
              "sessionIndex": {},
            },
            "user": {"enableSafetyMode": false},
          },
          ...body,
        },
        options: Options(headers: headers),
      );
      final jsonData = response.data;

      if (jsonData.containsKey("responseContext")) {
        return jsonData;
      } else {
        return jsonData;
      }
    } on DioException catch (e) {
      print(
        'Failed to make request to ${e.requestOptions.uri} - ${e.response?.statusCode} - [${e.response?.data}]',
      );
    }
  }

  Future<dynamic> obeterCookie({
    String url = "https://www.youtube.com/",
  }) async {
    final uri = Uri.parse(url);
    return await cookieJar.loadForRequest(uri);
  }

  //------------------------------------------------------------------------------------------------
  Future<List<SearchResult>> searchplaylist(String query) async {
    final searchData = await constructRequest(
      "search",
      body: {"query": query, "params": null},
    );

    return traverseList(searchData, ["musicResponsiveListItemRenderer"])
        .map(SearchParser.parse)
        .where((e) => e != null)
        .cast<SearchResult>()
        .toList();
  }

  Future<PlaylistFullSongas> getPlaylist(String playlistId) async {
    if (playlistId.startsWith("PL") || playlistId.startsWith("RD")) {
      playlistId = "VL$playlistId";
    }

    final playlistData = await constructRequest(
      "browse",
      body: {"browseId": playlistId},
    );

    final songs = traverseList(playlistData, [
      "musicPlaylistShelfRenderer",
      "musicResponsiveListItemRenderer",
    ]);
    dynamic continuation = traverse(playlistData, ["continuation"]);
    if (continuation is List) {
      continuation = continuation[0];
    }
    while (continuation is! List) {
      final songsData = await constructRequest(
        "browse",
        query: {"continuation": continuation},
      );
      songs.addAll(
        traverseList(songsData, ["musicResponsiveListItemRenderer"]),
      );
      continuation = traverse(songsData, ["continuation"]);
    }
    List<Future<VideoDetailed>> futures =
        songs.map((song) => parsePlaylistVideoAsync(song)).toList();
    List<VideoDetailed> songsList = await Future.wait(futures);
    return parsePlaylistFullSongas(playlistData, songsList);
  }

  Future<List<ArtistDetailed>> searchArtists(String query) async {
    final searchData = await constructRequest(
      "search",
      body: {
        "query": query,
        "params": "Eg-KAQwIABAAGAAgASgAMABqChAEEAMQCRAFEAo%3D",
      },
    );

    return traverseList(searchData, [
      "musicResponsiveListItemRenderer",
    ]).map(ArtistParser.parseSearchResult).toList();
  }

  Future<List<dynamic>> searchSongs(String query) async {
    final searchData = await constructRequest(
      "search",
      body: {
        "query": query,
        "params": "Eg-KAQwIARAAGAAgACgAMABqChAEEAMQCRAFEAo%3D",
      },
    );

    final results = traverseList(searchData, [
      "musicResponsiveListItemRenderer",
    ]);
    final mappedResults = results.map(SongParser.parseSearchResult).toList();

    return mappedResults;
  }

  Future<List<AlbumDetailed>> searchAlbums(String query) async {
    final searchData = await constructRequest(
      "search",
      body: {
        "query": query,
        "params": "Eg-KAQwIABAAGAEgACgAMABqChAEEAMQCRAFEAo%3D",
      },
    );

    return traverseList(searchData, [
      "musicResponsiveListItemRenderer",
    ]).map(AlbumParser.parseSearchResult).toList();
  }

  Future<List<SongSugest>> getSongNext({required String videoId}) async {
    if (!RegExp(r"^[a-zA-Z0-9-_]{11}$").hasMatch(videoId)) {
      throw Exception("Invalid videoId");
    }

    // Primeiro: pega a playlistId
    final data = await constructRequest("next", body: {"videoId": videoId});

    final playlistId =
        traverseString(data, [
          "contents",
          "singleColumnWatchNextResults",
          "playlist",
          "playlist",
          "playlistId",
        ]) ??
        traverseString(data, ["watchPlaylistEndpoint", "playlistId"]);

    if (playlistId == null || playlistId.isEmpty) {
      //throw Exception('não foi possivel obter playlistId: $videoId');
      print('não foi possivel obter playlistId: $videoId');
      return []; //throw Exception('não foi possivel obter playlistId: $videoId');
    }

    // Segundo: carrega a playlist

    final playlistData = await constructRequest(
      "next",
      body: {"videoId": videoId, "playlistId": playlistId},
    );
    final songs = traverseList(playlistData, ["playlistPanelVideoRenderer"]);

    List<SongSugest> listSongs =
        songs.map<SongSugest>((song) => SongSugest.fromJson(song)).toList();
    return listSongs;
  }

  Future<List<SongDetailed>> getArtistSongs(String artistId) async {
    final artistData = await constructRequest(
      "browse",
      body: {"browseId": artistId},
    );
    final browseToken = traverse(artistData, [
      "musicShelfRenderer",
      "title",
      "browseId",
    ]);

    if (browseToken is List) {
      return [];
    }

    final songsData = await constructRequest(
      "browse",
      body: {"browseId": browseToken},
    );
    final continueToken = traverse(songsData, ["continuation"]);
    late final Map moreSongsData;

    if (continueToken is String) {
      moreSongsData = await constructRequest(
        "browse",
        query: {"continuation": continueToken},
      );
    } else {
      moreSongsData = {};
    }

    return [
          ...traverseList(songsData, ["musicResponsiveListItemRenderer"]),
          ...traverseList(moreSongsData, ["musicResponsiveListItemRenderer"]),
        ]
        .map(
          (s) => SongParser.parseArtistSong(
            s,
            ArtistBasic(
              artistId: artistId,
              name:
                  traverseString(artistData, ["header", "title", "text"]) ?? '',
            ),
          ),
        )
        .toList();
  }

  Future<AlbumFull> getAlbum(String albumId) async {
    final data = await constructRequest("browse", body: {"browseId": albumId});

    final album = AlbumParser.parse(data, albumId);

    final artistSongs = await getArtistSongs(album.artist.artistId ?? '');
    final filteredSongs = artistSongs.where(
      (song) =>
          album.songs
              .where(
                (item) =>
                    '${song.album?.name}-${song.name}' ==
                    '${item.album?.name}-${item.name}',
              )
              .isNotEmpty,
    );

    final songsThatArentInArtist = album.songs.where(
      (item) =>
          artistSongs
              .where(
                (song) =>
                    '${song.album?.name}-${song.name}' ==
                    '${item.album?.name}-${item.name}',
              )
              .isEmpty,
    );

    return album..songs = [...filteredSongs, ...songsThatArentInArtist];
  }

  Future<SongFull> getSong(String videoId) async {
    if (!RegExp(r"^[a-zA-Z0-9-_]{11}$").hasMatch(videoId)) {
      throw Exception("Invalid videoId");
    }

    final data = await constructRequest("player", body: {"videoId": videoId});

    final manifest = await youtubeExplodexInstance.videos.streams.getManifest(
      videoId,
      requireWatchPage: false,
    );
    final audios = manifest.audioOnly;
    //final audios = null;

    final song = SongParser.parse(data, adaptiveFormats: audios);
    if (song.videoId != videoId) {
      throw Exception("Invalid videoId");
    }
    return song;
  }
Future<List<Suggestion>> getSearchSuggestions(String query) async {
  final response = await constructRequest(
    'music/get_search_suggestions',
    body: {
      "input": query,
      "params": "Eg-KAQwIARAAGAAgACgAMABqChAEEAMQCRAFEAo%3D",
    },
  );

  final suggestionsRaw = traverse(response, [
    'searchSuggestionsSectionRenderer',
    'contents',
  ]);
  List<Suggestion> suggestions = [];

  for (var item in suggestionsRaw) {
    // 1. Verifica se é música (tem videoId)
    final videoId = traverseString(item, [
      'musicResponsiveListItemRenderer',
      'navigationEndpoint',
      'watchEndpoint',
      'videoId',
    ]);

    if (videoId != null && videoId.isNotEmpty) {
      List<dynamic> itemData = traverseList(item, [
        'musicResponsiveListItemRenderer',
        'flexColumns',
      ]);

      String? title = traverseString(itemData[0], [
        'musicResponsiveListItemFlexColumnRenderer',
        'text',
        'runs',
        'text',
      ]);

      List<dynamic> artistRuns = traverseList(itemData[1], [
        'musicResponsiveListItemFlexColumnRenderer',
        'text',
        'runs',
      ]);

      String? artistName =
          artistRuns.length > 2 ? artistRuns[2]['text'] : null;

      String? artistId = traverseString(itemData[1], [
        'musicResponsiveListItemFlexColumnRenderer',
        'text',
        'runs',
        'navigationEndpoint',
        'browseEndpoint',
        'browseId',
      ]);

      List<dynamic> thumbs = traverseList(item, [
        'musicResponsiveListItemRenderer',
        'thumbnail',
        'musicThumbnailRenderer',
        'thumbnail',
        'thumbnails',
      ]);

      suggestions.add(Suggestion(
        type: SuggestionType.SONG,
        name: title ?? '',
        artist: Artist(name: artistName ?? '', id: artistId),
        videoId: videoId,
        thumbnails: thumbs.map((t) => ThumbnailFull.fromMap(t)).toList(),
        duration: '',
      ));
      continue;
    }

    // 2. Verifica se é playlist
    String? pageType = traverseString(item, [
      'musicResponsiveListItemRenderer',
      'navigationEndpoint',
      'browseEndpoint',
      'browseEndpointContextSupportedConfigs',
      'browseEndpointContextMusicConfig',
      'pageType',
    ]);

    if (pageType == 'MUSIC_PAGE_TYPE_PLAYLIST') {
      String? title = traverseString(item, [
        'musicResponsiveListItemRenderer',
        'flexColumns',
        'musicResponsiveListItemFlexColumnRenderer',
        'text',
        'runs',
        'text',
      ]);

      List<dynamic> thumbs = traverseList(item, [
        'musicResponsiveListItemRenderer',
        'thumbnail',
        'musicThumbnailRenderer',
        'thumbnail',
        'thumbnails',
      ]);

      String? playlistId = traverseString(item, [
        'musicResponsiveListItemRenderer',
        'overlay',
        'musicItemThumbnailOverlayRenderer',
        'content',
        'musicPlayButtonRenderer',
        'playNavigationEndpoint',
        'watchPlaylistEndpoint',
        'playlistId',
      ]);

      suggestions.add(Suggestion(
        type: SuggestionType.PLAYLIST,
        name: title ?? '',
        playlistId: playlistId,
        thumbnails: thumbs.map((t) => ThumbnailFull.fromMap(t)).toList(),
      ));
      continue;
    }

    // 3. Verifica se é artista (tem browseId mas não tem videoId)
    String? browseId = traverseString(item, [
      'musicResponsiveListItemRenderer',
      'navigationEndpoint',
      'browseEndpoint',
      'browseId',
    ]);

    if (browseId != null && browseId.isNotEmpty) {
      String? name = traverseString(item, [
        'musicResponsiveListItemRenderer',
        'flexColumns',
        'musicResponsiveListItemFlexColumnRenderer',
        'text',
        'runs',
        'text',
      ]);

      List<dynamic> thumbs = traverseList(item, [
        'musicResponsiveListItemRenderer',
        'thumbnail',
        'musicThumbnailRenderer',
        'thumbnail',
        'thumbnails',
      ]);

      suggestions.add(Suggestion(
        type: SuggestionType.ARTIST,
        name: name ?? '',
        artist: Artist(name: name ?? '', id: browseId),
        thumbnails: thumbs.map((t) => ThumbnailFull.fromMap(t)).toList(),
      ));
      continue;
    }

    // 4. Sugestão de texto (autocomplete)
    final textSuggestion = traverse(item, [
      'searchSuggestionRenderer',
      'searchEndpoint',
      'query',
    ]);
    if (textSuggestion != null && textSuggestion.isNotEmpty) {
      suggestions.add(Suggestion(
        type: SuggestionType.TEXT,
        name: textSuggestion.toString(),
      ));
      continue;
    }
  }

  if (suggestions.isEmpty) {
    return [Suggestion(type: SuggestionType.TEXT, name: 'Sem resultados')];
  }

  return suggestions;
}

  Future<List<AlbumDetailed>> getArtistAlbums(String artistId) async {
    final artistData = await constructRequest(
      "browse",
      body: {"browseId": artistId},
    );
    final artistAlbumsData =
        traverseList(artistData, ["musicCarouselShelfRenderer"])[0];
    final browseBody = traverse(artistAlbumsData, [
      "moreContentButton",
      "browseEndpoint",
    ]);
    if (browseBody is List) {
      return [];
    }
    final albumsData = await constructRequest(
      "browse",
      body: browseBody is List ? {} : browseBody,
    );

    return [
      ...traverseList(albumsData, ["musicTwoRowItemRenderer"])
          .map(
            (item) => AlbumParser.parseArtistAlbum(
              item,
              ArtistBasic(
                artistId: artistId,
                name:
                    traverseString(albumsData, ["header", "runs", "text"]) ??
                    '',
              ),
            ),
          )
          .where((album) => album.artist.artistId == artistId),
    ];
  }

  Future<ArtistFull> getArtist(String artistId) async {
    final artistFull = await constructRequest(
      "browse",
      body: {"browseId": artistId},
    );
    return ArtistParser.parse(artistFull, artistId);
  }
}

void main() async {
  final ytService = YTMusicService();
  await ytService.init(geo: 'BR', lang: 'pt');
   var p = await ytService.getPlaylist('PLgaFNC_I_ZknpTh8GFcNQoEAPj0JODW0N');
  //var pl = await ytService.getPlaylist('RDCLAK5uy_lZVsxtItENO13UuTujVif5yJTuDnjc1pA');
  //var w = await ytService.getSongNext(videoId: 'J-4lCvbBysA');
  //var w = await ytService.searchSongs('mc');
  print(p.artist.name);
}
