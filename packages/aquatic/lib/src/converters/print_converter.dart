import 'package:aquatic/aquatic.dart';
import 'package:aquatic/src/utils/logger.dart';

class PrintConverter extends AquaticConverter {
  final bool full;
  final AquaticLogger logger;
// TODO find a solution
  PrintConverter(this.logger, {this.full = true});
  @override
  Future<AquaticEntity> convert(AquaticEntity entity) async {
    logger.log('===============================');
    logger.log('path: ${entity.path}');
    if (full) {
      logger.log('operation: ${entity.operation}');
      logger.log('contentLocale: ' + entity.contentLocale.toLanguageTag());
      logger.log('contentType: ${entity.contentType}');
      logger.log('context:');
      (entity.context ?? entity.inheritedContext)
          ?.entries
          .forEach((entry) => logger.log('\t${entry.key}: ${entry.value}'));
    }
    logger.log('-------------------------------');
    logger.log(entity.content);

    logger.log('===============================');

    return entity;
  }
}
