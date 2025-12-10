// Stub implementation for platforms that don't support flutter_sound (e.g., Windows)
import 'dart:async';

/// Stub implementation of FlutterSoundRecorder for unsupported platforms
class FlutterSoundRecorder {
  Future<void> openRecorder() async {
    throw UnsupportedError('语音录制功能在此平台上不可用');
  }

  Future<void> closeRecorder() async {}

  Future<void> startRecorder({
    String? toFile,
    Codec? codec,
    int? bitRate,
    int? sampleRate,
  }) async {
    throw UnsupportedError('语音录制功能在此平台上不可用');
  }

  Future<String?> stopRecorder() async {
    throw UnsupportedError('语音录制功能在此平台上不可用');
  }

  bool get isRecording => false;
}

/// Stub implementation of Codec enum
class Codec {
  static const aacMP4 = Codec._('aacMP4');
  static const opusOGG = Codec._('opusOGG');
  
  final String _name;
  const Codec._(this._name);
  
  @override
  String toString() => _name;
}
