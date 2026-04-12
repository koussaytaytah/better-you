import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../../../core/constants/app_theme.dart';

class AppLimitsScreen extends StatefulWidget {
  const AppLimitsScreen({super.key});

  @override
  State<AppLimitsScreen> createState() => _AppLimitsScreenState();
}

class _AppLimitsScreenState extends State<AppLimitsScreen> {
  List<AppInfo> _installedApps = [];
  Map<String, dynamic> _appLimits = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apps = await InstalledApps.getInstalledApps(true, true);
      final prefs = await SharedPreferences.getInstance();
      
      // Load current limits saved for the native service to read
      final limitsJson = prefs.getString('app_limits') ?? '{}';
      
      setState(() {
        _installedApps = apps.where((app) => app.packageName != 'com.example.better_you').toList();
        _appLimits = json.decode(limitsJson);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_limits', json.encode(_appLimits));
    
    // The native android accessibility service reads "flutter.app_limits"
    // SharedPreferences automatically prepends "flutter." so we just save it locally as 'app_limits'.

    Map<String, bool> lockedStatus = {};
    _appLimits.forEach((key, value) {
       // If limit is 0, lock it instantly. Otherwise, wait for background service to lock it when time runs out.
       lockedStatus[key] = (value['limit'] == 0);
    });
    await prefs.setString('locked_apps_status', json.encode(lockedStatus));

    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('App Lock Rules Saved!'), backgroundColor: AppColors.success)
       );
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Doom-Scroll Blocker', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.shield, color: AppColors.primary, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Select apps to block until you finish your daily quests!',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _installedApps.length,
                    itemBuilder: (context, index) {
                      final app = _installedApps[index];
                      final isLocked = _appLimits.containsKey(app.packageName);
                      
                      return ListTile(
                        leading: app.icon != null
                            ? Image.memory(app.icon!, width: 40, height: 40)
                            : const Icon(Icons.android, size: 40),
                        title: Text(app.name ?? 'Unknown App', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        subtitle: Text(app.packageName ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLocked)
                              IconButton(
                                icon: const Icon(Icons.edit, color: AppColors.primary),
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
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
