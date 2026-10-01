class QuranTable {
  String id;
  String title;
  List<QuranRecord> records;

  QuranTable({required this.id, required this.title, required this.records});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'records': records.map((e) => e.toJson()).toList(),
      };

  factory QuranTable.fromJson(Map<String, dynamic> json) => QuranTable(
        id: json['id'],
        title: json['title'],
        records: (json['records'] as List).map((e) => QuranRecord.fromJson(e)).toList(),
      );
}

class QuranRecord {
  String id;
  String name;
  String startSurah;
  String startAyah;
  String endSurah;
  String endAyah;

  QuranRecord({
    required this.id,
    required this.name,
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startSurah': startSurah,
        'startAyah': startAyah,
        'endSurah': endSurah,
        'endAyah': endAyah,
      };

  factory QuranRecord.fromJson(Map<String, dynamic> json) => QuranRecord(
        id: json['id'],
        name: json['name'],
        startSurah: json['startSurah'],
        startAyah: json['startAyah'],
        endSurah: json['endSurah'],
        endAyah: json['endAyah'],
      );
}
