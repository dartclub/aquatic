import 'dart:io';

import 'package:aquatic/aquatic.dart';
import 'package:intl/locale.dart';

/// single file source
class AquaticFileSource extends AquaticSource {
  final bool watch;
  final File file;
  final int events;

  AquaticFileSource(
    String path, {
    this.watch = false,
    this.events = FileSystemEvent.all,
    String? slug,
    Map? context,
    Locale? currentLocale,
  })  : file = File(path),
        super(
          path,
          slug: slug,
          context: context,
        );

  AquaticOperation _convertOp(int event) {
    switch (event) {
      case FileSystemEvent.modify:
        return AquaticOperation.update;
      case FileSystemEvent.move:
        return AquaticOperation.update;
      case FileSystemEvent.delete:
        return AquaticOperation.delete;
      case FileSystemEvent.create:
      case FileSystemEvent.all:
      default:
        return AquaticOperation.create;
    }
  }

  Stream<AquaticEntity> _getFile() {
    try {
      if (watch) {
        return file.watch(events: events).asyncMap(
              (event) async => AquaticEntity(
                await file.readAsString(),
                path: event.path,
                contentLocale: contentLocale,
                operation: _convertOp(event.type),
                source: this,
              ),
            );
      } else {
        return Stream.fromIterable([
          AquaticEntity(
            file.readAsStringSync(),
            path: path,
            contentLocale: contentLocale,
            source: this,
          ),
        ]);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  AquaticPipeline get pipeline => AquaticPipeline(_getFile(), source: this);
}
