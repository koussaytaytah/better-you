import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressCalendarScreen extends StatelessWidget {
  const ProgressCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Progress Calendar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Text(
          'Progress Calendar Screen\nComing Soon!',
          style: GoogleFonts.poppins(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
