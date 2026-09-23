import 'package:dio/dio.dart';
import '../security/token_manager.dart';

class DioClient {
  static const String defaultBaseUrl = 'https://backend-tu3k.onrender.com/api/v1';

  static final DioClient instance = DioClient();

  late final Dio dio;

  DioClient({String baseUrl = defaultBaseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenManager.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            await TokenManager.clearTokens();
          }
          return handler.next(error);
        },
      ),
    );
  }
}