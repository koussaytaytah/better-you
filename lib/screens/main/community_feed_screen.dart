import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommunityFeedScreen extends StatelessWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community Feed',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Text(
          'Community Feed Screen\nComing Soon!',
          style: GoogleFonts.poppins(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
