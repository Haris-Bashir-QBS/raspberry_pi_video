import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio();
  final Logger _logger = Logger();
  final String _baseUrl = 'http://192.168.81.70:5000';

  Future<Response> start() => _call('start', method: 'GET');
  Future<Response> stop() => _call('stop', method: 'GET');

  Future<Map<String, dynamic>> fetchVideoList() async {
    final url = '$_baseUrl/list';
    _logger.i('Fetching video list from: $url');
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['videos'] is List) {
        return {
          'videos': List<String>.from(response.data['videos']),
          'count': response.data['count'] ?? 0,
        };
      } else {
        throw Exception('Failed to fetch video list');
      }
    } catch (e, stack) {
      _logger.e(
        'Error fetching video list from $url',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<String> downloadVideo(String fileName) async {
    final nameWithoutExtension =
        fileName.contains('.')
            ? fileName.substring(0, fileName.lastIndexOf('.'))
            : fileName;
    final url = '$_baseUrl/download/$nameWithoutExtension';
    _logger.i('Sending GET request to: $url');
    try {
      Directory? dir = await getDownloadsDirectory();
      dir ??= await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      await _dio.download(url, filePath);
      _logger.i('File downloaded to: $filePath');
      return filePath;
    } catch (e, stack) {
      _logger.e(
        'Error downloading file from $url',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<Response> _call(String endpoint, {String method = 'GET'}) async {
    final url = '$_baseUrl/$endpoint';
    _logger.i('Sending $method request to: $url');
    try {
      late Response response;
      if (method == 'GET') {
        response = await _dio.get(url);
      } else if (method == 'POST') {
        response = await _dio.post(url);
      } else {
        throw UnsupportedError('HTTP method $method not supported');
      }
      _logger.i(
        'Response from $endpoint: \\${response.statusCode} \\${response.data}',
      );
      return response;
    } catch (e, stack) {
      _logger.e('Error calling $method $url', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
