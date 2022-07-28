import 'dart:async';

import 'package:aquatic/aquatic.dart';
import 'package:dart_amqp/dart_amqp.dart';

class AmqpSource extends AquaticSource {
  final ConnectionSettings connectionSettings;
  final String queueTag;

  final StreamController _controller = StreamController<AquaticEntity>();
  final Client _client;
  late Channel _channel;
  late Queue _queue;
  late Consumer _consumer;
  late StreamSubscription<AmqpMessage> _subscription;

  AmqpSource(
    this.connectionSettings,
    this.queueTag, {
    AquaticErrorLevel errorLevel = AquaticErrorLevel.ignoreAndSkip,
  })  : _client = Client(settings: connectionSettings),
        super(
          '',
          errorLevel: errorLevel,
        ) {
    _initStream();
  }

  Future<void> _initStream() async {
    _channel = await _client.channel();
    _queue = await _channel.queue(queueTag, durable: false);
    _consumer = await _queue.consume(consumerTag: queueTag, noAck: true);

    _subscription = _consumer.listen((AmqpMessage event) {
      // TODO handle acknowledgement/rejection
      _controller.sink.add(AquaticEntity(
        event.payloadAsString,
        path: '${event.exchangeName}/${event.routingKey}',
      ));
      // TODO pass other arguments from AmqpMessage event to AquaticEntity() constructor
    });
  }

  @override
  AquaticPipeline get pipeline => AquaticPipeline(
        _controller.stream.asBroadcastStream().cast<AquaticEntity>(),
        source: this,
      );

  void cancel() => _subscription.cancel();
}
