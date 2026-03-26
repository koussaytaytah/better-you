import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HabitTrackerScreen extends StatelessWidget {
  const HabitTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Habit Tracker',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Text(
          'Habit Tracker Screen\nComing Soon!',
          style: GoogleFonts.poppins(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
