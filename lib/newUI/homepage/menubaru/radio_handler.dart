import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class RadioAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final String streamUrl = "https://play-93fm.madiunkota.go.id/live";
  Timer? _titleTimer;

  RadioAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _updateMediaItem("Live Broadcast");
    _startFetchTitleTimer();
  }

  void _startFetchTitleTimer() {
    _fetchNowPlayingTitle();
    _titleTimer = Timer.periodic(const Duration(seconds: 40), (_) {
      _fetchNowPlayingTitle();
    });
  }

  Future<void> _fetchNowPlayingTitle() async {
    try {
      final response = await http.get(Uri.parse('https://play-93fm.madiunkota.go.id/status-json.xsl'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final source = data['icestats']['source'];
        String title = "Live Broadcast";

        if (source is List && source.length > 1) {
          title = source[1]?['title'] ?? 'Live Broadcast';
        } else if (source is Map) {
          title = source['title'] ?? 'Live Broadcast';
        }
        _updateMediaItem(title);
      }
    } catch (e) {
      debugPrint("Error fetch title in handler: $e");
    }
  }

  void _updateMediaItem(String currentTitle) {
    mediaItem.add(MediaItem(
      id: streamUrl,
      album: "93.0 FM",
      artist: "LPPL Suara Madiun",
      title: currentTitle,
      artUri: Uri.parse("https://madiuntoday.id/assets/img/logo.png"),
      duration: null, // Desain: Menghilangkan progress bar
    ));
  }

  @override
  Future<void> play() async {
    try {
      if (_player.processingState == ProcessingState.idle) {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(streamUrl)));
      }
      return _player.play();
    } catch (e) {
      debugPrint("Error loading stream: $e");
    }
  }

  // Desain: Gunakan stop untuk memberhentikan stream sepenuhnya (hemat data)
  @override
  Future<void> stop() => _player.stop();

  // Desain: Izinkan pause agar tombol pause muncul di notifikasi
  @override
  Future<void> pause() => _player.stop(); // Untuk radio, pause = stop

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        // Desain: Menampilkan tombol Play saat berhenti, dan tombol Pause saat jalan
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.playPause,
        MediaAction.pause,
        MediaAction.stop,
      },
      // Menempatkan tombol Play/Pause di posisi utama notifikasi
      androidCompactActionIndices: const [0],
      updatePosition: Duration.zero,
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
    );
  }
}