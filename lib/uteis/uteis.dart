import 'package:ytmusicservice/uteis/traverse.dart';

List<Map<String, dynamic>> parseSuggestions(Map<String, dynamic> data) {
  final suggestions = <Map<String, dynamic>>[];

  try {
    final queueContents = traverse(data, [
      'contents',
      'singleColumnMusicWatchNextResultsRenderer',
      'tabbedRenderer',
      'watchNextTabbedResultsRenderer',
      'tabs',
    
      'tabRenderer',
      'content',
      'musicQueueRenderer',
      'content',
      'musicQueuePlaylistPanelRenderer',
      'contents',
    ]) as List<dynamic>;

    for (final item in queueContents) {
      final renderer = item['musicResponsiveListItemRenderer'];
      if (renderer == null) continue;

      final videoId = traverse(renderer, ['navigationEndpoint', 'watchEndpoint', 'videoId']);
      final title = traverse(renderer, ['flexColumns',  'musicResponsiveListItemFlexColumnRenderer', 'text', 'runs',  'text']);
      final author = traverse(renderer, ['flexColumns',  'musicResponsiveListItemFlexColumnRenderer', 'text', 'runs','text']);

      if (videoId != null && title != null) {
        suggestions.add({
          'videoId': videoId,
          'title': title,
          'author': author,
        });
      }
    }
  } catch (e) {
    print('Erro ao parsear sugestões: $e');
  }

  return suggestions;
}
