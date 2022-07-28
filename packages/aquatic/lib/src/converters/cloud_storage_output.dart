import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:aquatic/aquatic.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:gcloud/storage.dart';

class CloudStorageConverter extends AquaticConverter {
  final String projectId;
  final String bucketName;
  String? credentialPath;
  late http.Client client;
  late Storage storage;
  late Bucket bucket;

  CloudStorageConverter(this.projectId, this.bucketName, this.credentialPath);
  CloudStorageConverter.inject(this.projectId, this.bucketName, this.client);

  Future<auth.AutoRefreshingAuthClient> _authenticate() async {
    var jsonCredentials =
        File(credentialPath ?? '$projectId.json').readAsStringSync();
    var credentials = auth.ServiceAccountCredentials.fromJson(jsonCredentials);

    return auth.clientViaServiceAccount(credentials, Storage.SCOPES);
  }

  @override
  Future<AquaticEntity> convert(AquaticEntity entity) async {
    client = await _authenticate();
    storage = Storage(client, projectId);
    if (!await storage.bucketExists(bucketName)) {
      await storage.createBucket(bucketName);
    }
    bucket = storage.bucket(bucketName);
    if (entity.content is String || entity.content is Uint8List) {
      List<int> bytes = (entity.content is String)
          ? entity.content.codeUnits
          : (entity.content as Uint8List).toList();

      var resp = await bucket.writeBytes(
        entity.path,
        bytes,
        metadata: ObjectMetadata(
          contentType: entity.mimeType,
          contentEncoding: entity.charset,
          contentLanguage: entity.contentLanguage,
        ),
      );

      entity.path = resp.downloadLink.toString();
    } else {
      throw Exception('\'content\' must be of type String or Uint8List');
    }
    return entity;
  }
}
