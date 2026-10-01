import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';

// --- MOCK FIRESTORE CLASSES ---
class Timestamp implements Comparable<Timestamp> {
  final int seconds;
  final int nanoseconds;
  Timestamp(this.seconds, this.nanoseconds);
  factory Timestamp.fromDate(DateTime date) {
    return Timestamp(date.millisecondsSinceEpoch ~/ 1000, 0);
  }
  factory Timestamp.now() => Timestamp.fromDate(DateTime.now());
  DateTime toDate() => DateTime.fromMillisecondsSinceEpoch(seconds * 1000);

  @override
  int compareTo(Timestamp other) {
    if (seconds == other.seconds) {
      return nanoseconds.compareTo(other.nanoseconds);
    }
    return seconds.compareTo(other.seconds);
  }
}

class FieldValue {
  static FieldValue serverTimestamp() => FieldValue();
  static FieldValue delete() => FieldValue();
}

class DocumentReference {
  final String id;
  DocumentReference(this.id);
  Future<void> update(Map<String, dynamic> data) async {}
  Future<void> delete() async {}
}

class QueryDocumentSnapshot {
  final String id;
  final Map<String, dynamic> _data;
  QueryDocumentSnapshot(this.id, this._data);
  Map<String, dynamic> data() => _data;
  DocumentReference get reference => DocumentReference(id);
}

