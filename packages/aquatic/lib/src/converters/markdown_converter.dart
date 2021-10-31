import 'package:aquatic/aquatic.dart';
import 'package:markdown/markdown.dart';

class MarkdownConverter extends AquaticConverter {
  final bool checkFileExtension;
  final bool checkContentType;

  MarkdownConverter({
    this.checkFileExtension = false,
    this.checkContentType = false,
  }) : super(
          allowedFileExtensions: ['.md', '.markdown'],
        );

  @override
  Future<AquaticEntity> convert(AquaticEntity entity) async {
    var convert = (!checkFileExtension || containsFileExtension(entity.path)) ||
        (!checkContentType || containsContentType(entity.contentType));

    if (convert) {
      entity.content = markdownToHtml(entity.content);
    } else {
      throw AquaticException.type('.md', entity.contentType);
    }
    return entity;
  }
}
