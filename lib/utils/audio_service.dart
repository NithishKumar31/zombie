import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  final AudioPlayer _bgmPlayer = AudioPlayer();

  AudioService._internal() {
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> playBackgroundMusic() async {
    await _bgmPlayer.play(AssetSource('audio/background.mp3'));
  }

  Future<void> stopBackgroundMusic() async {
    await _bgmPlayer.stop();
  }

  Future<void> playSoundEffect(String fileName) async {
    final player = AudioPlayer();
    await player.play(AssetSource('audio/$fileName'));
  }
}
