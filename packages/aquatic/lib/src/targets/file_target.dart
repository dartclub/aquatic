import 'package:aquatic/aquatic.dart';
import 'package:aquatic/src/utils/utils.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;

class FileOutput extends AquaticConverter {
  @override
  Future<AquaticEntity> convert(AquaticEntity entity) async {
    if (AquaticUtils.isUri(entity.path)) {
      throw AquaticException.path(entity.path);
    }

    var parts = path.split(entity.path);
    parts.removeLast();
    var folder = '';
    while (parts.isNotEmpty) {
      folder += '${folder.isNotEmpty ? '/' : ''}${parts.removeAt(0)}';
      var dir = Directory(folder);
      if (!(await dir.exists())) {
        await dir.create();
      }
    }
    var file = File(entity.path);
    await file.create();
    if (entity.content is String) {
      await file.writeAsString(entity.content);
    } else if (entity.content is Uint8List) {
      await file.writeAsBytes(entity.content);
    } else {
      throw AquaticException.type(
          'String or Uint8List', entity.content.runtimeType);
    }
    return entity;
  }
}
