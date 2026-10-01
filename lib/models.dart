class ReadingRecord {
  String id;
  String dateString;
  String startSurah;
  int? startAyah;
  String endSurah;
  int? endAyah;
  
  ReadingRecord({
    required this.id,
    required this.dateString,
    required this.startSurah,
    this.startAyah,
    required this.endSurah,
    this.endAyah,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dateString': dateString,
    'startSurah': startSurah,
    'startAyah': startAyah,
    'endSurah': endSurah,
    'endAyah': endAyah,
  };

  factory ReadingRecord.fromJson(Map<String, dynamic> json) => ReadingRecord(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    dateString: json['dateString'] ?? '',
    startSurah: json['startSurah'] ?? '',
    startAyah: json['startAyah'],
    endSurah: json['endSurah'] ?? '',
    endAyah: json['endAyah'],
  );
}

class Student {
  String id;
  String name;
  List<ReadingRecord> records;

  Student({required this.id, required this.name, required this.records});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'records': records.map((e) => e.toJson()).toList(),
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id'],
    name: json['name'],
    records: (json['records'] as List?)?.map((e) => ReadingRecord.fromJson(e)).toList() ?? [],
  );
}

class Group {
  String id;
  String name;
  List<Student> students;

  Group({required this.id, required this.name, required this.students});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'students': students.map((e) => e.toJson()).toList(),
  };

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['id'],
    name: json['name'],
    students: (json['students'] as List?)?.map((e) => Student.fromJson(e)).toList() ?? [],
  );
}
