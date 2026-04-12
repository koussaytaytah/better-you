// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Toggle dark or light theme';

  @override
  String get language => 'Language';

  @override
  String get currentLanguage => 'Current Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic (العربية)';

  @override
  String get about => 'About';

  @override
  String get appVersion => 'App Version';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String welcomeBack(String name) {
    return 'Welcome back, $name!';
  }

  @override
  String get continueJourney => 'Continue your health journey today';

  @override
  String get cigarettes => 'Cigarettes';

  @override
  String get calories => 'Calories';

  @override
  String get alcohol => 'Alcohol';

  @override
  String get exercise => 'Exercise';

  @override
  String get water => 'Water';

  @override
  String get sleep => 'Sleep';

  @override
  String get steps => 'Steps';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get trackHabits => 'Track Habits';

  @override
  String get statistics => 'Statistics';

  @override
  String get community => 'Community';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get bmiCalculator => 'BMI Calculator';

  @override
  String get calendar => 'Calendar';

  @override
  String get quests => 'Quests';

  @override
  String get logout => 'Logout';

  @override
  String get profile => 'Profile';

  @override
  String get healthPermissionRequired => 'Health Permissions Required';

  @override
  String get healthPermissionSubtitle =>
      'Grant permission to automatically track your steps and sleep.';

  @override
  String get grantPermission => 'Grant Permission';
}
