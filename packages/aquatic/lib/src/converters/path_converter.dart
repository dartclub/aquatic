import 'package:aquatic/aquatic.dart';
import 'package:aquatic/src/converters/permalink.dart';
import 'package:aquatic/src/utils/utils.dart';

class PathReplaceConvert extends AquaticConverter {
  final Pattern from;
  final String replacement;
  final ReplacementType replacementType;

  PathReplaceConvert(this.from, this.replacement,
      {this.replacementType = ReplacementType.last});

  @override
  Future<AquaticEntity> convert(AquaticEntity entity) async {
    var replaced = entity.path.replace(from, replacement, replacementType);
    entity.slug = AquaticUtils.slugify(replaced);
    entity.path = replaced;
    return entity;
  }
}

class PathPermalinkConvert extends AquaticConverter {
  String permalinkTemplate;
  final bool allowPermalinkVar;

  PathPermalinkConvert(
    this.permalinkTemplate, /* fallback, if allowPermalinkVar is enabled */ {
    this.allowPermalinkVar = true,
  });
  @override
  Future<AquaticEntity> convert(AquaticEntity entity) async {
    permalinkTemplate = allowPermalinkVar
        ? (entity.context?['permalink'] ?? permalinkTemplate)
        : permalinkTemplate;

    entity.path = PermalinkTemplate(entity).render(permalinkTemplate);
    return entity;
  }
}
