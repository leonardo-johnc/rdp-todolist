import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rdp_todolist/screens/home_page.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
//initialize flutter bondings
  WidgetsFlutterBinding.ensureInitialized();

  //intialize flutter with the current platform's default options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /*load environment variables from the .env file 
  since i'm getting a warning of leak on github and told me to hide api key in a .env file and place it in .gitignore*/
   await dotenv.load();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}
