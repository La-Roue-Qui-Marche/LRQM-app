import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lrqm/UI/WorkingScreen.dart';
import 'package:lrqm/UI/LoginScreen.dart';

import 'Data/UserData.dart';

void main() async {
  /// Ensure that the WidgetsBinding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  /// Set preferred orientations to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  /// Check if user data exists in the shared preferences
  final bool isLoggedIn = (await UserData.getUserId()) != null;

  /// Run the application
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'La RQM APP',
      theme: ThemeData(
        fontFamily: 'SfPro',
      ),
      home: isLoggedIn ? const WorkingScreen() : const Login(),
    );
  }
}
