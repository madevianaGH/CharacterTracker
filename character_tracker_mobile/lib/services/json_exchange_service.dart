import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../repositories/character_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'download_helper.dart';

class JsonExchangeService {
  final CharacterRepository repo;
  JsonExchangeService(this.repo);

  Future<void> exportCharacterAndShare(int charId) async {
    final payload = await repo.buildExportPayload(charId);

    final jsonText = const JsonEncoder.withIndent(
      '  ',
    ).convert(payload.toJson());

    final safeName =
        (payload.character.name.isEmpty ? 'personaje' : payload.character.name)
            .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');

    if (kIsWeb) {
      downloadTextFile('$safeName.json', jsonText);
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$safeName.json');
    await file.writeAsString(jsonText, encoding: utf8);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'CharacterTracker export (schema v2)',
      ),
    );
  }

  Future<int?> importCharacterFromPicker() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: kIsWeb, // <- en Web necesitamos bytes
      withReadStream: false,
    );
    if (res == null || res.files.isEmpty) return null;

    String text;

    if (kIsWeb) {
      final bytes = res.files.single.bytes;
      if (bytes == null) {
        throw Exception('No se pudieron leer los bytes del archivo en Web.');
      }
      text = utf8.decode(bytes);
    } else {
      final path = res.files.single.path;
      if (path == null) return null;
      text = await File(path).readAsString(encoding: utf8);
    }

    final decoded = jsonDecode(text);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('JSON inválido (se esperaba un objeto).');
    }

    final ver = (decoded['schema_version'] as num?)?.toInt() ?? 1;

    if (ver == 1) {
      final newId = await repo.createCharacter();
      return newId;
    }

    final payload = ExportPayloadV2.fromJson(decoded);
    final newId = await repo.importPayloadV2(payload);
    return newId;
  }
}
