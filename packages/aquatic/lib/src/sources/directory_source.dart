import 'dart:io';

import 'package:aquatic/aquatic.dart';
import 'package:aquatic/src/utils/utils.dart';

/// single file source
class AquaticDirectorySource extends AquaticSource {
  final bool watch;
  final bool recursive;
  final Directory directory;
  final int events;

  AquaticDirectorySource(
    String path, {
    this.recursive = true,
    this.watch = false,
    this.events = FileSystemEvent.all,
    String? slug,
    Map? context,
    Locale? currentLocale,
  })  : directory = Directory(path),
        super(
          path,
          slug: slug,
          context: context,
        );

  Stream<AquaticEntity> _getStream() {
    try {
      if (watch) {
        return directory
            .watch(events: events, recursive: recursive)
            .where((e) => !e.isDirectory)
            .asyncMap(
              (event) async => AquaticEntity(
                await File(path).readAsString(),
                path: event.path,
                contentLocale: contentLocale,
                operation: AquaticUtils.convertFileEventToOp(event.type),
                source: this,
              ),
            );
      } else {
        return Stream.fromIterable(
          directory.listSync(recursive: recursive).whereType<File>().map(
                (File file) => AquaticEntity(
                  file.readAsStringSync(),
                  path: file.path,
                  contentLocale: contentLocale,
                  source: this,
                ),
              ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  AquaticPipeline get pipeline => AquaticPipeline(_getStream(), source: this);
}
