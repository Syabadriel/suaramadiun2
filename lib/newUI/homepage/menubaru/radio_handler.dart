import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

// --- INIT HELPER ---
Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.kominfo.suaramadiun.channel.audio',
      androidNotificationChannelName: 'Suara Madiun Radio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );
}

class RadioAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final String streamUrl = "https://play-93fm.madiunkota.go.id/live";
  Timer? _titleTimer;
  Uri? _artworkUri;

  RadioAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    await _setupArtwork();
    _player.playbackEventStream.listen(_transformEvent);
    _updateMediaItem("Live Broadcast");
    _startFetchTitleTimer();
  }

  /// Setup logo dari assets
  Future<void> _setupArtwork() async {
    try {
      final byteData = await rootBundle.load('assets/img/logolppl.png');
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/lppl_notification_icon.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      _artworkUri = Uri.file(file.path);
    } catch (e) {
      debugPrint("Error setting up artwork: $e");
      _artworkUri = Uri.parse("https://madiuntoday.id/assets/img/logolppl.png");
    }
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
        final icestats = data['icestats'];
        final source = icestats != null ? icestats['source'] : null;

        String title = "Live Broadcast";
        if (source is List && source.isNotEmpty) {
          if (source.length > 1) {
            title = source[1]?['title'] ?? 'Live Broadcast';
          } else {
            title = source[0]?['title'] ?? 'Live Broadcast';
          }
        } else if (source is Map) {
          title = source['title'] ?? 'Live Broadcast';
        }

        if (mediaItem.value?.title != title) {
          _updateMediaItem(title);
        }
      }
    } catch (e) {
      debugPrint("Error fetch title: $e");
    }
  }

  void _updateMediaItem(String currentTitle) {
    mediaItem.add(MediaItem(
      id: streamUrl,
      album: "93.0 FM",
      artist: "LPPL Suara Madiun",
      title: currentTitle,
      artUri: _artworkUri ?? Uri.parse("https://madiuntoday.id/assets/img/logo.png"),
      duration: null,
    ));
  }

  @override
  Future<void> play() async {
    // Reload URL jika player sedang stop/idle untuk memastikan stream live
    if (_player.processingState == ProcessingState.idle) {
      try {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(streamUrl)));
      } catch (e) {
        debugPrint("Error loading stream: $e");
      }
    }
    return _player.play();
  }

  @override
  Future<void> pause() async {
    // Untuk live streaming, pause = stop (agar tidak buffer di belakang & hemat kuota)
    await _player.stop();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop(); // Penting untuk mematikan service di background
  }

  // --- LOGIC UI NOTIFIKASI ---
  void _transformEvent(PlaybackEvent event) {
    playbackState.add(PlaybackState(
      controls: [
        // HANYA PLAY & PAUSE
        if (_player.playing) MediaControl.pause else MediaControl.play,
      ],
      systemActions: const {
        MediaAction.playPause,
        MediaAction.play,
        MediaAction.pause,
        // MediaAction.stop DIHAPUS agar tidak muncul di menu sistem
      },
      androidCompactActionIndices: const [0], // Tombol Play/Pause jadi yang utama
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
    ));
  }

  @override
  Future<void> onTaskRemoved() async {
    _titleTimer?.cancel();
    await _player.stop();
    await _player.dispose();
    await super.onTaskRemoved();
  }
}