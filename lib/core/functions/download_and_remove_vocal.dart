import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:process_run/shell.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../repositories/youtube_repository.dart';

Future<void> downloadMusicAndVocalRemover(List<dynamic> args) async {
  SendPort sendPort = args[0];
  String url = args[1];
  String name = args[2];
  final repository = YoutubeRepository(YoutubeExplode(), Dio());
  try {
    await repository.downloadMp3(url, name);
    debugPrint('Separando $name');
    await Shell().run('''
                  ffmpeg -y -i "./$name.webm" "./$name.mp3"
                  python ./vocal-remover/inference.py --input "./$name.mp3" --gpu 0 --tta --postprocess

                  ffmpeg -y -i "./${name}_Instruments.wav" "./results/$name.mp3"
              ''');
    await File("./$name.webm").delete(recursive: true);
    await File("./$name.mp3").delete(recursive: true);
    await File("./${name}_Vocals.wav").delete(recursive: true);
    await File("./${name}_Instruments.wav").delete(recursive: true);
    debugPrint('Conversão concluída com sucesso!\n$name');
    Isolate.exit(sendPort, true);
  } catch (e) {
    debugPrint(e.toString());
    Isolate.exit(sendPort, false);
  }
}
