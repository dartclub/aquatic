import 'dart:io';

import 'package:aquatic/aquatic.dart';
import 'package:aquatic/src/utils/utils.dart';

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

  Stream<AquaticEntity> _getStream() {
    try {
      if (watch) {
        return file.watch(events: events).asyncMap(
              (event) async => AquaticEntity(
                await file.readAsString(),
                path: event.path,
                contentLocale: contentLocale,
                operation: AquaticUtils.convertFileEventToOp(event.type),
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
  AquaticPipeline get pipeline => AquaticPipeline(_getStream(), source: this);
}