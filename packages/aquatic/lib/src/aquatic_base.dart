import 'dart:async';
import 'dart:io';

import 'package:aquatic/aquatic.dart';
import 'package:aquatic/src/utils/logger.dart';
import 'package:intl/locale.dart';
import 'package:aquatic/src/utils/utils.dart';

enum AquaticErrorLevel {
  /// stops the execution of the whole pipeline
  strict,

  /// ignores and skips the exception-effected file and continues
  ignoreAndSkip,
}

class AquaticException {
  final String message;

  AquaticException(this.message);

  factory AquaticException.type(expected, actual) => AquaticException(
      'expected content type was $expected, but the actual type was $actual');

  factory AquaticException.path(String path) =>
      AquaticException('invalid file path: \'$path\'');

  factory AquaticException.init(String message) =>
      AquaticException('error initializing the pipline: $message');

  factory AquaticException.either(
          AquaticException either, AquaticException or) =>
      AquaticException('skipped because of $either or $or');

  @override
  String toString() {
    return message;
  }
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
  final AquaticLogger logger = AquaticLogger();

  AquaticSource(
    String path, {
    required this.errorLevel,
    String? slug,
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

  Future<void> onClose() async {
    return;
  }
}

class AquaticPipeline {
  final AquaticSource source;
  Stream<AquaticEntity> stream;

  AquaticPipeline(
    this.stream, {
    required this.source,
  });

  AquaticPipeline step(_AquaticAction converter) {
    stream = stream.asyncExpand(
      (entity) async* {
        try {
          var entities = await converter.executeInternally(entity);
          yield* Stream.fromIterable(entities);
        } catch (e) {
          if (source.errorLevel == AquaticErrorLevel.strict) {
            source.logger.error(e.toString());
            rethrow;
          } else {
            source.logger.warn(e.toString());
            yield entity;
          }
        }
      },
    );
    return this;
  }
}

enum AquaticOperation {
  create,
  write,
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

abstract class _AquaticAction {
  final List<String> allowedFileExtensions;
  final List<ContentType> allowedContentTypes;

  _AquaticAction({
    this.allowedFileExtensions = const [],
    this.allowedContentTypes = const [],
  });

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

  Future<void> onClose();
  Future<Iterable<AquaticEntity>> executeInternally(AquaticEntity entity);
}

abstract class AquaticConverter extends _AquaticAction {
  AquaticConverter({super.allowedFileExtensions, super.allowedContentTypes});

  Future<AquaticEntity> convert(AquaticEntity entity);

  @override
  Future<Iterable<AquaticEntity>> executeInternally(
          AquaticEntity entity) async =>
      [await convert(entity)];

  @override
  Future<void> onClose() async {
    return;
  }
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
          allowedFileExtensions: allowedFileExtensions ?? [],
          allowedContentTypes: allowedContentTypes ?? [],
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

abstract class AquaticExpander extends _AquaticAction {
  AquaticExpander({super.allowedFileExtensions, super.allowedContentTypes});

  Future<Iterable<AquaticEntity>> expand(AquaticEntity entity);

  @override
  Future<Iterable<AquaticEntity>> executeInternally(AquaticEntity entity) =>
      expand(entity);

  @override
  Future<void> onClose() async {
    return;
  }
}

typedef Future<List<AquaticEntity>> ExpandFunction(AquaticEntity entity);
typedef Future<List<AquaticEntity>> ExpandSkipFunction(AquaticEntity entity);

class AquaticSimpleExpander extends AquaticExpander {
  final ExpandFunction expandFunction;
  final ExpandSkipFunction skipFunction;
  final bool checkFileExtension;
  final bool checkContentType;

  static final _skipFunctionDefault =
      (AquaticEntity entity) async => <AquaticEntity>[entity];

  AquaticSimpleExpander(
    this.expandFunction, {
    ExpandSkipFunction? skipFunction,
    this.checkFileExtension = false,
    List<String>? allowedFileExtensions,
    this.checkContentType = false,
    List<ContentType>? allowedContentTypes,
  })  : skipFunction = skipFunction ?? _skipFunctionDefault,
        super(
          allowedFileExtensions: allowedFileExtensions ?? [],
          allowedContentTypes: allowedContentTypes ?? [],
        );

  @override
  Future<Iterable<AquaticEntity>> expand(AquaticEntity entity) {
    if (checkFileExtension && !containsFileExtension(entity.path)) {
      return skipFunction(entity);
    }
    if (checkContentType && !containsContentType(entity.contentType)) {
      return skipFunction(entity);
    }
    return expandFunction(entity);
  }
}
