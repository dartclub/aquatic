import 'package:aquatic/aquatic.dart';
import 'package:archive/archive_io.dart';

class UnzipConverter extends AquaticConverter {
  @override
  Future<AquaticEntity> convert(AquaticEntity entity) async {
    if (entity.content is List<int>) {
      var unzipped = ZipDecoder().decodeBytes(entity.content);
      var first = unzipped.files.first;
      if (first.isFile) {
        return AquaticEntity(
          first.content,
          path: first.name,
          // TODO pass other args
        );
      }
    }

    throw Exception();
  }
}
