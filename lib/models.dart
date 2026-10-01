class Student {
  String id;
  String name;
  Student({required this.id, required this.name});
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Student.fromJson(Map<String, dynamic> json) => Student(id: json['id'], name: json['name']);
}

class ReadingRecord {
  String studentId;
  String startSurah;
  int? startAyah;
  String endSurah;
  int? endAyah;
  ReadingRecord({required this.studentId, required this.startSurah, this.startAyah, required this.endSurah, this.endAyah});
  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'startSurah': startSurah,
    'startAyah': startAyah,
    'endSurah': endSurah,
    'endAyah': endAyah,
  };
  factory ReadingRecord.fromJson(Map<String, dynamic> json) => ReadingRecord(
    studentId: json['studentId'],
    startSurah: json['startSurah'] ?? '',
    startAyah: json['startAyah'],
    endSurah: json['endSurah'] ?? '',
    endAyah: json['endAyah'],
  );
}

class DailySession {
  String id;
  String dateString;
  List<ReadingRecord> records;
  DailySession({required this.id, required this.dateString, required this.records});
  Map<String, dynamic> toJson() => {
    'id': id,
    'dateString': dateString,
    'records': records.map((e) => e.toJson()).toList(),
  };
  factory DailySession.fromJson(Map<String, dynamic> json) => DailySession(
    id: json['id'],
    dateString: json['dateString'],
    records: (json['records'] as List?)?.map((e) => ReadingRecord.fromJson(e)).toList() ?? [],
  );
}

class Group {
  String id;
  String name;
  List<Student> students;
  List<DailySession> sessions;
  Group({required this.id, required this.name, required this.students, required this.sessions});
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'students': students.map((e) => e.toJson()).toList(),
    'sessions': sessions.map((e) => e.toJson()).toList(),
  };
  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['id'],
    name: json['name'],
    students: (json['students'] as List?)?.map((e) => Student.fromJson(e)).toList() ?? [],
    sessions: (json['sessions'] as List?)?.map((e) => DailySession.fromJson(e)).toList() ?? [],
  );
}
