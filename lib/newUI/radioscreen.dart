// ignore_for_file: unnecessary_const, prefer_const_literals_to_create_immutables
import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart'; // Tambahkan ini
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/widget_radio.dart';
import 'package:lppl_93fm_suara_madiun/main.dart'; // Mengambil audioHandler global
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/native_service.dart';
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/radio_handler.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  // HAPUS: final AudioPlayer _player = AudioPlayer();
  // Kita gunakan audioHandler dari main.dart agar sinkron dengan notifikasi

  bool _isPlaying = false;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    _initAudioSession();

    // Mendengarkan perubahan status dari audioHandler global
    // Ini memastikan UI tombol berubah meskipun ditekan dari Notifikasi/Lockscreen
    audioHandler.playbackState.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isBuffering = state.processingState == AudioProcessingState.buffering ||
              state.processingState == AudioProcessingState.loading;
        });
      }
    });

    // Jalankan play otomatis saat startup
    _playAudio();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  // Preload ditiadakan karena sudah dihandle di dalam audioHandler.play()

  Future<void> _playAudio() async {
    setState(() {
      _isBuffering = true;
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tidak ada koneksi internet."),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Memanggil fungsi play dari audioHandler (Global)
      await audioHandler.play();

    } catch (e) {
      print("Gagal memutar audio: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memutar audio: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBuffering = false;
        });
      }
    }
  }

  Future<void> _stopAudio() async {
    try {
      // Memanggil fungsi stop dari audioHandler (Global)
      await audioHandler.stop();
    } catch (e) {
      print("Gagal menghentikan audio: $e");
    }
  }

  @override
  void dispose() {
    // Jangan dispose audioHandler di sini karena bersifat global untuk seluruh aplikasi
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bagian UI tetap sama persis sesuai permintaan Anda
    return Stack(
      alignment: Alignment.center,
      children: [
        LiveBroadcastButton(
          isPlaying: _isPlaying,
          onPlay: _playAudio,
          onStop: _stopAudio,
        ),
        if (_isBuffering)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 255, 160, 0).withOpacity(0.3),
                      const Color(0xFF1E88E5).withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "LPPL Radio",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            "Suara Madiun",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Sedang memuat siaran...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
      ],
    );
  }
}