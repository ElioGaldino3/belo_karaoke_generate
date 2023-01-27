import 'dart:async';

import 'package:belo_karaoke_generate/core/repositories/youtube_repository.dart';
import 'package:belo_karaoke_generate/widgets/custom_text_field.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:process_run/shell.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController urlFieldController;
  late final TextEditingController nameFieldController;
  late final StreamController<String> homePageMessageStream;
  final columnGap = 8.0;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          CustomTextField(
            controller: urlFieldController,
            placeholder: 'Link do video',
          ),
          SizedBox(height: columnGap),
          CustomTextField(
            controller: nameFieldController,
            placeholder: 'Nome da Música',
          ),
          SizedBox(height: columnGap + 6),
          ElevatedButton(
            child: const Text('Baixar'),
            onPressed: _downloadMusicAndVocalRemover,
          ),
          SizedBox(height: columnGap + 6),
          StreamBuilder(
            stream: homePageMessageStream.stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Text('Aguardando para baixar...');
              }

              return Text(snapshot.data ?? 'Aguardando para baixar...');
            },
          )
        ]),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    urlFieldController = TextEditingController();
    nameFieldController = TextEditingController();
    homePageMessageStream = StreamController<String>.broadcast();
    homePageMessageStream.sink.add('Aguardando para baixar...');
  }

  @override
  void dispose() {
    urlFieldController.dispose();
    nameFieldController.dispose();
    homePageMessageStream.close();
    super.dispose();
  }

  void _setLoading(bool state) {
    setState(() {
      isLoading = state;
    });
  }

  Future<void> _downloadMusicAndVocalRemover() async {
    if (urlFieldController.text.isEmpty && nameFieldController.text.isEmpty) {
      homePageMessageStream.sink.add('Preencha todos os campos');
      return;
    }
    _setLoading(true);
    final repository =
        YoutubeRepository(YoutubeExplode(), Dio(), homePageMessageStream.sink);
    try {
      await repository.downloadMp3(
          urlFieldController.text, nameFieldController.text);
      homePageMessageStream.sink.add(
          'Separando os instrumentos do vocal... Isso pode demorar um pouco');
      await Shell().run('''
                  ffmpeg -y -i "./${nameFieldController.text}.webm" "./${nameFieldController.text}.mp3"
                  python ./vocal-remover/inference.py --input "./${nameFieldController.text}.mp3" --gpu 0
                  rm "./${nameFieldController.text}.webm"
                  rm "./${nameFieldController.text}.mp3"
                  rm "./${nameFieldController.text}_Vocals.wav"
                  
                  ffmpeg -y -i "./${nameFieldController.text}_Instruments.wav" "./results/${nameFieldController.text}.mp3"
                  rm "./${nameFieldController.text}_Instruments.wav"
              ''');
      homePageMessageStream.sink.add(
          'Conversão concluída com sucesso! Agora você já pode baixar outras músicas');
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      homePageMessageStream.sink
          .add('Error: ${e.toString()}\nTente Novamente!');
    }
  }
}
