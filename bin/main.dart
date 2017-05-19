import 'dart:async';
import 'dart:io';
import 'dart:convert' show JSON;

import 'package:gcloud/db.dart' as db;
import 'package:gcloud/src/datastore_impl.dart' as datastore_impl;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:gcloud/service_scope.dart' as ss;

main(List<String> args) async {
  var datastoreDB =
      await _getDatastoreDB("./bin/datastore_service_account_credentials.json");
  var withServicesScopes = (callback()) => ss.fork(() {
        // register the services in the new service scope.
        db.registerDbService(datastoreDB);
        return callback();
      });

  withServicesScopes(() async {
    await db.dbService.commit(inserts: [
      new _TestDouble()
        ..name = "test double"
        ..weightMin = 1.0
        ..weightMax = 1.9
    ]);

    List<_TestDouble> allRecords =
        await db.dbService.query(_TestDouble).run().toList();

    print(
        '{name: ${allRecords.last.name}, weightMin: ${allRecords.last.weightMin}, weightMax: ${allRecords.last.weightMax},} ');
  });
}

Future<db.DatastoreDB> _getDatastoreDB(
    String datastoreServiceAccountFilePath) async {
  // Read the service account credentials from the file.
  var jsonCredentials =
      new File(datastoreServiceAccountFilePath).readAsStringSync();
  var credentials =
      new auth.ServiceAccountCredentials.fromJson(jsonCredentials);

  // Get an HTTP authenticated client using the service account credentials.
  List<String> scopes = []..addAll(datastore_impl.DatastoreImpl.SCOPES);
  var client = await auth.clientViaServiceAccount(credentials, scopes);
  var projectId = "${JSON.decode(jsonCredentials)["project_id"]}";

  // Instantiate objects to access Cloud Datastore
  return new db.DatastoreDB(
      new datastore_impl.DatastoreImpl(client, projectId));
}

@db.Kind(name: "testDouble")
class _TestDouble extends db.Model {
  @db.StringProperty()
  String name;

  // Weight restrictions
  @db.DoubleProperty(indexed: false)
  double weightMin;

  @db.DoubleProperty(indexed: false)
  double weightMax;
}
