import 'package:aquatic/aquatic.dart';
import 'package:dart_amqp/dart_amqp.dart';

class AmqpOutput extends AquaticConverter {
  final ConnectionSettings connectionSettings;
  final String queueTag;

  final Client _client;
  late Channel _channel;
  late Exchange _exchange;

  AmqpOutput(this.connectionSettings, this.queueTag)
      : _client = Client(settings: connectionSettings) {
    _initExchange();
  }

  Future<void> _initExchange() async {
    _channel = await _client.channel();
    _exchange = await _channel.exchange(queueTag, ExchangeType.FANOUT);
  }

  @override
  Future<AquaticEntity> convert(AquaticEntity entity) async {
    _exchange.publish(entity.content, null);

    return entity;
  }

  @override
  Future<void> onClose() async {
    await _client.close();
    return super.onClose();
  }
}
