import 'package:aquatic/aquatic.dart';
import 'package:aquatic/src/utils/utils.dart';

class ReplaceConverter extends AquaticConverter {
  final Pattern from;
  final String replacement;
  final ReplacementType replacementType;

  ReplaceConverter(this.from, this.replacement,
      {this.replacementType = ReplacementType.last});

  @override
  Future<AquaticEntity> convert(AquaticEntity entity) async {
    if (entity.content is String) {
      entity.content =
          entity.content.replace(from, replacement, replacementType);
    } else {
      throw AquaticException.type(String, entity.content.runtimeType);
    }

    return entity;
  }
}
