import 'package:flutter/material.dart';
import 'login.dart';
import 'entree.dart';
import 'pointage.dart'; 
import 'package:intl/date_symbol_data_local.dart';
import 'create_page.dart';
import 'PasswordSetupPage.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

   await initializeDateFormatting('fr_FR', null); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'i-pointe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(title: "Login",),
     '/entree': (context) => EntreePage() ,
     '/pointage': (context) => const PointagePage(),
        '/create': (context) => const CreatePage(),
        
      },
    );
  }
}
