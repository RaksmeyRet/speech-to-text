import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../constants/app_constants.dart';
import '../models/knowledge_search_result.dart';

class KnowledgeDetailSheet extends StatelessWidget {
  final KnowledgeSearchResult result;
  final String languageCode;

  const KnowledgeDetailSheet({
    super.key,
    required this.result,
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
    final isVideo = result.sourceType == 'video';
    final title = result.title.trim();
    final transcript = result.transcript.trim();
    final hasPageRange = result.pageStart != null || result.pageEnd != null;
    final pageLabel = result.pageStart == null
        ? (_isKhmer ? 'ទំព័រ ${result.pageEnd}' : 'Page ${result.pageEnd}')
        : result.pageEnd == null || result.pageEnd == result.pageStart
        ? (_isKhmer ? 'ទំព័រ ${result.pageStart}' : 'Page ${result.pageStart}')
        : (_isKhmer
              ? 'ទំព័រ ${result.pageStart}–${result.pageEnd}'
              : 'Pages ${result.pageStart}–${result.pageEnd}');
    final segmentText = [if (transcript.isNotEmpty) transcript];

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: isVideo
              ? _videoView(context)
              : _textView(
                  context,
                  title,
                  segmentText,
                  hasPageRange ? pageLabel : null,
                ),
        ),
      ),
    );
  }

  Widget _videoView(BuildContext context) {
    final url = result.fileUrl;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: _isKhmer ? 'បិទ' : 'Close',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
          ),
        ),
        Expanded(
          child: Center(
            child: url == null
                ? Text(
                    _isKhmer
                        ? 'វីដេអូនេះមិនមានតំណភ្ជាប់ទេ។'
                        : 'This video does not have a file URL.',
                    textAlign: TextAlign.center,
                  )
                : _VideoPlayer(
                    url: url,
                    startSeconds: result.startTimeSeconds,
                    endSeconds: result.endTimeSeconds,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _textView(
    BuildContext context,
    String title,
    List<String> segmentText,
    String? pageLabel,
  ) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: _isKhmer ? 'បិទ' : 'Close',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              if (title.isNotEmpty)
                Text(
                  title,
                  style: _detailTextStyle(
                    Theme.of(context).textTheme.titleLarge,
                    bold: true,
                  ),
                ),
              if (pageLabel != null) ...[
                if (title.isNotEmpty) const SizedBox(height: 8),
                Text(
                  pageLabel,
                  style: _detailTextStyle(
                    Theme.of(context).textTheme.bodySmall,
                    bold: false,
                  ),
                ),
              ],
              if (segmentText.isNotEmpty) ...[
                if (title.isNotEmpty || pageLabel != null)
                  const SizedBox(height: 12),
                for (var index = 0; index < segmentText.length; index++) ...[
                  if (index > 0) const SizedBox(height: 12),
                  Text(
                    segmentText[index],
                    style: _detailTextStyle(null, bold: false),
                  ),
                ],
              ],
              if (segmentText.isEmpty)
                Text(
                  pageLabel != null
                      ? _isKhmer
                            ? 'មិនមានអត្ថបទសម្រាប់ទំព័រនេះទេ។'
                            : 'No text is available for this page.'
                      : _isKhmer
                      ? 'មិនមានអត្ថបទសម្រាប់ផ្នែកនេះទេ។'
                      : 'No text is available for this segment.',
                  style: _detailTextStyle(null, bold: false),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

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
      if (_effectiveStart > Duration.zero) {
        await _controller.seekTo(_effectiveStart);
      }
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
