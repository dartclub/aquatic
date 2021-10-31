import 'package:aquatic/aquatic.dart';
import 'package:aquatic/src/converters/markdown_converter.dart';
import 'package:aquatic/src/converters/print_converter.dart';
import 'package:aquatic/src/converters/yaml_converter.dart';
import 'package:aquatic/src/sources/directory_source.dart';
import 'package:aquatic/src/sources/iterable_source.dart';
import 'package:aquatic/src/utils/logger.dart';

Future<void> main(List<String> args) async {
  var logger = AquaticLogger();

  var pipelines = <AquaticPipeline>[
    AquaticDirectorySource('_files', watch: false)
        .step(YAMLConverter(jekyllStyleHeader: true))
        .step(MarkdownConverter()),
    AquaticIterableSource([
      AquaticEntity('# Hello World 1', path: 'first'),
      AquaticEntity('*Hello World 2*', path: 'second'),
      AquaticEntity('**Hello World 3**', path: 'third'),
    ]).step(MarkdownConverter()).step(PrintConverter(logger)),
  ];

  for (var pipeline in pipelines) {
    logger.log((await pipeline.stream.first).content);
  }

  Future.delayed(Duration(seconds: 4), () {
    logger.printAll();
  });
}
