import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle get h1 => GoogleFonts.poppins(
        fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static TextStyle get h2 => GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3);
  static TextStyle get h3 =>
      GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600);
  static TextStyle get h4 =>
      GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600);

  static TextStyle get bodyLarge =>
      GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400);
  static TextStyle get bodyMedium =>
      GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle get bodySmall =>
      GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400);

  static TextStyle get labelLarge =>
      GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600);
  static TextStyle get labelMedium =>
      GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600);
  static TextStyle get labelSmall =>
      GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500);

  static TextStyle get chatMessage =>
      GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4);
  static TextStyle get chatTime =>
      GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400);
  static TextStyle get username =>
      GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700);

  static TextStyle get button =>
      GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white);
  static TextStyle get buttonSmall =>
      GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white);
}
