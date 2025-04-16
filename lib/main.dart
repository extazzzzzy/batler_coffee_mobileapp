import 'package:batler_app/MainScreen.dart';
import 'package:batler_app/ProfileUserScreen.dart';
import 'package:batler_app/RegisterNewUserScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:batler_app/LoginScreen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

Future<bool> isValidateToken(String token) async {
  final url = Uri.parse('${dotenv.env['API_SERVER']}check_validate_token');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'token': token}),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      return responseBody['validate'] != false;
    }
    return false;
  }
  catch (e) {
    return false;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getInitialScreen(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        };

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'BatlerCoffee',
          theme: ThemeData(
            // Основная цветовая схема
            colorScheme: ColorScheme.light(
            primary: Color.fromRGBO(10, 66, 51, 1), // Основной цвет (кнопки, AppBar)
            secondary: Colors.white, // Дополнительный цвет
            surface: Colors.white, // Фон календаря и карточек
            ),
          ),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('ru', 'RU'), // Русский язык
          ],
          home: snapshot.data,
        );
      },
    );
  }

  Future<Widget> _getInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      return LoginScreen();
    }

    final isValid = await isValidateToken(token);
    if (!isValid) {
      await prefs.remove('token');
      return LoginScreen();
    }

    final isNewUser = prefs.getString('is_new_user');
    if (isNewUser == 'yes') {
      return RegisterNewUserScreen();
    }

    return MainScreen();
  }
}