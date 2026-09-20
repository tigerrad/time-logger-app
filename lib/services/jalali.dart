import 'package:intl/intl.dart';

/// تبدیل تاریخ میلادی به شمسی
List<int> gregorianToJalali(DateTime g) {
  final gy = g.year;
  final gm = g.month;
  final gd = g.day;

  const gDaysInMonth = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  final gy2 = (gm > 2) ? (gy + 1) : gy;

  int days = 355666 +
      (365 * gy) +
      ((gy2 + 3) ~/ 4) -
      ((gy2 + 99) ~/ 100) +
      ((gy2 + 399) ~/ 400) +
      gd;

  for (int i = 1; i < gm; i++) {
    days += gDaysInMonth[i];
  }

  int jy = -1595 + (33 * (days ~/ 12053));
  days %= 12053;
  jy += 4 * (days ~/ 1461);
  days %= 1461;

  if (days > 365) {
    jy += ((days - 1) ~/ 365);
    days = (days - 1) % 365;
  }

  int jm, jd;
  if (days < 186) {
    jm = 1 + (days ~/ 31);
    jd = 1 + (days % 31);
  } else {
    jm = 7 + ((days - 186) ~/ 30);
    jd = 1 + ((days - 186) % 30);
  }

  return [jy, jm, jd];
}

/// تبدیل تاریخ به فرمت شمسی: 1403/06/30
String toJalaliDate(DateTime dt) {
  final j = gregorianToJalali(dt);
  return '${j[0]}/${j[1].toString().padLeft(2, '0')}/${j[2].toString().padLeft(2, '0')}';
}

/// تبدیل تاریخ و ساعت به فرمت شمسی: 1403/06/30 14:35
String toJalaliDateTime(DateTime dt) {
  final d = toJalaliDate(dt);
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$d $h:$m';
}

/// فقط زمان: 14:35
String timeOnly(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// نام روز هفته به فارسی
String jalaliWeekday(DateTime dt) {
  const names = [
    'دوشنبه',  // 1
    'سه‌شنبه', // 2
    'چهارشنبه',// 3
    'پنج‌شنبه',// 4
    'جمعه',   // 5
    'شنبه',   // 6
    'یکشنبه', // 7
  ];
  return names[dt.weekday - 1];
}

/// نام ماه شمسی
String jalaliMonthName(int month) {
  const names = [
    'فروردین', 'اردیبهشت', 'خرداد',
    'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر',
    'دی', 'بهمن', 'اسفند',
  ];
  if (month < 1 || month > 12) return '';
  return names[month - 1];
}

/// فرمت تاریخ میلادی برای نمایش در دیالوگ‌ها
String formatGregorianDate(DateTime dt) {
  return DateFormat('yyyy/MM/dd').format(dt);
}

/// فرمت کامل میلادی برای ذخیره‌سازی
String toIsoString(DateTime dt) {
  return dt.toIso8601String();
}