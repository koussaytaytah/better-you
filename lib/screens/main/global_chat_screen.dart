import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalChatScreen extends StatelessWidget {
  const GlobalChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Global Chat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Text(
          'Global Chat Screen\nComing Soon!',
          style: GoogleFonts.poppins(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
