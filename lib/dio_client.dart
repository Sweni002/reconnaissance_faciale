import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();

  factory DioClient() => _instance;

  late Dio dio;
  late CookieJar cookieJar;

  DioClient._internal() {
    cookieJar = CookieJar();

    dio = Dio(
      BaseOptions(
        baseUrl:'http://127.0.0.1:5000/api', // adapte ici
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(CookieManager(cookieJar));
  }
}
