// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get settings => 'الإعدادات';

  @override
  String get appearance => 'المظهر';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get darkModeSubtitle => 'التبديل بين السمة الداكنة أو الفاتحة';

  @override
  String get language => 'اللغة';

  @override
  String get currentLanguage => 'اللغة الحالية';

  @override
  String get english => 'الإنجليزية (English)';

  @override
  String get arabic => 'العربية';

  @override
  String get about => 'حول';

  @override
  String get appVersion => 'إصدار التطبيق';

  @override
  String get pageNotFound => 'الصفحة غير موجودة';

  @override
  String welcomeBack(String name) {
    return 'مرحباً بعودتك، $name!';
  }

  @override
  String get continueJourney => 'واصل رحلتك الصحية اليوم';

  @override
  String get cigarettes => 'السجائر';

  @override
  String get calories => 'السعرات الحرارية';

  @override
  String get alcohol => 'الكحول';

  @override
  String get exercise => 'التمارين';

  @override
  String get water => 'الماء';

  @override
  String get sleep => 'النوم';

  @override
  String get steps => 'الخطوات';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get trackHabits => 'تتبع العادات';

  @override
  String get statistics => 'الإحصائيات';

  @override
  String get community => 'المجتمع';

  @override
  String get aiAssistant => 'مساعد الذكاء الاصطناعي';

  @override
  String get bmiCalculator => 'حاسبة BMI';

  @override
  String get calendar => 'التقويم';

  @override
  String get quests => 'المهام';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get healthPermissionRequired => 'مطلوب أذونات الصحة';

  @override
  String get healthPermissionSubtitle =>
      'امنح الإذن لتتبع خطواتك ونومك تلقائياً.';

  @override
  String get grantPermission => 'منح الإذن';
}
