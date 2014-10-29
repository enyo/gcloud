// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library gcloud.db.properties_test;

import 'dart:typed_data';

import 'package:gcloud/db.dart';
import 'package:gcloud/datastore.dart' as datastore;
import 'package:unittest/unittest.dart';

main() {
  group('properties', () {
    test('bool_property', () {
      var prop = const BoolProperty(required: true);
      expect(prop.validate(null, null), isFalse);

      prop = const BoolProperty(required: false);
      expect(prop.validate(null, null), isTrue);
      expect(prop.validate(null, true), isTrue);
      expect(prop.validate(null, false), isTrue);
      expect(prop.encodeValue(null, null), equals(null));
      expect(prop.encodeValue(null, true), equals(true));
      expect(prop.encodeValue(null, false), equals(false));
      expect(prop.decodePrimitiveValue(null, null), equals(null));
      expect(prop.decodePrimitiveValue(null, true), equals(true));
      expect(prop.decodePrimitiveValue(null, false), equals(false));
    });

    test('int_property', () {
      var prop = const IntProperty(required: true);
      expect(prop.validate(null, null), isFalse);

      prop = const IntProperty(required: false);
      expect(prop.validate(null, null), isTrue);
      expect(prop.validate(null, 33), isTrue);
      expect(prop.encodeValue(null, null), equals(null));
      expect(prop.encodeValue(null, 42), equals(42));
      expect(prop.decodePrimitiveValue(null, null), equals(null));
      expect(prop.decodePrimitiveValue(null, 99), equals(99));
    });

    test('string_property', () {
      var prop = const StringProperty(required: true);
      expect(prop.validate(null, null), isFalse);

      prop = const StringProperty(required: false);
      expect(prop.validate(null, null), isTrue);
      expect(prop.validate(null, 'foobar'), isTrue);
      expect(prop.encodeValue(null, null), equals(null));
      expect(prop.encodeValue(null, 'foo'), equals('foo'));
      expect(prop.decodePrimitiveValue(null, null), equals(null));
      expect(prop.decodePrimitiveValue(null, 'bar'), equals('bar'));
    });

    test('blob_property', () {
      var prop = const BlobProperty(required: true);
      expect(prop.validate(null, null), isFalse);

      prop = const BlobProperty(required: false);
      expect(prop.validate(null, null), isTrue);
      expect(prop.validate(null, [1,2]), isTrue);
      expect(prop.encodeValue(null, null), equals(null));
      expect(prop.encodeValue(null, []).bytes, equals([]));
      expect(prop.encodeValue(null, [1,2]).bytes, equals([1,2]));
      expect(prop.encodeValue(null, new Uint8List.fromList([1,2])).bytes,
             equals([1,2]));
      expect(prop.decodePrimitiveValue(null, null), equals(null));
      expect(prop.decodePrimitiveValue(null, new datastore.BlobValue([])),
          equals([]));
      expect(prop.decodePrimitiveValue(null, new datastore.BlobValue([5,6])),
          equals([5,6]));
      expect(prop.decodePrimitiveValue(
          null, new datastore.BlobValue(new Uint8List.fromList([5,6]))),
             equals([5,6]));
    });

    test('datetime_property', () {
      var utc99 = new DateTime.fromMillisecondsSinceEpoch(99, isUtc: true);

      var prop = const DateTimeProperty(required: true);
      expect(prop.validate(null, null), isFalse);

      prop = const DateTimeProperty(required: false);
      expect(prop.validate(null, null), isTrue);
      expect(prop.validate(null, utc99), isTrue);
      expect(prop.encodeValue(null, null), equals(null));
      expect(prop.encodeValue(null, utc99), equals(utc99));
      expect(prop.decodePrimitiveValue(null, null), equals(null));
      expect(prop.decodePrimitiveValue(null, 99*1000), equals(utc99));
      expect(prop.decodePrimitiveValue(null, 99*1000 + 1), equals(utc99));
      expect(prop.decodePrimitiveValue(null, utc99), equals(utc99));
    });

    test('list_property', () {
      var prop = const ListProperty(const BoolProperty());

      expect(prop.validate(null, null), isFalse);
      expect(prop.validate(null, []), isTrue);
      expect(prop.validate(null, [true, false]), isTrue);
      expect(prop.validate(null, [true, false, 1]), isFalse);
      expect(prop.encodeValue(null, []), equals(null));
      expect(prop.encodeValue(null, [true]), equals(true));
      expect(prop.encodeValue(null, [true, false]), equals([true, false]));
      expect(prop.decodePrimitiveValue(null, null), equals([]));
      expect(prop.decodePrimitiveValue(null, []), equals([]));
      expect(prop.decodePrimitiveValue(null, true), equals([true]));
      expect(prop.decodePrimitiveValue(null, [true, false]),
             equals([true, false]));
    });

    test('modelkey_property', () {
      var datastoreKey = new datastore.Key(
          [new datastore.KeyElement('MyKind', 42)],
          partition: new datastore.Partition('foonamespace'));
      var dbKey = new KeyMock(datastoreKey);
      var modelDBMock = new ModelDBMock(datastoreKey, dbKey);

      var prop = const ModelKeyProperty(required: true);
      expect(prop.validate(modelDBMock, null), isFalse);

      prop = const ModelKeyProperty(required: false);
      expect(prop.validate(modelDBMock, null), isTrue);
      expect(prop.validate(modelDBMock, dbKey), isTrue);
      expect(prop.validate(modelDBMock, datastoreKey), isFalse);
      expect(prop.encodeValue(modelDBMock, null), equals(null));
      expect(prop.encodeValue(modelDBMock, dbKey), equals(datastoreKey));
      expect(prop.decodePrimitiveValue(modelDBMock, null), equals(null));
      expect(prop.decodePrimitiveValue(modelDBMock, datastoreKey),
             equals(dbKey));
    });
  });
}

class KeyMock implements Key {
  datastore.Key _datastoreKey;

  KeyMock(this._datastoreKey);

  Object id = 1;
  Type type = null;
  Key get parent => this;
  bool get isEmpty => false;
  Partition get partition => null;
  datastore.Key get datastoreKey => _datastoreKey;
  Key append(Type modelType, {Object id}) => null;
  int get hashCode => 1;
}

class ModelDBMock implements ModelDB {
  final datastore.Key _datastoreKey;
  final Key _dbKey;
  ModelDBMock(this._datastoreKey, this._dbKey);

  Key fromDatastoreKey(datastore.Key datastoreKey) {
    if (!identical(_datastoreKey, datastoreKey)) {
      throw "Broken test";
    }
    return _dbKey;
  }

  datastore.Key toDatastoreKey(Key key) {
    if (!identical(_dbKey, key)) {
     throw "Broken test";
    }
    return _datastoreKey;
  }

  modelDescriptionState(ModelDescription modelDescription) => null;
  Iterable<ModelDescription> get modelDescriptions => null;
  Map<String, Property> propertiesForModel(modelDescription) => null;
  modelClass(ModelDescription md) => null;
  Model fromDatastoreEntity(datastore.Entity entity) => null;
  ModelDescription modelDescriptionForType(Type type) => null;
  datastore.Entity toDatastoreEntity(Model model) => null;
  String fieldNameToPropertyName(String kind, String fieldName) => null;
  String kindName(Type type) => null;
}
