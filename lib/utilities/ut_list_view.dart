import 'package:collection/collection.dart';

class MyListView<T> implements Iterable<T> {
  final List<T> _list;

  MyListView(List<T> initialList) : _list = initialList;

  // Accessing elements (List-specific)
  T operator [](int index) => _list[index];

  int indexOf(T element, [int start = 0]) => _list.indexOf(element, start);

  // Basic properties
  @override
  int get length => _list.length;

  @override
  toString() => _list.toString();

  @override
  bool get isEmpty => _list.isEmpty;

  @override
  bool get isNotEmpty => _list.isNotEmpty;

  @override
  T get first => _list.first;

  @override
  T get last => _list.last;

  @override
  T elementAt(int index) => _list.elementAt(index);

  // Iteration
  @override
  Iterator<T> get iterator => _list.iterator;

  // Checking contents
  @override
  bool contains(Object? element) => _list.contains(element);

  @override
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) => _list.firstWhere(test, orElse: orElse);

  @override
  T lastWhere(bool Function(T element) test, {T Function()? orElse}) => _list.lastWhere(test, orElse: orElse);

  @override
  T singleWhere(bool Function(T element) test, {T Function()? orElse}) => _list.singleWhere(test, orElse: orElse);

  // Creating new ListViews (wrapping the result if possible)
  @override
  MyListView<R> cast<R>() => MyListView(_list.cast<R>());

  @override
  Iterable<T> skip(int count) => _list.skip(count); // Returns a lazy Iterable

  @override
  Iterable<T> skipWhile(bool Function(T value) test) => _list.skipWhile(test); // Returns a lazy Iterable

  @override
  Iterable<T> take(int count) => _list.take(count); // Returns a lazy Iterable

  @override
  Iterable<T> takeWhile(bool Function(T value) test) => _list.takeWhile(test); // Returns a lazy Iterable

  @override
  Iterable<T> where(bool Function(T element) test) => _list.where(test); // Returns a lazy Iterable

  @override
  Iterable<R> map<R>(R Function(T e) toElement) => _list.map(toElement); // Returns a lazy Iterable

  @override
  Iterable<R> expand<R>(Iterable<R> Function(T element) f) => _list.expand(f); // Returns a lazy Iterable

  @override
  Iterable<T> followedBy(Iterable<T> other) => _list.followedBy(other); // Returns a lazy Iterable

  @override
  Iterable<R> whereType<R>() => _list.whereType<R>(); // Returns a lazy Iterable

  // Other useful methods
  @override
  List<T> toList({bool growable = false}) => List.from(_list);

  @override
  Set<T> toSet() => _list.toSet();

  @override
  String join([String separator = ""]) => _list.join(separator);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MyListView && ListEquality().equals(_list, other._list);

  @override
  int get hashCode => ListEquality<T>().hash(_list);

  @override
  bool any(bool Function(T element) test) => _list.any(test);

  @override
  bool every(bool Function(T element) test) => _list.every(test);

  @override
  T reduce(T Function(T value, T element) combine) => _list.reduce(combine);

  @override
  T get single => _list.single;

  @override
  void forEach(void Function(T element) action) => _list.forEach(action);

  @override
  R fold<R>(R initialValue, R Function(R previousValue, T element) combine) => _list.fold<R>(initialValue, combine);
}
