import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeRepository {
  final YoutubeExplode _youtube;
  final Dio _dio;
  final Sink<String> _pageSink;

  YoutubeRepository(this._youtube, this._dio, this._pageSink);

  Future<void> downloadMp3(String url, String name) async {
    _pageSink.add('Coletando dados da música');
    final manifestId = _extractVideoIdByUrl(url);
    if (manifestId == null) throw Exception('Link Inválido');
    final manifest =
        await _youtube.videos.streamsClient.getManifest(manifestId);
    final streamInfo = manifest.audioOnly.withHighestBitrate();

    await _download(streamInfo.url.toString(), './$name.webm');
  }

  Future<void> _download(String url, String savePath) async {
    try {
      await _dio.download(url, savePath, onReceiveProgress: (value, max) {
        _pageSink.add(
            'Download da música: ${(value / max * 100).toStringAsFixed(2)}%');
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  String? _extractVideoIdByUrl(String url) {
    RegExp regExp = RegExp(
      r"v=...........",
      caseSensitive: false,
      multiLine: false,
    );

    final match = regExp.firstMatch(url);

    return match?.group(0)?.substring(2);
  }
}
