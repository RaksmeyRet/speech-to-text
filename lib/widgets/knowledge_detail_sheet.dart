import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../constants/app_constants.dart';
import '../models/knowledge_document.dart';
import '../models/knowledge_search_result.dart';

class KnowledgeDetailSheet extends StatelessWidget {
  final KnowledgeSearchResult result;
  final Future<KnowledgeDocument> document;
  final String languageCode;

  const KnowledgeDetailSheet({
    super.key,
    required this.result,
    required this.document,
    this.languageCode = 'en',
  });

  bool get _isKhmer => languageCode == 'km';

  TextStyle _detailTextStyle(TextStyle? base, {required bool bold}) {
    final style = base ?? const TextStyle();
    if (!_isKhmer) {
      return style.copyWith(
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
      );
    }
    return style.copyWith(
      fontFamily: AppTextStyles.khmerFontFamily,
      fontWeight: bold ? FontWeight.w600 : AppTextStyles.khmerAnswerFontWeight,
      fontVariations: bold
          ? AppTextStyles.khmerBoldFontVariations
          : AppTextStyles.khmerRegularFontVariations,
    );
  }

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
                  message: _isKhmer
                      ? 'មិនអាចផ្ទុកព័ត៌មានលម្អិតបានទេ។ សូមព្យាយាមម្តងទៀត។'
                      : 'Could not load document details: ${snapshot.error}',
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
                    style: _detailTextStyle(
                      Theme.of(context).textTheme.headlineSmall,
                      bold: true,
                    ),
                  ),
                  if (knowledge.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      knowledge.description,
                      style: _detailTextStyle(null, bold: false),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: _detailTextStyle(
                      Theme.of(context).textTheme.titleLarge,
                      bold: true,
                    ),
                  ),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(summary, style: _detailTextStyle(null, bold: false)),
                  ],
                  if (transcript.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      transcript,
                      style: _detailTextStyle(null, bold: false),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (knowledge.sourceType == 'video' && url != null)
                    _InlineVideo(
                      startSeconds:
                          segment?.startTimeSeconds ?? result.startTimeSeconds,
                      endSeconds:
                          segment?.endTimeSeconds ?? result.endTimeSeconds,
                      languageCode: languageCode,
                      child: _VideoPlayer(
                        url: url,
                        startSeconds:
                            segment?.startTimeSeconds ??
                            result.startTimeSeconds,
                        endSeconds:
                            segment?.endTimeSeconds ?? result.endTimeSeconds,
                      ),
                    )
                  else if (url != null)
                    FilledButton.icon(
                      onPressed: () => _openFile(url, pageStart),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        _isKhmer
                            ? pageStart == null
                                  ? 'បើកឯកសារ'
                                  : 'បើកឯកសារនៅទំព័រ $pageStart'
                            : pageStart == null
                            ? 'Open document'
                            : 'Open document at page $pageStart',
                        style: TextStyle(
                          fontFamily: _isKhmer
                              ? AppTextStyles.khmerFontFamily
                              : null,
                          fontVariations: _isKhmer
                              ? AppTextStyles.khmerBoldFontVariations
                              : null,
                          fontWeight: _isKhmer ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                  if (url == null)
                    Text(
                      _isKhmer
                          ? 'ឯកសារនេះមិនមានតំណភ្ជាប់ទេ។'
                          : 'This document does not have a file URL.',
                      style: _detailTextStyle(null, bold: false),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    _isKhmer
                        ? 'កម្រិតភាពត្រូវគ្នា៖ ${(result.score * 100).toStringAsFixed(1)}%'
                        : 'Match score: ${(result.score * 100).toStringAsFixed(1)}%',
                    style: _detailTextStyle(
                      Theme.of(context).textTheme.bodySmall,
                      bold: false,
                    ),
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

class _InlineVideo extends StatelessWidget {
  final double? startSeconds;
  final double? endSeconds;
  final String languageCode;
  final Widget child;

  const _InlineVideo({
    required this.startSeconds,
    required this.endSeconds,
    required this.languageCode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isKhmer = languageCode == 'km';
    final start = _formatSeconds(startSeconds);
    final end = _formatSeconds(endSeconds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isKhmer
              ? 'ចាប់ផ្តើម៖ $start វិនាទី · បញ្ចប់៖ $end វិនាទី'
              : 'Start: $start sec · End: $end sec',
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

String _formatSeconds(double? seconds) =>
    seconds == null ? '—' : seconds.toStringAsFixed(1);

class _VideoPlayer extends StatefulWidget {
  final String url;
  final double? startSeconds;
  final double? endSeconds;

  const _VideoPlayer({
    required this.url,
    required this.startSeconds,
    required this.endSeconds,
  });

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  late final VideoPlayerController _controller;
  Object? _error;
  bool _stoppingAtSegmentEnd = false;

  Duration get _start =>
      Duration(milliseconds: ((widget.startSeconds ?? 0) * 1000).round());

  Duration? get _configuredEnd => widget.endSeconds == null
      ? null
      : Duration(milliseconds: (widget.endSeconds! * 1000).round());

  Duration get _effectiveStart {
    final end = _effectiveEnd;
    return end != null && _start > end ? end : _start;
  }

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
      await _controller.seekTo(_effectiveStart);
      if (!mounted) return;
      setState(() {});
      await _controller.play();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _onTick() {
    final end = _effectiveEnd;
    final value = _controller.value;
    if (end == null ||
        !value.isInitialized ||
        !value.isPlaying ||
        value.position < end ||
        _stoppingAtSegmentEnd) {
      return;
    }
    _stoppingAtSegmentEnd = true;
    _returnToSegmentStart();
  }

  Future<void> _returnToSegmentStart() async {
    try {
      await _controller.pause();
      await _controller.seekTo(_effectiveStart);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      _stoppingAtSegmentEnd = false;
    }
  }

  Duration? get _effectiveEnd {
    final duration = _controller.value.duration;
    final configuredEnd = _configuredEnd;
    if (configuredEnd == null || configuredEnd > duration) return duration;
    return configuredEnd;
  }

  Future<void> _startPlayback() async {
    try {
      if (_effectiveEnd != null &&
          _controller.value.position >= _effectiveEnd!) {
        await _controller.seekTo(_effectiveStart);
      }
      await _controller.play();
    } catch (error) {
      if (mounted) setState(() => _error = error);
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
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            final end = _effectiveEnd ?? value.duration;
            final start = _effectiveStart;
            final range = (end - start).inMilliseconds;
            final position = value.position.inMilliseconds
                .clamp(start.inMilliseconds, end.inMilliseconds)
                .toDouble();
            return Slider(
              min: start.inMilliseconds.toDouble(),
              max: range > 0
                  ? end.inMilliseconds.toDouble()
                  : start.inMilliseconds.toDouble() + 1,
              value: range > 0 ? position : start.inMilliseconds.toDouble(),
              onChanged: range <= 0
                  ? null
                  : (milliseconds) => _controller.seekTo(
                      Duration(milliseconds: milliseconds.round()),
                    ),
            );
          },
        ),
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: _controller,
          builder: (context, value, _) => IconButton(
            tooltip: value.isPlaying ? 'Pause video' : 'Play video',
            onPressed: value.isPlaying ? _controller.pause : _startPlayback,
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
