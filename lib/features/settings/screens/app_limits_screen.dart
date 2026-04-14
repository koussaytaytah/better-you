import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppLimitsScreen extends ConsumerStatefulWidget {
  const AppLimitsScreen({super.key});

  @override
  ConsumerState<AppLimitsScreen> createState() => _AppLimitsScreenState();
}

class _AppLimitsScreenState extends ConsumerState<AppLimitsScreen> {
  List<AppInfo> _installedApps = [];
  Map<String, dynamic> _appLimits = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apps = await InstalledApps.getInstalledApps(true, true);
      final user = ref.read(currentUserProvider);
      
      // Prefer Cloud data, fallback to local prefs
      Map<String, dynamic> initialLimits = {};
      
      if (user != null && user.appLimits.isNotEmpty) {
        initialLimits = Map<String, dynamic>.from(user.appLimits);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final limitsJson = prefs.getString('app_limits') ?? '{}';
        initialLimits = json.decode(limitsJson);
      }
      
      setState(() {
        _installedApps = apps.where((app) => app.packageName != 'com.example.better_you').toList();
        _appLimits = initialLimits;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load apps: $e')));
      }
    }
  }

  Future<void> _saveLimits() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Save to Local Prefs (for Background Service & Native Accessibility)
      await prefs.setString('app_limits', json.encode(_appLimits));
      
      Map<String, bool> lockedStatus = {};
      _appLimits.forEach((key, value) {
         lockedStatus[key] = (value['limit'] == 0);
      });
      await prefs.setString('locked_apps_status', json.encode(lockedStatus));

      // 2. Save to Firestore (for Cloud Backup & Admin/Coach visibility)
      if (user != null) {
        await ref.read(userRepositoryProvider).updateUserProfile(user.uid, {
          'appLimits': _appLimits,
        });
      }

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('App Lock Rules Saved & Synced!'), backgroundColor: AppColors.success)
         );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLimitDialog(AppInfo app) {
    String quest = _appLimits[app.packageName]?['quest'] ?? 'Complete 5000 Steps';
    final questController = TextEditingController(text: quest);
    int selectedMinutes = _appLimits[app.packageName]?['limit'] ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Limit ${app.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Time limit per day:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButton<int>(
                    value: selectedMinutes,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text("Instant Block (0 min)")),
                      DropdownMenuItem(value: 15, child: Text("15 Minutes")),
                      DropdownMenuItem(value: 30, child: Text("30 Minutes")),
                      DropdownMenuItem(value: 60, child: Text("1 Hour")),
                      DropdownMenuItem(value: 120, child: Text("2 Hours")),
                      DropdownMenuItem(value: 180, child: Text("3 Hours")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedMinutes = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Quest to unlock:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: questController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Complete your daily quests',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (!_appLimits.containsKey(app.packageName)) {
                      setState(() {}); // Reset switch if cancelled and wasn't already locked
                    }
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _appLimits[app.packageName] = {
                        'limit': selectedMinutes,
                        'quest': questController.text.trim().isEmpty ? 'Complete your daily quests to unlock!' : questController.text.trim(),
                      };
                    });
                    _saveLimits();
                    Navigator.pop(context);
                  },
                  child: const Text('Save Rule'),
                ),
              ],
            );
          }
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredApps = _installedApps.where((app) {
      final name = (app.name ?? '').toLowerCase();
      final pkg = (app.packageName ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || pkg.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Doom-Scroll Blocker', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Colors.white, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Protect Your Focus',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Select apps to block until you finish your daily quests.',
                              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search apps...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = filteredApps[index];
                      final isLocked = _appLimits.containsKey(app.packageName);
                      final int limitMins = _appLimits[app.packageName]?['limit'] ?? 0;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 50,
                            height: 50,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: app.icon != null
                                ? Image.memory(app.icon!, fit: BoxFit.contain)
                                : const Icon(Icons.android, size: 30, color: Colors.grey),
                          ),
                          title: Text(
                            app.name ?? 'Unknown App',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Text(
                            isLocked ? (limitMins == 0 ? '🚫 Instant Block' : '⏳ $limitMins min limit') : 'No limits set',
                            style: GoogleFonts.poppins(
                              fontSize: 12, 
                              color: isLocked ? (limitMins == 0 ? Colors.red : AppColors.primary) : Colors.grey
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLocked)
                                IconButton(
                                  icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
                                  onPressed: () => _showLimitDialog(app),
                                ),
                              Switch(
                                value: isLocked,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  if (val) {
                                    _showLimitDialog(app);
                                  } else {
                                    setState(() {
                                      _appLimits.remove(app.packageName);
                                    });
                                    _saveLimits();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
