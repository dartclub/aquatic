import 'dart:convert';

import 'package:aquatic/aquatic.dart';
import 'package:crypto/crypto.dart';

class TableStorageOutput extends AquaticConverter {
  String azureStorageKey = '';
  _hashMac(String value) {
    var encodedKey = base64Encode(azureStorageKey.codeUnits);
    var authenticator = Hmac(sha256, encodedKey.codeUnits);
    var signature = authenticator.convert(value.codeUnits);
    return signature.bytes;
  }

  @override
  Future<AquaticEntity> convert(AquaticEntity entity) {
    // TODO: implement convert
    throw UnimplementedError();
  }
}
