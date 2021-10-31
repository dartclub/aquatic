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
    AquaticErrorLevel errorLevel = AquaticErrorLevel.ignoreAndSkip,
    this.watch = false,
    this.events = FileSystemEvent.all,
    String? slug,
    Map? context,
    Locale? currentLocale,
  })  : file = File(path),
        super(
          path,
          errorLevel: errorLevel,
          slug: slug,
          context: context,
        );

  Stream<AquaticEntity> _initStream() {
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
  AquaticPipeline get pipeline => AquaticPipeline(_initStream(), source: this);
}
