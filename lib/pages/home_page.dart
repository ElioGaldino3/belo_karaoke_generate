// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:isolate';

import 'package:belo_karaoke_generate/core/functions/download_and_remove_vocal.dart';
import 'package:belo_karaoke_generate/widgets/custom_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController urlFieldController;
  late final TextEditingController nameFieldController;
  late final Uuid uuid;
  final downloads = <DownloadAndConvertState>[];
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
            onPressed: _spawnAndReceive,
            child: const Text('Baixar'),
          ),
          SizedBox(height: columnGap + 6),
          Expanded(
            child: ListView(
              children: downloads
                  .map<Widget>(
                    (e) => ListTile(
                      title: Text(e.name),
                      subtitle: Text(e.url),
                      trailing: e is ErrorDownloadState
                          ? SizedBox(
                              width: 90,
                              child: Row(
                                children: [
                                  IconButton(
                                      onPressed: () =>
                                          _spawnAndReceive(downloadId: e.id),
                                      icon: const Icon(
                                          Icons.restart_alt_outlined)),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  IconButton(
                                      onPressed: () =>
                                          _removeFromDownloads(e.id),
                                      icon: const Icon(Icons.close)),
                                ],
                              ),
                            )
                          : const Text('Baixando...'),
                    ),
                  )
                  .toList(),
            ),
          )
        ]),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    urlFieldController = TextEditingController(
        text: kDebugMode
            ? "https://www.youtube.com/watch?v=2QKARCPO3sA&list=RD2QKARCPO3sA&start_radio=1&ab_channel=Stephen"
            : "");
    nameFieldController = TextEditingController(
        text: kDebugMode ? "Stephen - Bullet Train ft. Joni Fatora" : "");
    uuid = const Uuid();
  }

  @override
  void dispose() {
    urlFieldController.dispose();
    nameFieldController.dispose();
    super.dispose();
  }

  Future<void> _spawnAndReceive({String? downloadId}) async {
    if (urlFieldController.text.isEmpty &&
        nameFieldController.text.isEmpty &&
        downloadId == null) {
      showToast("Preencha todos os campos");
      return;
    }
    late String url;
    late String name;

    final id = downloadId ?? uuid.v4();
    if (downloadId != null) {
      final idx = downloads.indexWhere((element) => element.id == id);
      url = downloads[idx].url;
      name = downloads[idx].name;
      _removeFromDownloads(id);
    } else {
      url = urlFieldController.text;
      name = nameFieldController.text;
      urlFieldController.clear();
      nameFieldController.clear();
    }
    setState(() {
      downloads.add(DownloadingState(id: id, url: url, name: name));
    });
    var rp = ReceivePort();
    await Isolate.spawn(downloadMusicAndVocalRemover, [rp.sendPort, url, name]);
    final bool result = await rp.first;
    if (result) {
      _removeFromDownloads(id);
    } else {
      _updateToError(id);
    }
  }

  _removeFromDownloads(String id) {
    setState(() {
      downloads.removeWhere((element) => element.id == id);
    });
  }

  _updateToError(String id) {
    setState(() {
      final idx = downloads.indexWhere((element) => element.id == id);
      downloads[idx] = ErrorDownloadState(
          id: id, url: downloads[idx].url, name: downloads[idx].name);
    });
  }

  
}

abstract class DownloadAndConvertState {
  String id;
  String url;
  String name;
  DownloadAndConvertState({
    required this.id,
    required this.url,
    required this.name,
  });
}

class DownloadingState implements DownloadAndConvertState {
  @override
  String id;

  DownloadingState({
    required this.id,
    required this.name,
    required this.url,
  });

  @override
  String name;

  @override
  String url;
}

class ErrorDownloadState implements DownloadAndConvertState {
  @override
  String id;
  @override
  String name;
  @override
  String url;
  ErrorDownloadState({
    required this.id,
    required this.name,
    required this.url,
  });
}
