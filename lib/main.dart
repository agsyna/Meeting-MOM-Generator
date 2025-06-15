
import 'package:flutter/material.dart';
import 'package:meeting_gist/screens/welcome_screen.dart';

void main()
{
  runApp(
    MaterialApp(
      themeMode: ThemeMode.system, // can be ThemeMode.light or ThemeMode.dark
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF7785FF),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF7785FF),
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF7785FF),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF7785FF),
          foregroundColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body : WelcomeScreen(),
        )
  ),);
}