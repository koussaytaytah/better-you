import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/screen_time_service.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ScreenTimeManagementScreen extends ConsumerStatefulWidget {
  const ScreenTimeManagementScreen({super.key});

  @override
  ConsumerState<ScreenTimeManagementScreen> createState() =>
      _ScreenTimeManagementScreenState();
}

class _ScreenTimeManagementScreenState
    extends ConsumerState<ScreenTimeManagementScreen>
    with WidgetsBindingObserver {
  final ScreenTimeService _service = ScreenTimeService();
  bool _hasPermission = false;
  List<String> _apps = [];
  Map<String, AppInfo> _appDetails = {};
  Map<String, int> _usageMap = {};
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadApps();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadApps();
    }
  }

  Future<void> _loadApps() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      debugPrint('BetterYou: Loading apps...');
      _hasPermission = await _service.checkPermission();
      debugPrint('BetterYou: Has permissions: $_hasPermission');

      // Get usage stats if we have permission
      if (_hasPermission) {
        _usageMap = await _service.getDailyUsage();
      }

      // ALWAYS load installed apps, even without permissions
      final allInstalled = await InstalledApps.getInstalledApps(true, true);
      debugPrint('BetterYou: Installed apps found: ${allInstalled.length}');

      final Map<String, AppInfo> details = {};
      final List<String> packageNames = [];

      for (var app in allInstalled) {
        final pkg = app.packageName;
        // Filter out system apps that aren't useful or this app itself
        if (pkg == 'com.example.better_you') continue;
        details[pkg] = app;
        packageNames.add(pkg);
      }

      _appDetails = details;

      // Sort package names by usage if available, otherwise alphabetically
      packageNames.sort((a, b) {
        if (_hasPermission) {
          final usageA = _usageMap[a] ?? 0;
          final usageB = _usageMap[b] ?? 0;
          if (usageA != usageB) return usageB.compareTo(usageA);
        }
        final nameA = _appDetails[a]?.name ?? a;
        final nameB = _appDetails[b]?.name ?? b;
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });

      _apps = packageNames;
      debugPrint('BetterYou: Apps list prepared: ${_apps.length} items');
    } catch (e, stack) {
      debugPrint('BetterYou: Error loading apps: $e');
      debugPrint(stack.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredApps = _apps.where((pkg) {
      final detail = _appDetails[pkg];
      if (detail == null) return false;
      final name = detail.name.toLowerCase();
      final pkgLower = pkg.toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          pkgLower.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'App Limits',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!_hasPermission) _buildPermissionBanner(),
                if (_searchQuery.isEmpty) _buildHighUsageSection(user),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search for an app...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: isDark ? Colors.grey[900] : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 0,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredApps.isEmpty
                      ? _buildEmptyState()
                      : _buildAppList(filteredApps, user, isDark),
                ),
              ],
            ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Setup is incomplete. Apps won\'t be blocked.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => _showPermissionDialog(),
            child: const Text('SETUP', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: _buildPermissionRequest(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apps_outage_outlined,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No apps found on this device'
                : 'No apps matching "$_searchQuery"',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHighUsageSection(UserModel? user) {
    if (user == null || _usageMap.isEmpty) return const SizedBox.shrink();

    // Get top 3 most used apps that aren't this app
    final topApps =
        _usageMap.entries
            .where((e) => e.key != 'com.example.better_you')
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final highUsageApps = topApps.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'High Usage Detected',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...highUsageApps.map((e) {
            final detail = _appDetails[e.key];
            final isLimited = user.appLimits.containsKey(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  if (detail?.icon != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(detail!.icon!, width: 24, height: 24),
                    )
                  else
                    const Icon(Icons.android, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      detail?.name ?? e.key.split('.').last,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${e.value}m',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!isLimited)
                    InkWell(
                      onTap: () => _showSetLimitDialog(
                        e.key,
                        detail?.name ?? e.key,
                        user,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'SET LIMIT',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildAppList(List<String> apps, UserModel? user, bool isDark) {
    if (user == null) return const SizedBox.shrink();

    return ListView.builder(
      itemCount: apps.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final pkg = apps[index];
        final detail = _appDetails[pkg];
        final limitData = (user.appLimits[pkg] as Map?)
            ?.cast<String, dynamic>();
        final isLimited = limitData != null;
        final int limitMins = (limitData?['limit'] as num?)?.toInt() ?? 999999;
        final int usageMins = _usageMap[pkg] ?? 0;

        return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () =>
                      _showSetLimitDialog(pkg, detail?.name ?? pkg, user),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: detail?.icon != null
                                ? Image.memory(
                                    detail!.icon!,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.android,
                                              size: 32,
                                              color: Colors.grey,
                                            ),
                                  )
                                : const Icon(
                                    Icons.android,
                                    size: 32,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail?.name ??
                                    pkg.split('.').last.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 14,
                                    color: usageMins > limitMins
                                        ? Colors.red
                                        : AppColors.primary.withValues(
                                            alpha: 0.6,
                                          ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$usageMins mins',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: usageMins > limitMins
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                  if (isLimited) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '/ $limitMins mins',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (isLimited) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: (usageMins / limitMins).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      usageMins >= limitMins
                                          ? Colors.red
                                          : AppColors.primary,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      size: 10,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Limit: ${limitData['limit']}m • ${limitData['quest']}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Switch.adaptive(
                          value: isLimited,
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primary.withValues(
                            alpha: 0.5,
                          ),
                          onChanged: (val) {
                            if (val) {
                              _showSetLimitDialog(
                                pkg,
                                detail?.name ?? pkg,
                                user,
                              );
                            } else {
                              _removeLimit(pkg, user);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: (index * 50).ms)
            .slideX(begin: 0.1);
      },
    );
  }

  void _showSetLimitDialog(String pkg, String appName, UserModel user) {
    final limitController = TextEditingController(
      text: user.appLimits[pkg]?['limit']?.toString() ?? '60',
    );
    String selectedQuest = user.appLimits[pkg]?['quest'] ?? '10 Pushups';
    final customQuestController = TextEditingController();
    bool isCustom = !AppConstants.defaultQuests.contains(selectedQuest);

    if (isCustom) customQuestController.text = selectedQuest;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text('Limit for $appName')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How many minutes per day?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: limitController,
                  decoration: InputDecoration(
                    hintText: 'e.g. 60',
                    suffixText: 'mins',
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Choose an unlock quest:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: isCustom ? 'Custom' : selectedQuest,
                      items: <String>[...AppConstants.defaultQuests, 'Custom']
                          .map<DropdownMenuItem<String>>(
                            (q) => DropdownMenuItem<String>(
                              value: q,
                              child: Text(q),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == 'Custom') {
                            isCustom = true;
                          } else {
                            isCustom = false;
                            selectedQuest = val!;
                          }
                        });
                      },
                    ),
                  ),
                ),
                if (isCustom) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: customQuestController,
                    decoration: InputDecoration(
                      hintText: 'Enter your custom quest',
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => selectedQuest = val,
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Completing this quest will grant you 15 minutes of extra time.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final limit = int.tryParse(limitController.text) ?? 60;
                final quest = isCustom
                    ? customQuestController.text.trim()
                    : selectedQuest;
                if (quest.isNotEmpty) {
                  await _updateLimit(pkg, limit, quest, user);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Limit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.security_outlined,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Permissions Required',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'To monitor your app usage and intervene when limits are reached, please grant the following:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          FutureBuilder<Map<String, dynamic>>(
            future:
                Future.wait([
                  _service.checkUsagePermissionOnly(),
                  _service.checkOverlayPermissionOnly(),
                  _service.checkNotificationPermissionOnly(),
                  _checkAccessibilityPermission(),
                ]).then(
                  (results) => {
                    'Usage Stats (Required)': results[0],
                    'Overlay (Important)': results[1],
                    'Notifications': results[2],
                    'Accessibility (Blocker)': results[3],
                  },
                ),
            builder: (context, snapshot) {
              final permissions =
                  snapshot.data ??
                  {
                    'Usage Stats (Required)': false,
                    'Overlay (Important)': false,
                    'Notifications': false,
                    'Accessibility (Blocker)': false,
                  };

              return Column(
                children: permissions.entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () async {
                            if (!entry.value) {
                              if (entry.key.contains('Usage')) {
                                await _service.requestUsagePermission();
                              } else if (entry.key.contains('Overlay')) {
                                await _service.requestOverlayPermission();
                              } else if (entry.key.contains('Accessibility')) {
                                await _requestAccessibilityPermission();
                              } else {
                                await _service.requestNotificationPermission();
                              }
                              setState(() {});
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: entry.value
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: entry.value
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : AppColors.primary.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  entry.value
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: entry.value
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: entry.value
                                        ? Colors.green
                                        : Colors.black,
                                  ),
                                ),
                                const Spacer(),
                                if (!entry.value)
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadApps(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('CHECK PERMISSIONS AGAIN'),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkAccessibilityPermission() async {
    const channel = MethodChannel('com.example.better_you/lock');
    try {
      return await channel.invokeMethod('isAccessibilityServiceEnabled') ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _requestAccessibilityPermission() async {
    const channel = MethodChannel('com.example.better_you/lock');
    try {
      await channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      // ignore
    }
  }

  Future<void> _updateLimit(
    String pkg,
    int limit,
    String quest,
    UserModel user,
  ) async {
    final updatedLimits = Map<String, dynamic>.from(user.appLimits);
    updatedLimits[pkg] = {'limit': limit, 'quest': quest};

    // Save to SharedPreferences for Background Service
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_limits', json.encode(updatedLimits));

    // Notify background service directly
    FlutterBackgroundService().invoke('updateLimits', updatedLimits);

    // Notify background service directly
    FlutterBackgroundService().invoke('updateLimits', updatedLimits);

    await ref.read(userRepositoryProvider).updateUserProfile(user.uid, {
      'appLimits': updatedLimits,
    });
    ref.invalidate(currentUserProvider);
  }

  Future<void> _removeLimit(String pkg, UserModel user) async {
    final updatedLimits = Map<String, dynamic>.from(user.appLimits);
    updatedLimits.remove(pkg);

    // Save to SharedPreferences for Background Service
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_limits', json.encode(updatedLimits));

    await ref.read(userRepositoryProvider).updateUserProfile(user.uid, {
      'appLimits': updatedLimits,
    });
    ref.invalidate(currentUserProvider);
  }
}
