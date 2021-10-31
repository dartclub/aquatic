import 'dart:io';

import 'package:aquatic/aquatic.dart';
import 'package:yaml/yaml.dart';

class YAMLConverter extends AquaticConverter {
  final bool jekyllStyleHeader;
  final bool checkFileExtension;
  final bool checkContentType;

  YAMLConverter({
    this.jekyllStyleHeader = false,
    this.checkFileExtension = false,
    this.checkContentType = false,
  }) : super(
          allowedFileExtensions: ['.yml', '.yaml'],
          allowedContentTypes: [
            ContentType('text', 'yaml'),
            ContentType('text', 'x-yaml'),
            ContentType('application', 'x-yaml'),
          ],
        );

  @override
  Future<AquaticEntity> convert(AquaticEntity entity) async {
    var convert = (!checkFileExtension || containsFileExtension(entity.path)) ||
        (!checkContentType || containsContentType(entity.contentType));

    if (jekyllStyleHeader) {
      var parts = entity.content.split('---\n');
      entity.context!.addAll(loadYaml(parts[1]) as Map);
      entity.content = parts[2];
    } else {
      if (convert) {
        entity.content = loadYaml(entity.content) as Map;
        entity.context?.addAll(entity.content);
      } else {
        throw AquaticException.type('.yaml', entity.contentType);
      }
    }
    return entity;
  }
}
