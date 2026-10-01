/// Kuran-ı Kerim Sure Bilgileri
/// Her surenin adı, ayet sayısı ve başlangıç cüzü

class SurahInfo {
  final int number;
  final String nameArabic;
  final String nameUyghur;
  final int ayahCount;
  final int startJuz;

  const SurahInfo({
    required this.number,
    required this.nameArabic,
    required this.nameUyghur,
    required this.ayahCount,
    required this.startJuz,
  });
}

class QuranData {
  static const List<SurahInfo> surahs = [
    SurahInfo(
        number: 1,
        nameArabic: "الفاتحة",
        nameUyghur: "فاتىھە",
        ayahCount: 7,
        startJuz: 1),
    SurahInfo(
        number: 2,
        nameArabic: "البقرة",
        nameUyghur: "بەقەرە",
        ayahCount: 286,
        startJuz: 1),
    SurahInfo(
        number: 3,
        nameArabic: "آل عمران",
        nameUyghur: "ئالى ئىمران",
        ayahCount: 200,
        startJuz: 3),
    SurahInfo(
        number: 4,
        nameArabic: "النساء",
        nameUyghur: "نىسا",
        ayahCount: 176,
        startJuz: 4),
    SurahInfo(
        number: 5,
        nameArabic: "المائدة",
        nameUyghur: "مائىدە",
        ayahCount: 120,
        startJuz: 6),
    SurahInfo(
        number: 6,
        nameArabic: "الأنعام",
        nameUyghur: "ئەنئام",
        ayahCount: 165,
        startJuz: 7),
    SurahInfo(
        number: 7,
        nameArabic: "الأعراف",
        nameUyghur: "ئەئراف",
        ayahCount: 206,
        startJuz: 8),
    SurahInfo(
        number: 8,
        nameArabic: "الأنفال",
        nameUyghur: "ئەنفال",
        ayahCount: 75,
        startJuz: 9),
    SurahInfo(
        number: 9,
        nameArabic: "التوبة",
        nameUyghur: "تەۋبە",
        ayahCount: 129,
        startJuz: 10),
    SurahInfo(
        number: 10,
        nameArabic: "يونس",
        nameUyghur: "يۇنۇس",
        ayahCount: 109,
        startJuz: 11),
    SurahInfo(
        number: 11,
        nameArabic: "هود",
        nameUyghur: "ھۇد",
        ayahCount: 123,
        startJuz: 11),
    SurahInfo(
        number: 12,
        nameArabic: "يوسف",
        nameUyghur: "يۈسۈپ",
        ayahCount: 111,
        startJuz: 12),
    SurahInfo(
        number: 13,
        nameArabic: "الرعد",
        nameUyghur: "رەئد",
        ayahCount: 43,
        startJuz: 13),
    SurahInfo(
        number: 14,
        nameArabic: "إبراهيم",
        nameUyghur: "ئىبراھىم",
        ayahCount: 52,
        startJuz: 13),
    SurahInfo(
        number: 15,
        nameArabic: "الحجر",
        nameUyghur: "ھىجر",
        ayahCount: 99,
        startJuz: 14),
    SurahInfo(
        number: 16,
        nameArabic: "النحل",
        nameUyghur: "نەھل",
        ayahCount: 128,
        startJuz: 14),
    SurahInfo(
        number: 17,
        nameArabic: "الإسراء",
        nameUyghur: "ئىسرا",
        ayahCount: 111,
        startJuz: 15),
    SurahInfo(
        number: 18,
        nameArabic: "الكهف",
        nameUyghur: "كەھف",
        ayahCount: 110,
        startJuz: 15),
    SurahInfo(
        number: 19,
        nameArabic: "مريم",
        nameUyghur: "مەريەم",
        ayahCount: 98,
        startJuz: 16),
    SurahInfo(
        number: 20,
        nameArabic: "طه",
        nameUyghur: "تاھا",
        ayahCount: 135,
        startJuz: 16),
    SurahInfo(
        number: 21,
        nameArabic: "الأنبياء",
        nameUyghur: "ئەنبىيا",
        ayahCount: 112,
        startJuz: 17),
    SurahInfo(
        number: 22,
        nameArabic: "الحج",
        nameUyghur: "ھەج",
        ayahCount: 78,
        startJuz: 17),
    SurahInfo(
        number: 23,
        nameArabic: "المؤمنون",
        nameUyghur: "مۆمىنۇن",
        ayahCount: 118,
        startJuz: 18),
    SurahInfo(
        number: 24,
        nameArabic: "النور",
        nameUyghur: "نۇر",
        ayahCount: 64,
        startJuz: 18),
    SurahInfo(
        number: 25,
        nameArabic: "الفرقان",
        nameUyghur: "فۇرقان",
        ayahCount: 77,
        startJuz: 18),
    SurahInfo(
        number: 26,
        nameArabic: "الشعراء",
        nameUyghur: "شۇئەرا",
        ayahCount: 227,
        startJuz: 19),
    SurahInfo(
        number: 27,
        nameArabic: "النمل",
        nameUyghur: "نەمل",
        ayahCount: 93,
        startJuz: 19),
    SurahInfo(
        number: 28,
        nameArabic: "القصص",
        nameUyghur: "قەسەس",
        ayahCount: 88,
        startJuz: 20),
    SurahInfo(
        number: 29,
        nameArabic: "العنكبوت",
        nameUyghur: "ئەنكەبۇت",
        ayahCount: 69,
        startJuz: 20),
    SurahInfo(
        number: 30,
        nameArabic: "الروم",
        nameUyghur: "رۇم",
        ayahCount: 60,
        startJuz: 21),
    SurahInfo(
        number: 31,
        nameArabic: "لقمان",
        nameUyghur: "لۇقمان",
        ayahCount: 34,
        startJuz: 21),
    SurahInfo(
        number: 32,
        nameArabic: "السجدة",
        nameUyghur: "سەجدە",
        ayahCount: 30,
        startJuz: 21),
    SurahInfo(
        number: 33,
        nameArabic: "الأحزاب",
        nameUyghur: "ئەھزاب",
        ayahCount: 73,
        startJuz: 21),
    SurahInfo(
        number: 34,
        nameArabic: "سبأ",
        nameUyghur: "سەبەئ",
        ayahCount: 54,
        startJuz: 22),
    SurahInfo(
        number: 35,
        nameArabic: "فاطر",
        nameUyghur: "فاتىر",
        ayahCount: 45,
        startJuz: 22),
    SurahInfo(
        number: 36,
        nameArabic: "يس",
        nameUyghur: "ياسىن",
        ayahCount: 83,
        startJuz: 22),
    SurahInfo(
        number: 37,
        nameArabic: "الصافات",
        nameUyghur: "سافات",
        ayahCount: 182,
        startJuz: 23),
    SurahInfo(
        number: 38,
        nameArabic: "ص",
        nameUyghur: "ساد",
        ayahCount: 88,
        startJuz: 23),
    SurahInfo(
        number: 39,
        nameArabic: "الزمر",
        nameUyghur: "زۇمەر",
        ayahCount: 75,
        startJuz: 23),
    SurahInfo(
        number: 40,
        nameArabic: "غافر",
        nameUyghur: "غافىر",
        ayahCount: 85,
        startJuz: 24),
    SurahInfo(
        number: 41,
        nameArabic: "فصلت",
        nameUyghur: "فۇسسىلەت",
        ayahCount: 54,
        startJuz: 24),
    SurahInfo(
        number: 42,
        nameArabic: "الشورى",
        nameUyghur: "شۇرا",
        ayahCount: 53,
        startJuz: 25),
    SurahInfo(
        number: 43,
        nameArabic: "الزخرف",
        nameUyghur: "زۇخرۇف",
        ayahCount: 89,
        startJuz: 25),
    SurahInfo(
        number: 44,
        nameArabic: "الدخان",
        nameUyghur: "دۇخان",
        ayahCount: 59,
        startJuz: 25),
    SurahInfo(
        number: 45,
        nameArabic: "الجاثية",
        nameUyghur: "جاسىيە",
        ayahCount: 37,
        startJuz: 25),
    SurahInfo(
        number: 46,
        nameArabic: "الأحقاف",
        nameUyghur: "ئەھقاف",
        ayahCount: 35,
        startJuz: 26),
    SurahInfo(
        number: 47,
        nameArabic: "محمد",
        nameUyghur: "مۇھەممەد",
        ayahCount: 38,
        startJuz: 26),
    SurahInfo(
        number: 48,
        nameArabic: "الفتح",
        nameUyghur: "فەتىھ",
        ayahCount: 29,
        startJuz: 26),
    SurahInfo(
        number: 49,
        nameArabic: "الحجرات",
        nameUyghur: "ھۇجۇرات",
        ayahCount: 18,
        startJuz: 26),
    SurahInfo(
        number: 50,
        nameArabic: "ق",
        nameUyghur: "قاف",
        ayahCount: 45,
        startJuz: 26),
    SurahInfo(
        number: 51,
        nameArabic: "الذاريات",
        nameUyghur: "زارىيات",
        ayahCount: 60,
        startJuz: 26),
    SurahInfo(
        number: 52,
        nameArabic: "الطور",
        nameUyghur: "تۇر",
        ayahCount: 49,
        startJuz: 27),
    SurahInfo(
        number: 53,
        nameArabic: "النجم",
        nameUyghur: "نەجم",
        ayahCount: 62,
        startJuz: 27),
    SurahInfo(
        number: 54,
        nameArabic: "القمر",
        nameUyghur: "قەمەر",
        ayahCount: 55,
        startJuz: 27),
    SurahInfo(
        number: 55,
        nameArabic: "الرحمن",
        nameUyghur: "رەھمان",
        ayahCount: 78,
        startJuz: 27),
    SurahInfo(
        number: 56,
        nameArabic: "الواقعة",
        nameUyghur: "ۋاقىئە",
        ayahCount: 96,
        startJuz: 27),
    SurahInfo(
        number: 57,
        nameArabic: "الحديد",
        nameUyghur: "ھەدىد",
        ayahCount: 29,
        startJuz: 27),
    SurahInfo(
        number: 58,
        nameArabic: "المجادلة",
        nameUyghur: "مۇجادىلە",
        ayahCount: 22,
        startJuz: 28),
    SurahInfo(
        number: 59,
        nameArabic: "الحشر",
        nameUyghur: "ھەشر",
        ayahCount: 24,
        startJuz: 28),
    SurahInfo(
        number: 60,
        nameArabic: "الممتحنة",
        nameUyghur: "مۇمتەھىنە",
        ayahCount: 13,
        startJuz: 28),
    SurahInfo(
        number: 61,
        nameArabic: "الصف",
        nameUyghur: "سەف",
        ayahCount: 14,
        startJuz: 28),
    SurahInfo(
        number: 62,
        nameArabic: "الجمعة",
        nameUyghur: "جۈمئە",
        ayahCount: 11,
        startJuz: 28),
    SurahInfo(
        number: 63,
        nameArabic: "المنافقون",
        nameUyghur: "مۇنافىقۇن",
        ayahCount: 11,
        startJuz: 28),
    SurahInfo(
        number: 64,
        nameArabic: "التغابن",
        nameUyghur: "تەغابۇن",
        ayahCount: 18,
        startJuz: 28),
    SurahInfo(
        number: 65,
        nameArabic: "الطلاق",
        nameUyghur: "تالاق",
        ayahCount: 12,
        startJuz: 28),
    SurahInfo(
        number: 66,
        nameArabic: "التحريم",
        nameUyghur: "تەھرىم",
        ayahCount: 12,
        startJuz: 28),
    SurahInfo(
        number: 67,
        nameArabic: "الملك",
        nameUyghur: "مۈلك",
        ayahCount: 30,
        startJuz: 29),
    SurahInfo(
        number: 68,
        nameArabic: "القلم",
        nameUyghur: "قەلەم",
        ayahCount: 52,
        startJuz: 29),
    SurahInfo(
        number: 69,
        nameArabic: "الحاقة",
        nameUyghur: "ھاققە",
        ayahCount: 52,
        startJuz: 29),
    SurahInfo(
        number: 70,
        nameArabic: "المعارج",
        nameUyghur: "مەئارىج",
        ayahCount: 44,
        startJuz: 29),
    SurahInfo(
        number: 71,
        nameArabic: "نوح",
        nameUyghur: "نۇھ",
        ayahCount: 28,
        startJuz: 29),
    SurahInfo(
        number: 72,
        nameArabic: "الجن",
        nameUyghur: "جىن",
        ayahCount: 28,
        startJuz: 29),
    SurahInfo(
        number: 73,
        nameArabic: "المزمل",
        nameUyghur: "مۇزەممىل",
        ayahCount: 20,
        startJuz: 29),
    SurahInfo(
        number: 74,
        nameArabic: "المدثر",
        nameUyghur: "مۇدەسسىر",
        ayahCount: 56,
        startJuz: 29),
    SurahInfo(
        number: 75,
        nameArabic: "القيامة",
        nameUyghur: "قىيامە",
        ayahCount: 40,
        startJuz: 29),
    SurahInfo(
        number: 76,
        nameArabic: "الإنسان",
        nameUyghur: "ئىنسان",
        ayahCount: 31,
        startJuz: 29),
    SurahInfo(
        number: 77,
        nameArabic: "المرسلات",
        nameUyghur: "مۇرسەلات",
        ayahCount: 50,
        startJuz: 29),
    SurahInfo(
        number: 78,
        nameArabic: "النبأ",
        nameUyghur: "نەبەئ",
        ayahCount: 40,
        startJuz: 30),
    SurahInfo(
        number: 79,
        nameArabic: "النازعات",
        nameUyghur: "نازىئات",
        ayahCount: 46,
        startJuz: 30),
    SurahInfo(
        number: 80,
        nameArabic: "عبس",
        nameUyghur: "ئەبەسە",
        ayahCount: 42,
        startJuz: 30),
    SurahInfo(
        number: 81,
        nameArabic: "التكوير",
        nameUyghur: "تەكۋىر",
        ayahCount: 29,
        startJuz: 30),
    SurahInfo(
        number: 82,
        nameArabic: "الانفطار",
        nameUyghur: "ئىنفىتار",
        ayahCount: 19,
        startJuz: 30),
    SurahInfo(
        number: 83,
        nameArabic: "المطففين",
        nameUyghur: "مۇتەففىفىن",
        ayahCount: 36,
        startJuz: 30),
    SurahInfo(
        number: 84,
        nameArabic: "الانشقاق",
        nameUyghur: "ئىنشىقاق",
        ayahCount: 25,
        startJuz: 30),
    SurahInfo(
        number: 85,
        nameArabic: "البروج",
        nameUyghur: "بۇرۇج",
        ayahCount: 22,
        startJuz: 30),
    SurahInfo(
        number: 86,
        nameArabic: "الطارق",
        nameUyghur: "تارىق",
        ayahCount: 17,
        startJuz: 30),
    SurahInfo(
        number: 87,
        nameArabic: "الأعلى",
        nameUyghur: "ئەئلا",
        ayahCount: 19,
        startJuz: 30),
    SurahInfo(
        number: 88,
        nameArabic: "الغاشية",
        nameUyghur: "غاشىيە",
        ayahCount: 26,
        startJuz: 30),
    SurahInfo(
        number: 89,
        nameArabic: "الفجر",
        nameUyghur: "فەجر",
        ayahCount: 30,
        startJuz: 30),
    SurahInfo(
        number: 90,
        nameArabic: "البلد",
        nameUyghur: "بەلەد",
        ayahCount: 20,
        startJuz: 30),
    SurahInfo(
        number: 91,
        nameArabic: "الشمس",
        nameUyghur: "شەمس",
        ayahCount: 15,
        startJuz: 30),
    SurahInfo(
        number: 92,
        nameArabic: "الليل",
        nameUyghur: "لەيل",
        ayahCount: 21,
        startJuz: 30),
    SurahInfo(
        number: 93,
        nameArabic: "الضحى",
        nameUyghur: "زۇھا",
        ayahCount: 11,
        startJuz: 30),
    SurahInfo(
        number: 94,
        nameArabic: "الشرح",
        nameUyghur: "شەرھ",
        ayahCount: 8,
        startJuz: 30),
    SurahInfo(
        number: 95,
        nameArabic: "التين",
        nameUyghur: "تىن",
        ayahCount: 8,
        startJuz: 30),
    SurahInfo(
        number: 96,
        nameArabic: "العلق",
        nameUyghur: "ئەلەق",
        ayahCount: 19,
        startJuz: 30),
    SurahInfo(
        number: 97,
        nameArabic: "القدر",
        nameUyghur: "قەدر",
        ayahCount: 5,
        startJuz: 30),
    SurahInfo(
        number: 98,
        nameArabic: "البينة",
        nameUyghur: "بەييىنە",
        ayahCount: 8,
        startJuz: 30),
    SurahInfo(
        number: 99,
        nameArabic: "الزلزلة",
        nameUyghur: "زىلزال",
        ayahCount: 8,
        startJuz: 30),
    SurahInfo(
        number: 100,
        nameArabic: "العاديات",
        nameUyghur: "ئادىيات",
        ayahCount: 11,
        startJuz: 30),
    SurahInfo(
        number: 101,
        nameArabic: "القارعة",
        nameUyghur: "قارىئە",
        ayahCount: 11,
        startJuz: 30),
    SurahInfo(
        number: 102,
        nameArabic: "التكاثر",
        nameUyghur: "تەكاسۇر",
        ayahCount: 8,
        startJuz: 30),
    SurahInfo(
        number: 103,
        nameArabic: "العصر",
        nameUyghur: "ئەسر",
        ayahCount: 3,
        startJuz: 30),
    SurahInfo(
        number: 104,
        nameArabic: "الهمزة",
        nameUyghur: "ھۇمەزە",
        ayahCount: 9,
        startJuz: 30),
    SurahInfo(
        number: 105,
        nameArabic: "الفيل",
        nameUyghur: "فىل",
        ayahCount: 5,
        startJuz: 30),
    SurahInfo(
        number: 106,
        nameArabic: "قريش",
        nameUyghur: "قۇرەيش",
        ayahCount: 4,
        startJuz: 30),
    SurahInfo(
        number: 107,
        nameArabic: "الماعون",
        nameUyghur: "مائۇن",
        ayahCount: 7,
        startJuz: 30),
    SurahInfo(
        number: 108,
        nameArabic: "الكوثر",
        nameUyghur: "كەۋسەر",
        ayahCount: 3,
        startJuz: 30),
    SurahInfo(
        number: 109,
        nameArabic: "الكافرون",
        nameUyghur: "كافىرۇن",
        ayahCount: 6,
        startJuz: 30),
    SurahInfo(
        number: 110,
        nameArabic: "النصر",
        nameUyghur: "نەسر",
        ayahCount: 3,
        startJuz: 30),
    SurahInfo(
        number: 111,
        nameArabic: "المسد",
        nameUyghur: "مەسەد",
        ayahCount: 5,
        startJuz: 30),
    SurahInfo(
        number: 112,
        nameArabic: "الإخلاص",
        nameUyghur: "ئىخلاس",
        ayahCount: 4,
        startJuz: 30),
    SurahInfo(
        number: 113,
        nameArabic: "الفلق",
        nameUyghur: "فەلەق",
        ayahCount: 5,
        startJuz: 30),
    SurahInfo(
        number: 114,
        nameArabic: "الناس",
        nameUyghur: "ناس",
        ayahCount: 6,
        startJuz: 30),
  ];

  static SurahInfo? getSurahByNumber(int number) {
    if (number < 1 || number > 114) return null;
    return surahs[number - 1];
  }

  static List<int> getAyahsForSurah(int surahNumber) {
    final surah = getSurahByNumber(surahNumber);
    if (surah == null) return [];
    return List.generate(surah.ayahCount, (i) => i + 1);
  }
}
