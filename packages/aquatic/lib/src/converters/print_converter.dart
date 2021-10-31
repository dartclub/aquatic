import 'package:aquatic/aquatic.dart';

class PrintConverter extends AquaticConverter {
  final bool full;

  PrintConverter({this.full = true});
  @override
  Future<AquaticEntity> convert(AquaticEntity entity) async {
    print('===============================');
    print('path: ${entity.path}');
    if (full) {
      print('operation: ${entity.operation}');
      print('contentLocale: ' + entity.contentLocale.toLanguageTag());
      print('contentType: ${entity.contentType}');
      print('context:');
      (entity.context ?? entity.inheritedContext)
          ?.entries
          .forEach((entry) => print('\t${entry.key}: ${entry.value}'));
    }
    print('-------------------------------');
    print(entity.content);

    print('===============================');

    return entity;
  }
}
