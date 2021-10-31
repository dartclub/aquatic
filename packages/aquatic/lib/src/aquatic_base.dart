import 'dart:async';
import 'dart:io';

import 'package:intl/locale.dart';
import 'package:aquatic/src/utils/utils.dart';

enum AquaticErrorLevel {
  /// stops the execution of the whole pipeline
  strict,

  /// ignores and skips the exception-effected file and continues
  ignoreAndSkip,
}

abstract class _AquaticContext {
  final String key;
  String path;
  String slug;
  Map? context;
  Locale contentLocale;
  DateTime buildTime;
  ContentType? contentType;
  String? get mimeType => contentType?.mimeType;
  String? get charset => contentType?.charset;

  String get contentLanguage => contentLocale.toLanguageTag();

  _AquaticContext(
    this.key,
    this.path,
    this.slug,
    this.context,
    this.contentType,
    Locale? contentLocale, {
    DateTime? buildTime,
  })  : contentLocale = contentLocale ?? Locale.parse('en_US'),
        buildTime = buildTime ?? DateTime.now();

  Map toMap();
}

abstract class AquaticSource extends _AquaticContext {
  final AquaticErrorLevel errorLevel;
  AquaticSource(
    String path, {
    required this.errorLevel,
    String? slug,
    // TODO required this.errorLevel,
    Map? context,
    ContentType? contentType,
    Locale? contentLocale,
    DateTime? buildTime,
  }) : super(
          path,
          path,
          AquaticUtils.slugify(slug ?? path),
          context,
          contentType,
          contentLocale,
        );

  @override
  Map toMap() => {
        "collection": {
          "path": path,
          "slug": slug,
          "contentLanguage": contentLanguage,
        },
        "site": context,
      };
  AquaticPipeline get pipeline;
  AquaticPipeline step(AquaticConverter converter) => pipeline.step(converter);
}

enum AquaticOperation {
  create,
  update,
  delete,
}

class AquaticEntity extends _AquaticContext {
  dynamic content;
  Map? inheritedContext;
  AquaticOperation operation;

  AquaticEntity(
    this.content, {
    required String path,
    AquaticSource? source,
    this.operation = AquaticOperation.create,
    String? slug,
    Map? context,
    ContentType? contentType,
    Locale? contentLocale,
  }) : super(
          path,
          path,
          AquaticUtils.slugify(slug ?? path),
          context,
          contentType ?? source?.contentType,
          contentLocale ?? source?.contentLocale,
        ) {
    inheritedContext = source?.context;
  }

  @override
  Map toMap() => {
        "page": {
          "key": key,
          "path": path,
          "slug": slug,
          "title": AquaticUtils.titelizeSlug(slug),
          "date": buildTime,
          "content": content,
          "contentLanguage": contentLanguage,
          "mineType": mimeType,
          "charset": charset,
          ...?context,
        },
        "path": path,
        "slug": slug,
        "content": content,
        "site": inheritedContext,
      };
}

class AquaticPipeline {
  final AquaticSource source;
  Stream<AquaticEntity> stream;

  AquaticPipeline(
    this.stream, {
    required this.source,
  });

  AquaticPipeline step(AquaticConverter converter) {
    stream = stream.asyncMap(converter.convert);
    return this;
  }
}

abstract class AquaticConverter {
  final List<String> allowedFileExtensions;
  final List<ContentType> allowedContentTypes;
  bool containsFileExtension(String path) {
    for (var ext in allowedFileExtensions) {
      if (path.endsWith(ext)) {
        return true;
      }
    }
    return false;
  }

  bool containsContentType(ContentType? type) {
    for (var allowedType in allowedContentTypes) {
      if (type == allowedType) {
        return true;
      }
    }
    return false;
  }

  AquaticConverter({
    List<String>? allowedFileExtensions,
    List<ContentType>? allowedContentTypes,
  })  : allowedFileExtensions = allowedFileExtensions ?? [],
        allowedContentTypes = allowedContentTypes ?? [];
  Future<AquaticEntity> convert(AquaticEntity entity);
}

typedef Future<AquaticEntity> ConvertFunction(AquaticEntity entity);
typedef Future<AquaticEntity> SkipFunction(AquaticEntity entity);

/// Simply use this to create an Aquatic converter by declaring a function instead of extending the `AquaticConverter` class
class AquaticSimpleConverter extends AquaticConverter {
  final ConvertFunction convertFunction;
  final SkipFunction skipFunction;
  final bool checkFileExtension;
  final bool checkContentType;

  static final SkipFunction _skipFunctionDefault =
      (AquaticEntity entity) async => entity;

  AquaticSimpleConverter(
    this.convertFunction, {
    SkipFunction? skipFunction,
    this.checkFileExtension = false,
    List<String>? allowedFileExtensions,
    this.checkContentType = false,
    List<ContentType>? allowedContentTypes,
  })  : skipFunction = skipFunction ?? _skipFunctionDefault,
        super(
          allowedFileExtensions: allowedFileExtensions,
          allowedContentTypes: allowedContentTypes,
        );

  @override
  Future<AquaticEntity> convert(AquaticEntity entity) async {
    if (checkFileExtension && !containsFileExtension(entity.path)) {
      return skipFunction(entity);
    }
    if (checkContentType && !containsContentType(entity.contentType)) {
      return skipFunction(entity);
    }
    return convertFunction(entity);
  }
}
