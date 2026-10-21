import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class RadarFrame {
  final int time;
  final String path;

  const RadarFrame({required this.time, required this.path});

  factory RadarFrame.fromJson(Map<String, dynamic> json) {
    return RadarFrame(
      time: json['time'] as int,
      path: json['path'] as String,
    );
  }
}

class RadarDataResponse {
  final String host;
  final List<RadarFrame> past;
  final List<RadarFrame> nowcast;

  const RadarDataResponse({
    required this.host,
    required this.past,
    required this.nowcast,
  });

  List<RadarFrame> get allFrames => [...past, ...nowcast];

  RadarFrame? getFrameByIndex(int index) {
    if (allFrames.isEmpty) return null;
    final validIndex = index.clamp(0, allFrames.length - 1);
    return allFrames[validIndex];
  }

  String? getTileUrlForFrameIndex(int index, {int tileSize = 256, int colorScheme = 2, bool smooth = true}) {
    final frame = getFrameByIndex(index);
    if (frame == null) return null;

    final smoothVal = smooth ? 1 : 0;
    return '$host${frame.path}/$tileSize/{z}/{x}/{y}/$colorScheme/${smoothVal}_1.png';
  }

  RadarFrame? getFrameForOffset(int hourOffset) {
    if (allFrames.isEmpty) return null;

    if (hourOffset == 0) {
      return past.isNotEmpty ? past.last : allFrames.first;
    }

    // Map offset step to available frame array index for noticeable frame progression
    if (hourOffset > 0 && nowcast.isNotEmpty) {
      final idx = ((hourOffset / 24.0) * (nowcast.length - 1)).round().clamp(0, nowcast.length - 1);
      return nowcast[idx];
    }

    return past.last;
  }

  String? getTileUrlForOffset(int hourOffset, {int tileSize = 256, int colorScheme = 2, bool smooth = true}) {
    final frame = getFrameForOffset(hourOffset);
    if (frame == null) return null;

    final smoothVal = smooth ? 1 : 0;
    return '$host${frame.path}/$tileSize/{z}/{x}/{y}/$colorScheme/${smoothVal}_1.png';
  }
}

class WeatherRadarService {
  final http.Client _client;
  static const String _apiUrl = 'https://api.rainviewer.com/public/weather-maps.json';

  WeatherRadarService({http.Client? client}) : _client = client ?? http.Client();

  Future<RadarDataResponse> fetchRadarFrames() async {
    final response = await _client.get(Uri.parse(_apiUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load radar data: HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final host = json['host'] as String? ?? 'https://tilecache.rainviewer.com';

    final radarJson = json['radar'] as Map<String, dynamic>? ?? {};
    final pastList = (radarJson['past'] as List<dynamic>? ?? [])
        .map((e) => RadarFrame.fromJson(e as Map<String, dynamic>))
        .toList();
    final nowcastList = (radarJson['nowcast'] as List<dynamic>? ?? [])
        .map((e) => RadarFrame.fromJson(e as Map<String, dynamic>))
        .toList();

    return RadarDataResponse(
      host: host,
      past: pastList,
      nowcast: nowcastList,
    );
  }
}

final weatherRadarServiceProvider = Provider<WeatherRadarService>((ref) {
  return WeatherRadarService();
});

final radarFramesProvider = FutureProvider<RadarDataResponse>((ref) async {
  final service = ref.watch(weatherRadarServiceProvider);
  return service.fetchRadarFrames();
});
