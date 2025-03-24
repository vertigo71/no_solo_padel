import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diacritic/diacritic.dart';

import '../interface/app_state.dart';

StreamTransformer<QuerySnapshot<Map<String, dynamic>>, List<T>> transformer<T>(
        T Function(Map<String, dynamic> json) fromJson) =>
    StreamTransformer<QuerySnapshot<Map<String, dynamic>>, List<T>>.fromHandlers(
      handleData: (QuerySnapshot<Map<String, dynamic>> data, EventSink<List<T>> sink) {
        final List<Map<String, dynamic>> snaps = data.docs.map((doc) => doc.data()).toList();
        final List<T> items = snaps.map((json) => fromJson(json)).toList();

        sink.add(items);
      },
    );

StreamTransformer<QuerySnapshot<Map<String, dynamic>>, List<T>> transformerWithState<T>(
        T Function(Map<String, dynamic>, AppState) fromJson, AppState appState) =>
    StreamTransformer<QuerySnapshot<Map<String, dynamic>>, List<T>>.fromHandlers(
      handleData: (QuerySnapshot<Map<String, dynamic>> data, EventSink<List<T>> sink) {
        final List<Map<String, dynamic>> snaps = data.docs.map((doc) => doc.data()).toList();
        final List<T> items = snaps.map((json) => fromJson(json, appState)).toList();

        sink.add(items);
      },
    );

int boolToInt(bool value) => value ? 1 : 0;

bool intToBool(int value) => value == 0 ? false : true;

String boolToStr(bool value) => value.toString();

/// true if value != 0 or is 'true'
bool strToBool(String value) {
  int? intValue = int.tryParse(value);
  if (intValue != null) return intValue != 0;
  if (value == 'true') return true;
  return false;
}

String lowCaseNoDiacritics(String str) => removeDiacritics(str.toLowerCase());
