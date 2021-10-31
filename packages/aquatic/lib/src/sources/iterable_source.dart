import 'package:aquatic/aquatic.dart';

class AquaticIterableSource extends AquaticSource {
  final Iterable<AquaticEntity> iterable;

  AquaticIterableSource(
    this.iterable, {
    AquaticErrorLevel errorLevel = AquaticErrorLevel.ignoreAndSkip,
    String path = '',
  }) : super(
          path,
          errorLevel: errorLevel,
        );

  @override
  AquaticPipeline get pipeline =>
      AquaticPipeline(Stream.fromIterable(iterable), source: this);
}
