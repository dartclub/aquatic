import 'package:http/http.dart' as http;
import 'package:aquatic/aquatic.dart';

enum HttpMethod { get }

class HttpSource extends AquaticSource {
  final Map<String, String>? headers;
  final Duration? refreshInterval;
  late Stream<AquaticEntity> _stream;

  HttpSource(
    String url, {
    AquaticErrorLevel errorLevel = AquaticErrorLevel.ignoreAndSkip,
    this.refreshInterval,
    HttpMethod method = HttpMethod.get,
    this.headers,
  }) : super(url, errorLevel: errorLevel) {
    if (refreshInterval != null) {
      _stream = Stream.periodic(refreshInterval!, (period) => path)
          .asyncMap((event) async => _requestHandler());
    } else {
      _stream = Stream<AquaticEntity>.fromFuture(_requestHandler());
    }
  }

  Future<AquaticEntity> _requestHandler() async {
    var resp = await http.get(
      Uri.parse(path),
      headers: headers,
    );
    return AquaticEntity(resp.body, path: path);
  }

  @override
  AquaticPipeline get pipeline => AquaticPipeline(
        _stream,
        source: this,
      );
}