class QuerySnapshot {
  final List<QueryDocumentSnapshot> docs;
  QuerySnapshot(this.docs);
}
// --- END MOCK CLASSES ---

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal() {
    _initStreams();
  }

  static const String _studentsKey = 'local_students';
  static const String _logsKey = 'local_daily_logs';
  static const String _trackingStudentsKey = 'local_tracking_students';
  static const String _trackingAttendanceKey = 'local_tracking_attendance';

  final _studentsController = StreamController<QuerySnapshot>.broadcast();
  final _logsController = StreamController<QuerySnapshot>.broadcast();
  final _trackingStudentsController = StreamController<QuerySnapshot>.broadcast();
  final _trackingAttendanceController = StreamController<QuerySnapshot>.broadcast();

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(key);
    if (data == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(list));
    _notifyStreams();
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> _initStreams() async {
    _notifyStreams();
  }

  Future<void> _notifyStreams() async {
    final students = await _readList(_studentsKey);
    final logs = await _readList(_logsKey);
    final trackingStudents = await _readList(_trackingStudentsKey);
    final trackingAttendance = await _readList(_trackingAttendanceKey);

    _studentsController.add(_mapToQuerySnapshot(students));
    _logsController.add(_mapToQuerySnapshot(logs));
    _trackingStudentsController.add(_mapToQuerySnapshot(trackingStudents));
    _trackingAttendanceController.add(_mapToQuerySnapshot(trackingAttendance));
  }

  QuerySnapshot _mapToQuerySnapshot(List<Map<String, dynamic>> list) {
    List<QueryDocumentSnapshot> docs = list.map((item) {
      Map<String, dynamic> data = Map<String, dynamic>.from(item);
      String id = data['id'] ?? _generateId();
      if (data.containsKey('date_millis')) {
        data['date'] = Timestamp(data['date_millis'] ~/ 1000, 0);
      }
      if (data.containsKey('created_at_millis')) {
        data['created_at'] = Timestamp(data['created_at_millis'] ~/ 1000, 0);
      }
      return QueryDocumentSnapshot(id, data);
    }).toList();
    return QuerySnapshot(docs);
  }

  // ==================== ÖĞRENCİ İŞLEMLERİ ====================

  Future<void> addStudent(String name, String parentCode) async {
    List<Map<String, dynamic>> students = await _readList(_studentsKey);
    if (students.any((s) => s['parent_code'] == parentCode)) {
      throw Exception('Bu veli kodu zaten kullanılıyor');
    }
    students.add({
      'id': _generateId(),
      'name': name.trim(),
      'parent_code': parentCode.trim(),
      'last_attended': false,
      'last_lesson': '',
      'on_leave': false,
      'created_at_millis': DateTime.now().millisecondsSinceEpoch,
    });
    await _writeList(_studentsKey, students);
  }

  Future<void> updateStudent(String studentId, {required String name, required String parentCode}) async {
    List<Map<String, dynamic>> students = await _readList(_studentsKey);
    if (students.any((s) => s['parent_code'] == parentCode && s['id'] != studentId)) {
      throw Exception('Bu veli kodu başka bir öğrencide kullanılıyor');
    }
    final index = students.indexWhere((s) => s['id'] == studentId);
    if (index != -1) {
      students[index]['name'] = name.trim();
      students[index]['parent_code'] = parentCode.trim();
      await _writeList(_studentsKey, students);
    }
  }

  Future<void> deleteStudent(String studentId) async {
    List<Map<String, dynamic>> students = await _readList(_studentsKey);
    List<Map<String, dynamic>> logs = await _readList(_logsKey);
    
    students.removeWhere((s) => s['id'] == studentId);
    logs.removeWhere((l) => l['student_id'] == studentId);
    
    await _writeList(_studentsKey, students);
    await _writeList(_logsKey, logs);
  }

  Stream<QuerySnapshot> getStudents() {
    _notifyStreams();
    return _studentsController.stream.map((snapshot) {
      final sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          final timeA = a.data()['created_at_millis'] as int? ?? 0;
          final timeB = b.data()['created_at_millis'] as int? ?? 0;
          return timeB.compareTo(timeA);
        });
      return QuerySnapshot(sortedDocs);
    });
  }

  Future<void> setStudentLeaveStatus(String studentId, bool onLeave) async {
    List<Map<String, dynamic>> students = await _readList(_studentsKey);
    final index = students.indexWhere((s) => s['id'] == studentId);
    if (index != -1) {
      students[index]['on_leave'] = onLeave;
      await _writeList(_studentsKey, students);
    }
  }

  Future<void> updateStudentsSortOrder(List<String> studentIds) async {
    List<Map<String, dynamic>> students = await _readList(_studentsKey);
    for (int i = 0; i < studentIds.length; i++) {
      final index = students.indexWhere((s) => s['id'] == studentIds[i]);
      if (index != -1) {
        students[index]['sort_order'] = i;
      }
    }
    await _writeList(_studentsKey, students);
  }

  Future<QuerySnapshot> getAllStudents() async {
    final students = await _readList(_studentsKey);
    return _mapToQuerySnapshot(students);
  }

  Future<QuerySnapshot> loginStudent(String code) async {
    final students = await _readList(_studentsKey);
    final matched = students.where((s) => s['parent_code'] == code.trim()).toList();
    return _mapToQuerySnapshot(matched);
  }

  // ==================== DERS KAYDI İŞLEMLERİ ====================

  Future<void> _syncStudentLatestLog(String studentId) async {
    List<Map<String, dynamic>> logs = await _readList(_logsKey);
    List<Map<String, dynamic>> students = await _readList(_studentsKey);
    
    final studentLogs = logs.where((l) => l['student_id'] == studentId).toList()
      ..sort((a, b) => (b['date_string'] as String).compareTo(a['date_string'] as String));
      
    final index = students.indexWhere((s) => s['id'] == studentId);
    if (index != -1) {
      if (studentLogs.isNotEmpty) {
        final latest = studentLogs.first;
        final attended = latest['attended'] ?? false;
        final lesson = latest['lesson'] ?? '';
        students[index]['last_attended'] = attended;
        students[index]['last_attended_date'] = latest['date_string'];
        students[index]['last_lesson'] = lesson.isNotEmpty ? lesson : (attended ? 'ئۆتكۈزدى' : 'ئۆتكۈزمىدى');
        students[index]['last_is_takrar'] = latest['is_takrar'] ?? false;
        students[index]['last_is_teravih'] = latest['is_teravih'] ?? false;
      } else {
        students[index]['last_attended'] = false;
        students[index]['last_attended_date'] = null;
        students[index]['last_lesson'] = '';
        students[index]['last_is_takrar'] = false;
        students[index]['last_is_teravih'] = false;
      }
      await _writeList(_studentsKey, students);
    }
  }

  Future<void> addDailyLog(
    String studentId,
    bool attended,
    String lesson,
    String homework, {
    DateTime? customDate,
    int? pageCount,
    int? juzCount,
    int? lineCount,
    bool isTakrar = false,
    bool isTeravih = false,
  }) async {
    DateTime targetDate = customDate ?? DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(targetDate);
    
    List<Map<String, dynamic>> logs = await _readList(_logsKey);
    final index = logs.indexWhere((l) => l['student_id'] == studentId && l['date_string'] == formattedDate);
    
    Map<String, dynamic> logData = {
      'student_id': studentId,
      'attended': attended,
      'lesson': lesson,
      'homework': homework,
      'date_millis': targetDate.millisecondsSinceEpoch,
      'date_string': formattedDate,
      'page_count': pageCount ?? 0,
      'juz_count': juzCount ?? 0,
      'line_count': lineCount ?? 0,
      'is_takrar': isTakrar,
      'is_teravih': isTeravih,
    };

    if (index != -1) {
      logData['id'] = logs[index]['id'];
      logs[index] = logData;
    } else {
      logData['id'] = _generateId();
      logs.add(logData);
    }
    
    await _writeList(_logsKey, logs);
    
    final String todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (formattedDate == todayString || formattedDate.compareTo(todayString) > 0) {
      List<Map<String, dynamic>> students = await _readList(_studentsKey);
      final sIndex = students.indexWhere((s) => s['id'] == studentId);
      if (sIndex != -1) {
        students[sIndex]['last_attended'] = attended;
        students[sIndex]['last_attended_date'] = formattedDate;
        students[sIndex]['last_lesson'] = lesson.isNotEmpty ? lesson : (attended ? 'ئۆتكۈزدى' : 'ئۆتكۈزمىدى');
        students[sIndex]['last_is_takrar'] = isTakrar;
        students[sIndex]['last_is_teravih'] = isTeravih;
        await _writeList(_studentsKey, students);
      }
    } else {
      await _syncStudentLatestLog(studentId);
    }
  }

  Future<void> updateDailyLog(
    String logId, {
    required bool attended,
    required String lesson,
    required String homework,
    DateTime? customDate,
    bool isTakrar = false,
    bool isTeravih = false,
  }) async {
    List<Map<String, dynamic>> logs = await _readList(_logsKey);
    final index = logs.indexWhere((l) => l['id'] == logId);
    if (index != -1) {
      logs[index]['attended'] = attended;
      logs[index]['lesson'] = lesson;
      logs[index]['homework'] = homework;
      logs[index]['is_takrar'] = isTakrar;
      logs[index]['is_teravih'] = isTeravih;
      
      if (customDate != null) {
        logs[index]['date_millis'] = customDate.millisecondsSinceEpoch;
        logs[index]['date_string'] = DateFormat('yyyy-MM-dd').format(customDate);
      }
      
      await _writeList(_logsKey, logs);
      await _syncStudentLatestLog(logs[index]['student_id']);
    }
  }

  Future<void> deleteDailyLog(String logId) async {
    List<Map<String, dynamic>> logs = await _readList(_logsKey);
    final index = logs.indexWhere((l) => l['id'] == logId);
    if (index != -1) {
      final studentId = logs[index]['student_id'];
      logs.removeAt(index);
      await _writeList(_logsKey, logs);
      await _syncStudentLatestLog(studentId);
    }
  }

  Stream<QuerySnapshot> getStudentHistory(String studentId) {
    _notifyStreams();
    return _logsController.stream.map((snapshot) {
      final filtered = snapshot.docs.where((d) => d.data()['student_id'] == studentId).toList();
      return QuerySnapshot(filtered);
    });
  }

  Stream<QuerySnapshot> getStudentLogs(String studentId) => getStudentHistory(studentId);

  Future<QuerySnapshot> getLogsByDateRange(DateTime startDate, DateTime endDate) async {
    final logs = await _readList(_logsKey);
    final startMillis = startDate.millisecondsSinceEpoch;
    final endMillis = endDate.millisecondsSinceEpoch;
    
    final filtered = logs.where((l) {
      final m = l['date_millis'] as int? ?? 0;
      return m >= startMillis && m <= endMillis;
    }).toList();
    
    return _mapToQuerySnapshot(filtered);
  }

  Future<QuerySnapshot> getAllLogs() async {
    final logs = await _readList(_logsKey);
    return _mapToQuerySnapshot(logs);
  }

  // ==================== YOKLAMA TAKİP İŞLEMLERİ ====================

  Future<void> addTrackingStudent(String name, String type, {String arrivalTime = ''}) async {
    List<Map<String, dynamic>> students = await _readList(_trackingStudentsKey);
    students.add({
      'id': _generateId(),
      'name': name.trim(),
      'type': type,
      'arrival_time': arrivalTime.trim(),
      'created_at_millis': DateTime.now().millisecondsSinceEpoch,
    });
    await _writeList(_trackingStudentsKey, students);
  }

  Stream<QuerySnapshot> getTrackingStudents() {
    _notifyStreams();
    return _trackingStudentsController.stream.map((snapshot) {
      final sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          final timeA = a.data()['created_at_millis'] as int? ?? 0;
          final timeB = b.data()['created_at_millis'] as int? ?? 0;
          return timeA.compareTo(timeB); // ascending
        });
      return QuerySnapshot(sortedDocs);
    });
  }

  Future<void> deleteTrackingStudent(String studentId) async {
    List<Map<String, dynamic>> students = await _readList(_trackingStudentsKey);
    List<Map<String, dynamic>> attendance = await _readList(_trackingAttendanceKey);
    
    students.removeWhere((s) => s['id'] == studentId);
    attendance.removeWhere((a) => a['student_id'] == studentId);
    
    await _writeList(_trackingStudentsKey, students);
    await _writeList(_trackingAttendanceKey, attendance);
  }

  Future<void> updateTrackingStudent(String studentId, String name, String type, {String arrivalTime = ''}) async {
    List<Map<String, dynamic>> students = await _readList(_trackingStudentsKey);
    final index = students.indexWhere((s) => s['id'] == studentId);
    if (index != -1) {
      students[index]['name'] = name.trim();
      students[index]['type'] = type;
      students[index]['arrival_time'] = arrivalTime.trim();
      await _writeList(_trackingStudentsKey, students);
    }
  }

  Future<void> updateTrackingAttendance(String studentId, String yearMonth, int day, String? status) async {
    List<Map<String, dynamic>> attendance = await _readList(_trackingAttendanceKey);
    final docId = '${studentId}_$yearMonth';
    final index = attendance.indexWhere((a) => a['id'] == docId);
    
    if (index == -1) {
      if (status != null) {
        attendance.add({
          'id': docId,
          'student_id': studentId,
          'year_month': yearMonth,
          'days': {day.toString(): status}
        });
      }
    } else {
      Map<String, dynamic> days = Map<String, dynamic>.from(attendance[index]['days'] ?? {});
      if (status == null) {
        days.remove(day.toString());
      } else {
        days[day.toString()] = status;
      }
      attendance[index]['days'] = days;
    }
    
    await _writeList(_trackingAttendanceKey, attendance);
  }

  Stream<QuerySnapshot> getTrackingAttendance(String yearMonth) {
    _notifyStreams();
    return _trackingAttendanceController.stream.map((snapshot) {
      final filtered = snapshot.docs.where((d) => d.data()['year_month'] == yearMonth).toList();
      return QuerySnapshot(filtered);
    });
  }
}
