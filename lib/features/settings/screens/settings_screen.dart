import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:better_you/l10n/app_localizations.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/language_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../core/constants/app_theme.dart';
import 'app_limits_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final isSimpleMode = ref.watch(simpleModeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.settings,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black87
                : Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.light
                ? [
                    const Color(0xFFE0F7F4),
                    Colors.white.withValues(alpha: 0.8),
                    const Color(0xFFE0F7F4).withValues(alpha: 0.5),
                  ]
                : [
                    const Color(0xFF001F1B),
                    Colors.black.withValues(alpha: 0.8),
                    const Color(0xFF001F1B).withValues(alpha: 0.5),
                  ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
          children: [
            _buildSectionHeader(l10n.appearance),
            _buildSettingTile(
              context: context,
              title: l10n.darkMode,
              subtitle: l10n.darkModeSubtitle,
              icon: isDark ? Icons.dark_mode : Icons.light_mode,
              trailing: Switch(
                value: isDark,
                onChanged: (val) =>
                    ref.read(themeModeProvider.notifier).toggleTheme(val),
                activeThumbColor: AppColors.primary,
              ),
            ),
            _buildSettingTile(
              context: context,
              title: 'Simple Mode',
              subtitle: 'Simplify UI and hide secondary features',
              icon: isSimpleMode ? Icons.auto_awesome_mosaic : Icons.dashboard,
              trailing: Switch(
                value: isSimpleMode,
                onChanged: (val) =>
                    ref.read(simpleModeProvider.notifier).toggleSimpleMode(val),
                activeThumbColor: AppColors.primary,
              ),
            ),
            _buildSettingTile(
              context: context,
              title: 'Doom-Scroll Blocker',
              subtitle: 'Lock social apps until you finish quests',
              icon: Icons.shield,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppLimitsScreen()));
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(l10n.language),
            _buildSettingTile(
              context: context,
              title: l10n.currentLanguage,
              subtitle: currentLocale.languageCode == 'en'
                  ? l10n.english
                  : currentLocale.languageCode == 'ar'
                  ? l10n.arabic
                  : 'Français',
              icon: Icons.language,
              onTap: () =>
                  _showLanguagePicker(context, ref, currentLocale, l10n),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(l10n.about),
            _buildSettingTile(
              context: context,
              title: l10n.appVersion,
              subtitle: '1.0.0',
              icon: Icons.info_outline,
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
        trailing:
            trailing ??
            (onTap != null
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Colors.grey,
                    ),
                  )
                : null),
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    Locale current,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.language,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildLanguageOption(
                context,
                ref,
                l10n.english,
                'en',
                current.languageCode == 'en',
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                context,
                ref,
                'Français',
                'fr',
                current.languageCode == 'fr',
              ),
              _buildLanguageOption(
                context,
                ref,
                l10n.arabic,
                'ar',
                current.languageCode == 'ar',
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref,
    String label,
    String code,
    bool isSelected,
  ) {
    return ListTile(
      onTap: () {
        ref.read(languageProvider.notifier).setLanguage(code);
        Navigator.pop(context);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
    );
  }
}
