import 'package:intl/intl.dart';

List<int> gregorianToJalali(DateTime g) {
  final gy = g.year;
  final gm = g.month;
  final gd = g.day;
  const gDaysInMonth = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  final gy2 = (gm > 2) ? (gy + 1) : gy;
  int days = 355666 + (365 * gy) + ((gy2 + 3) ~/ 4) - ((gy2 + 99) ~/ 100) + ((gy2 + 399) ~/ 400) + gd;
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

String toJalaliDate(DateTime dt) {
  final j = gregorianToJalali(dt);
  return '${j[0]}/${j[1].toString().padLeft(2, '0')}/${j[2].toString().padLeft(2, '0')}';
}

String toJalaliDateTime(DateTime dt) {
  final d = toJalaliDate(dt);
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$d $h:$m';
}

String timeOnly(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}