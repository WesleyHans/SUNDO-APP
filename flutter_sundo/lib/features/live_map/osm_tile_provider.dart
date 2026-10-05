import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';

/// Stores only tiles requested by the visible map, never a city or zoom archive.
class CachedOsmTileProvider extends TileProvider {
  CachedOsmTileProvider({TileCacheStore? store})
      : store = store ?? TileCacheStore(),
        super(headers: {'User-Agent': TileCacheStore.userAgent});

  final TileCacheStore store;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _CachedTileImage(getTileUrl(coordinates, options), store);

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }
}

/// Native disk cache for OSM raster tiles. The OS may reclaim this directory.
///
/// Freshness follows Cache-Control/Expires; missing freshness headers use seven
/// days. Expired entries are conditionally validated, and a failed connection
/// can use the already viewed tile unless the server requires revalidation.
/// This cache is independent of truck GPS timestamps and collection updates.
class TileCacheStore {
  TileCacheStore({
    Directory? directory,
    Dio? dio,
    DateTime Function()? now,
    this.maxBytes = 128 * 1024 * 1024,
  })  : assert(maxBytes > 0),
        _providedDirectory = directory,
        _dio = dio ??
            Dio(BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 12))),
        _ownsDio = dio == null,
        _now = now ?? DateTime.now;

  static const userAgent =
      'SUNDO/1.2.1 (+https://github.com/wesleyhansplatil123/SUNDO-APP)';
  static const _fallbackLifetime = Duration(days: 7);
  static const _maxTileBytes = 2 * 1024 * 1024;
  static final _cacheName = RegExp(r'^osm_[A-Za-z0-9_-]+\.tile$');
  static const _pngHeader = [137, 80, 78, 71, 13, 10, 26, 10];

  final int maxBytes;
  final Directory? _providedDirectory;
  final Dio _dio;
  final bool _ownsDio;
  final DateTime Function() _now;
  final Map<String, Future<Uint8List>> _inFlight = {};
  Future<Directory>? _directoryFuture;
  Future<void> _diskQueue = Future.value();
  DateTime? _lastCleanup;
  int? _diskBytes;
  int _imageVersion = 0;
  bool _disposed = false;

  Future<_CachedTileImageKey> _imageKey(String url) async {
    // Resolve HTTP freshness before consulting Flutter's decoded ImageCache.
    // Otherwise an expired/no-cache tile could be reused entirely in memory.
    final bytes = await loadTile(url);
    Object version = ++_imageVersion;
    final key = 'osm_${base64Url.encode(utf8.encode(url)).replaceAll('=', '')}';
    try {
      await _disk(() async {
        final directory = await _directory();
        final metadata =
            File('${directory.path}${Platform.pathSeparator}$key.tile.json');
        if (!await metadata.exists()) return;
        final decoded = jsonDecode(await metadata.readAsString());
        if (decoded is! Map<String, dynamic> || decoded['url'] != url) return;
        final expires = DateTime.tryParse(decoded['expires'] as String? ?? '');
        if (expires != null && _now().toUtc().isBefore(expires)) {
          version = decoded['expires'] as String;
        }
      });
    } on FileSystemException {
      // A response which cannot be persisted receives a unique decoded key.
    } on FormatException {
      // A damaged metadata entry must never bypass the HTTP cache policy.
    } on TypeError {
      // Treat malformed persisted metadata as an uncached response.
    }
    return _CachedTileImageKey(url, this, version, bytes);
  }

  /// Requests one viewport tile, coalescing concurrent requests for that URL.
  Future<Uint8List> loadTile(String url) {
    if (_disposed) return Future.error(StateError('Tile cache is disposed'));
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'tile.openstreetmap.org' ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty ||
        uri.path.length < 2 ||
        !RegExp(r'^\d{1,2}/\d{1,10}/\d{1,10}\.png$')
            .hasMatch(uri.path.substring(1))) {
      return Future.error(ArgumentError('Expected an HTTPS OSM raster tile'));
    }
    final key = 'osm_${base64Url.encode(utf8.encode(url)).replaceAll('=', '')}';
    return _inFlight.putIfAbsent(key, () async {
      try {
        return await _load(url, key);
      } finally {
        _inFlight.remove(key);
        // An oversized cache can briefly retain tiles still being read. Once
        // the last request completes they become eligible for bounded pruning.
        if ((_diskBytes ?? 0) > maxBytes) {
          unawaited(
              _disk(() => _cleanup(force: true)).catchError((Object _) {}));
        }
      }
    });
  }

  Future<Directory> _directory() => _directoryFuture ??= (() async {
        final directory = _providedDirectory ??
            Directory(
                '${(await getApplicationCacheDirectory()).path}${Platform.pathSeparator}sundo_osm_tiles_v1');
        return directory.create(recursive: true);
      })();

  Future<T> _disk<T>(Future<T> Function() operation) {
    final result = _diskQueue.then((_) => operation());
    _diskQueue =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<Uint8List> _load(String url, String key) async {
    _StoredTile? previous;
    try {
      previous = await _disk(() => _read(url, key));
    } on FileSystemException {
      // A full or reclaimed OS cache must not prevent ordinary map viewing.
    }
    final now = _now().toUtc();
    if (previous != null && now.isBefore(previous.expires)) {
      return previous.bytes;
    }
    final requestHeaders = <String, String>{'User-Agent': userAgent};
    if (previous?.headers['etag'] case final String etag) {
      requestHeaders['If-None-Match'] = etag;
    }
    if (previous?.headers['last-modified'] case final String lastModified) {
      requestHeaders['If-Modified-Since'] = lastModified;
    }
    try {
      final response = await _dio.get<List<int>>(url,
          options: Options(
              responseType: ResponseType.bytes,
              headers: requestHeaders,
              validateStatus: (status) => status == 200 || status == 304));
      final responseHeaders = <String, String>{
        for (final entry in response.headers.map.entries)
          entry.key.toLowerCase(): entry.value.join(', '),
      };
      late final Uint8List bytes;
      if (response.statusCode == 304) {
        if (previous == null) {
          throw StateError('Received a tile validation without cached bytes');
        }
        bytes = previous.bytes;
        final originalHeaders = {...previous.headers}
          ..remove('date')
          ..remove('age');
        responseHeaders.addAll({
          ...originalHeaders,
          ...responseHeaders,
        });
      } else {
        bytes = Uint8List.fromList(response.data ?? []);
        if (!_validPng(bytes)) {
          throw const FormatException('The tile response is not a PNG image');
        }
      }
      try {
        await _disk(() => _save(url, key, bytes, responseHeaders));
      } on FileSystemException {
        // Display a valid response even when persistence is unavailable.
      }
      return bytes;
    } catch (error) {
      final status = error is DioException ? error.response?.statusCode : null;
      if (previous != null &&
          !previous.requiresValidation &&
          !(status != null && status >= 400 && status < 500)) {
        // Do not advance expiry or imply that old map tiles are newly fetched.
        return previous.bytes;
      }
      rethrow;
    }
  }

  bool _validPng(Uint8List bytes) =>
      bytes.length >= _pngHeader.length &&
      bytes.length <= _maxTileBytes &&
      listEquals(bytes.sublist(0, _pngHeader.length), _pngHeader);

  Future<_StoredTile?> _read(String url, String key) async {
    final directory = await _directory();
    final tile = File('${directory.path}${Platform.pathSeparator}$key.tile');
    final metadata = File('${tile.path}.json');
    if (!await tile.exists() || !await metadata.exists()) return null;
    try {
      final decoded = jsonDecode(await metadata.readAsString());
      if (decoded is! Map<String, dynamic> || decoded['url'] != url) {
        return null;
      }
      final bytes = await tile.readAsBytes();
      if (!_validPng(bytes)) return null;
      final expires = DateTime.tryParse(decoded['expires'] as String? ?? '');
      if (expires == null || decoded['headers'] is! Map) return null;
      final headers = Map<String, String>.from(decoded['headers'] as Map);
      final accessed = await tile.lastModified();
      if (_now().difference(accessed) > const Duration(minutes: 10)) {
        await tile.setLastModified(_now());
      }
      return _StoredTile(bytes, expires, headers);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> _save(String url, String key, Uint8List bytes,
      Map<String, String> headers) async {
    final directory = await _directory();
    final tile = File('${directory.path}${Platform.pathSeparator}$key.tile');
    final metadata = File('${tile.path}.json');
    final control = headers['cache-control']?.toLowerCase() ?? '';
    if (RegExp(r'(^|,)\s*no-store\s*(,|$)').hasMatch(control)) {
      await _removeEntry(tile, metadata);
      return;
    }
    final oldLength = (await tile.exists() ? await tile.length() : 0) +
        (await metadata.exists() ? await metadata.length() : 0);
    final metadataBytes = utf8.encode(jsonEncode({
      'url': url,
      'expires': _expires(headers).toIso8601String(),
      'headers': {
        for (final name in [
          'cache-control',
          'expires',
          'date',
          'age',
          'etag',
          'last-modified',
        ])
          if (headers[name] != null) name: headers[name],
      },
    }));
    await _replaceFile(tile, bytes);
    await _replaceFile(metadata, metadataBytes);
    if (_diskBytes != null) {
      _diskBytes =
          _diskBytes! + bytes.length + metadataBytes.length - oldLength;
    }
    await _cleanup(force: (_diskBytes ?? 0) > maxBytes);
  }

  DateTime _expires(Map<String, String> headers) {
    final now = _now().toUtc();
    final control = headers['cache-control']?.toLowerCase() ?? '';
    if (RegExp(r'(^|,)\s*no-cache\b').hasMatch(control)) return now;
    final maxAge = RegExp(r'(^|,)\s*max-age\s*=\s*"?(\d+)').firstMatch(control);
    if (maxAge != null) {
      final serverDate = _httpDate(headers['date']);
      final apparentAge = serverDate == null
          ? 0
          : now.difference(serverDate).inSeconds.clamp(0, 1 << 31);
      final age = int.tryParse(headers['age'] ?? '') ?? 0;
      final elapsed = age > apparentAge ? age : apparentAge;
      final remaining = int.parse(maxAge.group(2)!) - elapsed;
      return now.add(Duration(seconds: remaining.clamp(0, 1 << 31)));
    }
    final expires = _httpDate(headers['expires']);
    if (expires != null) {
      final serverDate = _httpDate(headers['date']) ?? now;
      final apparentAge =
          now.difference(serverDate).inSeconds.clamp(0, 1 << 31);
      final age = int.tryParse(headers['age'] ?? '') ?? 0;
      final elapsed = age > apparentAge ? age : apparentAge;
      return now.add(Duration(
          seconds: (expires.difference(serverDate).inSeconds - elapsed)
              .clamp(0, 1 << 31)));
    }
    return now.add(_fallbackLifetime);
  }

  DateTime? _httpDate(String? value) {
    if (value == null) return null;
    try {
      return HttpDate.parse(value);
    } on FormatException {
      return null;
    }
  }

  Future<void> _replaceFile(File target, List<int> bytes) async {
    final temporary = File('${target.path}.part');
    await temporary.writeAsBytes(bytes);
    await temporary.rename(target.path);
  }

  Future<void> _removeEntry(File tile, File metadata) async {
    for (final file in [tile, metadata]) {
      if (await file.exists()) {
        final length = await file.length();
        await file.delete();
        if (_diskBytes != null) _diskBytes = _diskBytes! - length;
      }
    }
  }

  Future<void> _cleanup({bool force = false}) async {
    final now = _now().toUtc();
    if (!force &&
        _lastCleanup != null &&
        now.difference(_lastCleanup!) < const Duration(hours: 1)) {
      return;
    }
    final directory = await _directory();
    final entries = <_DiskTile>[];
    var total = 0;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!_cacheName.hasMatch(name)) continue;
      final metadata = File('${entity.path}.json');
      final stat = await entity.stat();
      final size =
          stat.size + (await metadata.exists() ? await metadata.length() : 0);
      total += size;
      entries.add(_DiskTile(entity, metadata,
          name.substring(0, name.length - 5), size, stat.modified));
    }
    entries.sort((a, b) => a.accessed.compareTo(b.accessed));
    for (final entry in entries) {
      if (total <= maxBytes) break;
      if (_inFlight.containsKey(entry.key)) continue;
      await _removeEntry(entry.tile, entry.metadata);
      total -= entry.bytes;
    }
    _diskBytes = total;
    _lastCleanup = now;
  }

  /// Waits for disk maintenance; useful before a deterministic cache test ends.
  Future<void> flush() async {
    await _diskQueue;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_ownsDio) _dio.close(force: true);
  }
}

