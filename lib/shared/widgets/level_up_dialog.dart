import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LevelUpDialog extends StatelessWidget {
  final int level;

  const LevelUpDialog({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.amber, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, color: Colors.amber, size: 80)
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .rotate(duration: 600.ms),
            const SizedBox(height: 16),
            Text(
              'LEVEL UP!',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5),
            const SizedBox(height: 8),
            Text(
              'You reached Level $level',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 24),
            Text(
              'Keep up the great work on your health journey!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ).animate().fadeIn(delay: 700.ms),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('AWESOME!', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ).animate().fadeIn(delay: 900.ms).scale(),
          ],
        ),
      ),
    );
  }
}
