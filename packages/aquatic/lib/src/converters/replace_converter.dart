import 'package:aquatic/aquatic.dart';
import 'package:aquatic/src/utils/utils.dart';

class ReplaceConvert extends AquaticConverter {
  final Pattern from;
  final String replacement;
  final ReplacementType replacementType;

  ReplaceConvert(this.from, this.replacement,
      {this.replacementType = ReplacementType.last});

  @override
  Future<AquaticEntity> convert(AquaticEntity entity) async {
    if (entity.content is String) {
      entity.content =
          entity.content.replace(from, replacement, replacementType);
    } else {
      // TODO throw Exception('to replace, \'content\' must be of type String');
    }

    return entity;
  }
}