class _StoredTile {
  _StoredTile(this.bytes, this.expires, this.headers);
  final Uint8List bytes;
  final DateTime expires;
  final Map<String, String> headers;

  bool get requiresValidation => RegExp(r'(^|,)\s*(no-cache|must-revalidate)\b')
      .hasMatch(headers['cache-control']?.toLowerCase() ?? '');
}

class _DiskTile {
  _DiskTile(this.tile, this.metadata, this.key, this.bytes, this.accessed);
  final File tile;
  final File metadata;
  final String key;
  final int bytes;
  final DateTime accessed;
}

@immutable
class _CachedTileImageKey {
  const _CachedTileImageKey(this.url, this.store, this.version, this.bytes);
  final String url;
  final TileCacheStore store;
  final Object version;
  final Uint8List bytes;

  @override
  bool operator ==(Object other) =>
      other is _CachedTileImageKey &&
      other.url == url &&
      identical(other.store, store) &&
      other.version == version;

  @override
  int get hashCode => Object.hash(url, store, version);
}

@immutable
class _CachedTileImage extends ImageProvider<_CachedTileImageKey> {
  const _CachedTileImage(this.url, this.store);
  final String url;
  final TileCacheStore store;

  @override
  Future<_CachedTileImageKey> obtainKey(ImageConfiguration configuration) =>
      store._imageKey(url);

  @override
  ImageStreamCompleter loadImage(
          _CachedTileImageKey key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(
          codec: _decode(key, decode), scale: 1, debugLabel: url);

  Future<ui.Codec> _decode(
      _CachedTileImageKey key, ImageDecoderCallback decode) async {
    try {
      final codec =
          await decode(await ui.ImmutableBuffer.fromUint8List(key.bytes));
      if (key.version is int) {
        // No-store/no-cache and stale responses may remain visible, but must
        // not be retained in the decoded cache after their listeners leave.
        scheduleMicrotask(() =>
            PaintingBinding.instance.imageCache.evict(key, includeLive: false));
      }
      return codec;
    } catch (_) {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      rethrow;
    }
  }
}
