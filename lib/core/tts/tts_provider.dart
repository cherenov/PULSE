import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/core/tts/tts_service.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  service.init();
  ref.onDispose(service.stop);
  return service;
});
