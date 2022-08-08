import 'package:aquatic/aquatic.dart';
import 'package:xml/xml.dart';

class XmlConverter extends AquaticConverter {
  @override
  Future<AquaticEntity> convert(AquaticEntity entity) async {
    if (entity.content is String) {
      return entity..content = XmlDocument.parse(entity.content);
    }
    throw Exception();
  }
}
