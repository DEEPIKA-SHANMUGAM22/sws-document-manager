import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/document.dart';
import '../models/notification.dart';

class ApiService {
  // Use your PC's local IP for physical device, or 10.0.2.2 for Android emulator
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  static const String wsUrl = 'ws://10.0.2.2:8000/ws/notifications';

  final Dio _dio = Dio();

  Future<Map<String, dynamic>> uploadFiles(List<File> files) async {
    FormData formData = FormData();
    for (var file in files) {
      formData.files.add(
        MapEntry(
          'files',
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ),
      );
    }
    final response = await _dio.post('$baseUrl/upload', data: formData);
    return response.data;
  }

  Future<List<Document>> getDocuments() async {
    final response = await _dio.get('$baseUrl/documents');
    return (response.data as List).map((d) => Document.fromJson(d)).toList();
  }

  Future<void> deleteDocument(int id) async {
    await _dio.delete('$baseUrl/documents/$id');
  }

  Future<List<AppNotification>> getNotifications() async {
    final response = await _dio.get('$baseUrl/notifications');
    return (response.data as List)
        .map((n) => AppNotification.fromJson(n))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get('$baseUrl/notifications/unread-count');
    return response.data['count'];
  }

  Future<void> markRead(int id) async {
    await _dio.patch('$baseUrl/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.patch('$baseUrl/notifications/read-all');
  }
}
