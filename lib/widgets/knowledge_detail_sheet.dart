import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../models/knowledge_document.dart';
import '../models/knowledge_search_result.dart';

class KnowledgeDetailSheet extends StatelessWidget {
  final KnowledgeSearchResult result;
  final Future<KnowledgeDocument> document;

  const KnowledgeDetailSheet({
    super.key,
    required this.result,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: FutureBuilder<KnowledgeDocument>(
            future: document,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _MessageView(
                  message: 'Could not load document details: ${snapshot.error}',
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final knowledge = snapshot.data!;
              final source = knowledge.sources.isEmpty
                  ? null
                  : knowledge.sources.firstWhere(
                      (item) => item.fileUrl == result.fileUrl,
                      orElse: () => knowledge.sources.first,
                    );

              // match the segment by its id (the search result has no reliable index)
              final matchingSegments = knowledge.segments.where(
                (item) => item.id == result.segmentId,
              );
              final segment = matchingSegments.isEmpty
                  ? null
                  : matchingSegments.first;
              final url = source?.fileUrl ?? result.fileUrl;

              final title = segment?.title.isNotEmpty == true
                  ? segment!.title
                  : result.title;
              final summary = segment?.summary.isNotEmpty == true
                  ? segment!.summary
                  : result.summary;
              final transcript = segment?.transcript.isNotEmpty == true
                  ? segment!.transcript
                  : result.transcript;
              final pageStart = segment?.pageStart ?? result.pageStart;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    knowledge.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (knowledge.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(knowledge.description),
                  ],
                  const SizedBox(height: 18),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(summary),
                  ],
                  if (transcript.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(transcript),
                  ],
                  const SizedBox(height: 18),
                  if (knowledge.sourceType == 'video' && url != null)
                    _VideoPreview(
                      url: url,
                      startSeconds:
                          segment?.startTimeSeconds ?? result.startTimeSeconds,
                      endSeconds:
                          segment?.endTimeSeconds ?? result.endTimeSeconds,
                    )
                  else if (url != null)
                    FilledButton.icon(
                      onPressed: () => _openFile(url, pageStart),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        pageStart == null
                            ? 'Open document'
                            : 'Open document at page $pageStart',
                      ),
                    ),
                  if (url == null)
                    const Text('This document does not have a file URL.'),
                  const SizedBox(height: 12),
                  Text(
                    'Match score: ${(result.score * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openFile(String url, int? pageStart) async {
    final fileUri = Uri.parse(url);
    final uri = pageStart == null
        ? fileUri
        : fileUri.replace(fragment: 'page=$pageStart');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        Get.snackbar('Unable to open file', 'Check the file URL.');
      }
    } catch (error) {
      Get.snackbar('Unable to open file', error.toString());
    }
  }
}

class _VideoPreview extends StatefulWidget {
  final String url;
  final double? startSeconds;
  final double? endSeconds;

  const _VideoPreview({
    required this.url,
    required this.startSeconds,
    required this.endSeconds,
  });

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late final VideoPlayerController _controller;
  Object? _error;

  Duration get _start =>
      Duration(milliseconds: ((widget.startSeconds ?? 0) * 1000).round());

  Duration? get _end => widget.endSeconds == null
      ? null
      : Duration(milliseconds: (widget.endSeconds! * 1000).round());

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.addListener(_onTick);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      if (_start > Duration.zero) await _controller.seekTo(_start);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  // pause at the end of the segment, ready to replay
  void _onTick() {
    final end = _end;
    final value = _controller.value;
    if (end != null &&
        value.isInitialized &&
        value.isPlaying &&
        value.position >= end) {
      _controller.pause();
      _controller.seekTo(_start);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Text('Could not play this video: $_error');
    }
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        VideoProgressIndicator(_controller, allowScrubbing: true),
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: _controller,
          builder: (context, value, _) => IconButton(
            onPressed: () =>
                value.isPlaying ? _controller.pause() : _controller.play(),
            icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
          ),
        ),
      ],
    );
  }
}

class _MessageView extends StatelessWidget {
  final String message;

  const _MessageView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
  );
}