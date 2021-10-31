import 'dart:convert';
import 'dart:io';

import 'package:aquatic/aquatic.dart';

class JSONConverter extends AquaticConverter {
  final bool checkFileExtension;
  final bool checkContentType;
  JSONConverter({
    this.checkFileExtension = false,
    this.checkContentType = false,
  }) : super(
          allowedFileExtensions: ['.json'],
          allowedContentTypes: [ContentType.json],
        );

  @override
  Future<AquaticEntity> convert(AquaticEntity entity) async {
    var convert = (!checkFileExtension || containsFileExtension(entity.path)) ||
        (!checkContentType || containsContentType(entity.contentType));

    if (convert && entity.content is String) {
      entity.content = jsonDecode(entity.content);
      if (entity.content is Map) entity.context?.addAll(entity.content);
    } else {
      // TODO throw
    }

    return entity;
  }
}
