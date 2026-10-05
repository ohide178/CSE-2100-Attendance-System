import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for Flutter Web / Desktop
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  static Future<List<dynamic>> fetchCourses() async {
    final res = await http.get(Uri.parse('$baseUrl/courses'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load courses');
  }

  static Future<List<dynamic>> fetchAttendance(String courseCode, String date) async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance?course_code=${Uri.encodeComponent(courseCode)}&date=$date'),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load attendance');
  }

  static Future<bool> saveAttendance(String courseCode, String date, List<Map<String, dynamic>> records) async {
    final res = await http.post(
      Uri.parse('$baseUrl/attendance'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'course_code': courseCode,
        'date': date,
        'records': records,
      }),
    );
    return res.statusCode == 200;
  }

  static Future<List<dynamic>> fetchStudentSummary(String roll) async {
    final res = await http.get(Uri.parse('$baseUrl/student/$roll/summary'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to fetch student summary');
  }

  static Future<List<dynamic>> fetchCourseReport(String courseCode) async {
    final res = await http.get(Uri.parse('$baseUrl/course/${Uri.encodeComponent(courseCode)}/report'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to fetch course report');
  }
}