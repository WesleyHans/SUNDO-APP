import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundo_sipalay/features/live_map/osm_tile_provider.dart';

class _TileAdapter implements HttpClientAdapter {
  _TileAdapter(this.respond);

  final FutureOr<ResponseBody> Function(RequestOptions request) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const url = 'https://tile.openstreetmap.org/15/27526/15492.png';
  final png = TileProvider.transparentImage;
  late Directory directory;
  late DateTime time;
  final stores = <TileCacheStore>[];

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sundo_osm_cache_test_');
    time = DateTime.utc(2026, 10, 5, 9);
  });

  tearDown(() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    for (final store in stores) {
      await store.flush();
      store.dispose();
    }
    stores.clear();
    await directory.delete(recursive: true);
  });

  TileCacheStore createStore(_TileAdapter adapter,
      {int maxBytes = 128 * 1024 * 1024}) {
    final dio = Dio()..httpClientAdapter = adapter;
    final store = TileCacheStore(
        directory: directory, dio: dio, now: () => time, maxBytes: maxBytes);
    stores.add(store);
    return store;
  }

  ResponseBody tile({Map<String, List<String>>? headers}) =>
      ResponseBody.fromBytes(png, 200, headers: headers);

  Future<void> resolveImage(ImageProvider image) async {
    final loaded = Completer<void>();
    final stream = image.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener((info, _) {
      info.dispose();
      loaded.complete();
    }, onError: (Object error, StackTrace? stack) {
      loaded.completeError(error, stack);
    });
    stream.addListener(listener);
    try {
      await loaded.future;
    } finally {
      stream.removeListener(listener);
    }
  }

  test('decoded Flutter image cache still validates an expired HTTP tile',
      () async {
    final adapter = _TileAdapter((_) => tile(headers: {
          'cache-control': ['max-age=60'],
        }));
    final provider = CachedOsmTileProvider(store: createStore(adapter));
    final options = TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        tileProvider: provider);
    ImageProvider image() =>
        provider.getImage(const TileCoordinates(27526, 15492, 15), options);
    await resolveImage(image());
    await resolveImage(image());
    expect(adapter.requests, hasLength(1));
    expect(PaintingBinding.instance.imageCache.currentSize, 1);
    time = time.add(const Duration(minutes: 2));
    await resolveImage(image());
    expect(adapter.requests, hasLength(2));
  });

  test('decoded image cache cannot bypass server no-store on a revisit',
      () async {
    final adapter = _TileAdapter((_) => tile(headers: {
          'cache-control': ['no-store'],
        }));
    final provider = CachedOsmTileProvider(store: createStore(adapter));
    final options = TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        tileProvider: provider);
    ImageProvider image() =>
        provider.getImage(const TileCoordinates(27526, 15492, 15), options);
    await resolveImage(image());
    await resolveImage(image());
    expect(adapter.requests, hasLength(2));
    expect(PaintingBinding.instance.imageCache.currentSize, 0);
    expect(await directory.list().toList(), isEmpty);
  });

  test('fresh HTTP cache survives a new store without another tile download',
      () async {
    final adapter = _TileAdapter((_) => tile(headers: {
          'cache-control': ['public, max-age=604800'],
        }));
    final original = createStore(adapter);
    expect(await original.loadTile(url), orderedEquals(png));
    time = time.add(const Duration(days: 6));
    final reopened = createStore(adapter);
    expect(await reopened.loadTile(url), orderedEquals(png));
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.headers['User-Agent'],
        TileCacheStore.userAgent);
    expect(
        adapter.requests.single.headers.keys, isNot(contains('Cache-Control')));
    expect(adapter.requests.single.headers.keys, isNot(contains('Pragma')));
  });

  test('missing freshness headers keep previously viewed tiles for seven days',
      () async {
    final adapter = _TileAdapter((_) => tile());
    final store = createStore(adapter);
    await store.loadTile(url);
    time = time.add(const Duration(days: 6, hours: 23));
    await store.loadTile(url);
    expect(adapter.requests, hasLength(1));
    time = time.add(const Duration(hours: 2));
    await store.loadTile(url);
    expect(adapter.requests, hasLength(2));
  });

  test('expired tile uses both validators and a 304 refreshes freshness',
      () async {
    const lastModified = 'Sun, 04 Oct 2026 08:00:00 GMT';
    final adapter = _TileAdapter((request) {
      if (request.headers.containsKey('If-None-Match')) {
        return ResponseBody.fromBytes([], 304,
            headers: {
              'cache-control': ['public, max-age=3600'],
              'etag': ['"tile-version-1"'],
            });
      }
      return tile(headers: {
        'cache-control': ['public, max-age=3600'],
        'age': ['3500'],
        'etag': ['"tile-version-1"'],
        'last-modified': [lastModified],
      });
    });
    final store = createStore(adapter);
    await store.loadTile(url);
    time = time.add(const Duration(seconds: 101));
    expect(await store.loadTile(url), orderedEquals(png));
    expect(adapter.requests.last.headers['If-None-Match'], '"tile-version-1"');
    expect(adapter.requests.last.headers['If-Modified-Since'], lastModified);
    time = time.add(const Duration(minutes: 50));
    expect(await store.loadTile(url), orderedEquals(png));
    expect(adapter.requests, hasLength(2));
  });

  test('Expires is respected instead of the fallback cache duration', () async {
    final adapter = _TileAdapter((_) => tile(headers: {
          'expires': [HttpDate.format(time.add(const Duration(minutes: 30)))],
        }));
    final store = createStore(adapter);
    await store.loadTile(url);
    time = time.add(const Duration(minutes: 31));
    await store.loadTile(url);
    expect(adapter.requests, hasLength(2));
  });

  test('an already aged Expires response retains only its remaining freshness',
      () async {
    final responseDate = time;
    final adapter = _TileAdapter((_) => tile(headers: {
          'date': [HttpDate.format(responseDate)],
          'expires': [
            HttpDate.format(responseDate.add(const Duration(hours: 1)))
          ],
          'age': ['3500'],
        }));
    final store = createStore(adapter);
    await store.loadTile(url);
    time = time.add(const Duration(seconds: 101));
    await store.loadTile(url);
    expect(adapter.requests, hasLength(2));
  });

  test('network failure reuses a previous tile without making it fresh',
      () async {
    final adapter = _TileAdapter((request) {
      if (request.headers.containsKey('If-None-Match')) {
        throw DioException(
            requestOptions: request,
            type: DioExceptionType.connectionError,
            error: const SocketException('Simulated disconnected device'));
      }
      return tile(headers: {
        'cache-control': ['max-age=60'],
        'etag': ['"old-viewed-tile"'],
      });
    });
    final store = createStore(adapter);
    await store.loadTile(url);
    time = time.add(const Duration(minutes: 2));
    expect(await store.loadTile(url), orderedEquals(png));
    expect(await store.loadTile(url), orderedEquals(png));
    expect(adapter.requests, hasLength(3));
  });

  test('must-revalidate prevents serving an expired tile on connection failure',
      () async {
    var failed = false;
    final adapter = _TileAdapter((request) {
      if (failed) {
        throw DioException(
            requestOptions: request, type: DioExceptionType.connectionError);
      }
      return tile(headers: {
        'cache-control': ['max-age=60, must-revalidate'],
      });
    });
    final store = createStore(adapter);
    await store.loadTile(url);
    failed = true;
    time = time.add(const Duration(minutes: 2));
    await expectLater(store.loadTile(url), throwsA(isA<DioException>()));
  });

  test('no-store responses are displayed but never persisted', () async {
    final adapter = _TileAdapter((_) => tile(headers: {
          'cache-control': ['no-store'],
        }));
    final store = createStore(adapter);
    expect(await store.loadTile(url), orderedEquals(png));
    await store.loadTile(url);
    expect(adapter.requests, hasLength(2));
    expect(await directory.list().toList(), isEmpty);
  });

  test('simultaneous consumers share one tile request', () async {
    final response = Completer<ResponseBody>();
    final adapter = _TileAdapter((_) => response.future);
    final store = createStore(adapter);
    final first = store.loadTile(url);
    final second = store.loadTile(url);
    response.complete(tile());
    expect(await first, orderedEquals(png));
    expect(await second, orderedEquals(png));
    expect(adapter.requests, hasLength(1));
  });

  test(
      'bounded pruning retains current bytes and only removes owned tile files',
      () async {
    final unrelated =
        File('${directory.path}${Platform.pathSeparator}keep.txt');
    final unrelatedTile =
        File('${directory.path}${Platform.pathSeparator}unrelated.tile');
    await unrelated.writeAsString('unrelated app data');
    await unrelatedTile.writeAsString('unrelated file');
    final adapter = _TileAdapter((_) => tile());
    final store = createStore(adapter, maxBytes: 350);
    for (var x = 27526; x < 27529; x++) {
      final bytes = await store
          .loadTile('https://tile.openstreetmap.org/15/$x/15492.png');
      expect(bytes, orderedEquals(png));
      await store.flush();
      time = time.add(const Duration(minutes: 1));
    }
    var ownBytes = 0;
    await for (final file in directory.list()) {
      if (file is File && file.uri.pathSegments.last.startsWith('osm_')) {
        ownBytes += await file.length();
      }
    }
    expect(ownBytes, lessThanOrEqualTo(350));
    expect(await unrelated.readAsString(), 'unrelated app data');
    expect(await unrelatedTile.readAsString(), 'unrelated file');
  });

  test(
      'provider selects the viewport URL without starting disk or network work',
      () async {
    final adapter = _TileAdapter((_) => tile());
    final store = createStore(adapter);
    final provider = CachedOsmTileProvider(store: store);
    final options = TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        tileProvider: provider);
    final image =
        provider.getImage(const TileCoordinates(27526, 15492, 15), options);
    expect(image, isNotNull);
    expect(adapter.requests, isEmpty);
    expect(await directory.list().toList(), isEmpty);
    expect(provider.headers['User-Agent'], TileCacheStore.userAgent);
  });
}
