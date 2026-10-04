import 'package:dio/dio.dart';

/// Optional PHP/MySQL adapter: repository transports can use this authenticated
/// client without coupling Flutter screens to a server-specific response shape.
class SundoApiClient {
  final Dio dio;
  SundoApiClient({required String baseUrl, String? bearerToken, Dio? client})
      : dio = client ??
            Dio(BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 20),
                headers: {
                  if (bearerToken != null)
                    'Authorization': 'Bearer $bearerToken'
                }));
  Future<Map<String, dynamic>> getObject(String path) async {
    final result = await dio.get<Map<String, dynamic>>(path);
    if (result.data == null) throw StateError('Empty API response');
    return result.data!;
  }

  void close() => dio.close();
}
