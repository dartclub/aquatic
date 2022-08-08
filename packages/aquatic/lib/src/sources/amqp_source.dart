import 'dart:async';

import 'package:aquatic/aquatic.dart';
import 'package:dart_amqp/dart_amqp.dart';

class AmqpSource extends AquaticSource {
  final ConnectionSettings connectionSettings;
  final String queueTag;

  final StreamController _controller = StreamController<AquaticEntity>();
  final Client _client;
  late Channel _channel;
  late Exchange _exchange;
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
    try {
      var queue = await _channel.queue(queueTag, durable: false);
      _consumer = await queue.consume(consumerTag: queueTag, noAck: true);
    } on QueueNotFoundException {
      _exchange = await _channel.exchange(queueTag, ExchangeType.FANOUT);
      _consumer = await _exchange.bindQueueConsumer(
        queueTag,
        [],
        consumerTag: queueTag,
        noAck: true,
      );
    } catch (e) {
      rethrow;
    }

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

  @override
  Future<void> onClose() async {
    await _client.close();
    return super.onClose();
  }
}
