import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeRepository {
  final YoutubeExplode _youtube;
  final Dio _dio;

  YoutubeRepository(this._youtube, this._dio);

  Future<void> downloadMp3(String url, String name) async {
    final manifestId = _extractVideoIdByUrl(url);
    if (manifestId == null) throw Exception('Link Inválido');
    final manifest =
        await _youtube.videos.streamsClient.getManifest(manifestId);

    final streamInfo = manifest.audioOnly.withHighestBitrate();

    await _download(streamInfo.url.toString(), './$name.webm');
  }

  Future<void> _download(String url, String savePath) async {
    try {
      if (await File(savePath).exists()) {
        return;
      }
      await _dio.download(url, savePath);
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
