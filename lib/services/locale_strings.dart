import 'language_service.dart';

class L {
  final AppLanguage lang;
  L(this.lang);

  String get appTitle {
    switch (lang) {
      case AppLanguage.fa:
        return 'تایم لاگر — سازنده: کورش شیراز';
      case AppLanguage.en:
        return 'Time Logger — by Kurosh Shiraz';
      case AppLanguage.ar:
        return 'مسجل الوقت — کوروش شیراز';
    }
  }

  String get tabTimer {
    switch (lang) {
      case AppLanguage.fa:
        return 'تایم';
      case AppLanguage.en:
        return 'Time';
      case AppLanguage.ar:
        return 'الوقت';
    }
  }

  String get tabGoals {
    switch (lang) {
      case AppLanguage.fa:
        return 'اهداف';
      case AppLanguage.en:
        return 'Goals';
      case AppLanguage.ar:
        return 'الأهداف';
    }
  }

  String get tabSavings {
    switch (lang) {
      case AppLanguage.fa:
        return 'پس‌انداز';
      case AppLanguage.en:
        return 'Savings';
      case AppLanguage.ar:
        return 'المدخرات';
    }
  }

  String get tabFinance {
    switch (lang) {
      case AppLanguage.fa:
        return 'مالی';
      case AppLanguage.en:
        return 'Finance';
      case AppLanguage.ar:
        return 'المالية';
    }
  }

  String get tabMeetings {
    switch (lang) {
      case AppLanguage.fa:
        return 'جلسات';
      case AppLanguage.en:
        return 'Meetings';
      case AppLanguage.ar:
        return 'الاجتماعات';
    }
  }

  String get tabReports {
    switch (lang) {
      case AppLanguage.fa:
        return 'گزارش';
      case AppLanguage.en:
        return 'Reports';
      case AppLanguage.ar:
        return 'التقارير';
    }
  }

  String get tabPublications {
    switch (lang) {
      case AppLanguage.fa:
        return 'نشریات';
      case AppLanguage.en:
        return 'Publications';
      case AppLanguage.ar:
        return 'المنشورات';
    }
  }

  String get tabSettings {
    switch (lang) {
      case AppLanguage.fa:
        return 'تنظیمات';
      case AppLanguage.en:
        return 'Settings';
      case AppLanguage.ar:
        return 'الإعدادات';
    }
  }

  String get settingsTheme {
    switch (lang) {
      case AppLanguage.fa:
        return 'تم';
      case AppLanguage.en:
        return 'Theme';
      case AppLanguage.ar:
        return 'المظهر';
    }
  }

  String get settingsDark {
    switch (lang) {
      case AppLanguage.fa:
        return 'تاریک';
      case AppLanguage.en:
        return 'Dark';
      case AppLanguage.ar:
        return 'داكن';
    }
  }

  String get settingsLight {
    switch (lang) {
      case AppLanguage.fa:
        return 'روشن';
      case AppLanguage.en:
        return 'Light';
      case AppLanguage.ar:
        return 'فاتح';
    }
  }

  String get settingsColorBlue {
    switch (lang) {
      case AppLanguage.fa:
        return 'آبی';
      case AppLanguage.en:
        return 'Blue';
      case AppLanguage.ar:
        return 'أزرق';
    }
  }

  String get settingsColorGreen {
    switch (lang) {
      case AppLanguage.fa:
        return 'سبز';
      case AppLanguage.en:
        return 'Green';
      case AppLanguage.ar:
        return 'أخضر';
    }
  }

  String get settingsColorPurple {
    switch (lang) {
      case AppLanguage.fa:
        return 'بنفش';
      case AppLanguage.en:
        return 'Purple';
      case AppLanguage.ar:
        return 'بنفسجي';
    }
  }

  String get settingsLanguage {
    switch (lang) {
      case AppLanguage.fa:
        return 'زبان';
      case AppLanguage.en:
        return 'Language';
      case AppLanguage.ar:
        return 'اللغة';
    }
  }

  String get settingsFarsi {
    switch (lang) {
      case AppLanguage.fa:
        return 'فارسی';
      case AppLanguage.en:
        return 'Persian';
      case AppLanguage.ar:
        return 'الفارسية';
    }
  }

  String get settingsEnglish {
    switch (lang) {
      case AppLanguage.fa:
        return 'انگلیسی';
      case AppLanguage.en:
        return 'English';
      case AppLanguage.ar:
        return 'الإنجليزية';
    }
  }

  String get settingsArabic {
    switch (lang) {
      case AppLanguage.fa:
        return 'عربی';
      case AppLanguage.en:
        return 'Arabic';
      case AppLanguage.ar:
        return 'العربية';
    }
  }

  String get settingsSecurity {
    switch (lang) {
      case AppLanguage.fa:
        return 'امنیت';
      case AppLanguage.en:
        return 'Security';
      case AppLanguage.ar:
        return 'الأمان';
    }
  }

  String get settingsPinLock {
    switch (lang) {
      case AppLanguage.fa:
        return 'قفل با رمز عددی';
      case AppLanguage.en:
        return 'PIN Lock';
      case AppLanguage.ar:
        return 'قفل برقم سري';
    }
  }

  String get settingsFingerprint {
    switch (lang) {
      case AppLanguage.fa:
        return 'اثر انگشت';
      case AppLanguage.en:
        return 'Fingerprint';
      case AppLanguage.ar:
        return 'بصمة الإصبع';
    }
  }

  String get settingsAbout {
    switch (lang) {
      case AppLanguage.fa:
        return 'درباره';
      case AppLanguage.en:
        return 'About';
      case AppLanguage.ar:
        return 'حول';
    }
  }

  String get settingsCheckUpdate {
    switch (lang) {
      case AppLanguage.fa:
        return 'بررسی بروزرسانی';
      case AppLanguage.en:
        return 'Check for Updates';
      case AppLanguage.ar:
        return 'التحقق من التحديثات';
    }
  }
}