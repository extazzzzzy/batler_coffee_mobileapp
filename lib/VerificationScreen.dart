import 'package:batler_app/MainScreen.dart';
import 'package:batler_app/MenuScreen.dart';
import 'package:batler_app/ProfileUserScreen.dart';
import 'package:batler_app/RegisterNewUserScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String authType;

  const VerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.authType,
  }) : super(key: key);

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _verificationCodeController = TextEditingController();
  final String logoImg = 'src/img/batler_logo.png';

  @override
  void initState() {
    super.initState();
    if (widget.authType == 'Telegram') {
      openTelegramBot();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void openTelegramBot() {
    launch(dotenv.env['URL_TG_BOT'].toString(), forceSafariVC: false);
  }

  void showAppSnackBar(BuildContext context, String message) { // Креатор уведомлений
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            message,
            style: TextStyle(
              fontFamily: dotenv.env['APP_FONT_FAMILY'],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color.fromRGBO(10, 66, 51, 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }

  void auth() async {
    final url = Uri.parse('${dotenv.env['API_SERVER']}auth');
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': widget.phoneNumber,
          'input_code': _verificationCodeController.text
        }),
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        if (responseBody['error'] == 'false_code') {
          showAppSnackBar(context, 'Неверный код');
          return;
        }

        // сохраняем токен в кэш
        await prefs.setString('token', responseBody['access_token']);
        await prefs.setString('created_at_token', responseBody['created_at_token']);
        showAppSnackBar(context, 'Авторизация пройдена успешно');

        if (responseBody['is_new_user']) {
          await prefs.setString('is_new_user', 'yes');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterNewUserScreen(),
            ),
          );
        }
        else {
          await prefs.setString('is_new_user', 'no');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
                (route) => false,
          );
        }
      }
      else {
        showAppSnackBar(context, 'Повторите попытку позже');
        print('Ошибка: ${response.statusCode}');
      }
    }
    catch (e) {
      print('Ошибка соединения: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Image.asset(logoImg, height: 256),
              const SizedBox(height: 50),
              
              _VerifyCodeInputField(
                controller: _verificationCodeController,
                label: 'Код подтверждения',
                icon: Icons.verified,
                hint: '',
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(10, 66, 51, 1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    auth();
                  },
                  child: Text(
                    'Войти',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: dotenv.env['APP_FONT_FAMILY'],
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifyCodeInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const _VerifyCodeInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontFamily: dotenv.env['APP_FONT_FAMILY'],
              fontWeight: FontWeight.w500,
              color: const Color.fromRGBO(10, 66, 51, 1)
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
            LengthLimitingTextInputFormatter(5),
          ],
          style: TextStyle(
            fontFamily: dotenv.env['APP_FONT_FAMILY'],
            color: const Color.fromRGBO(10, 66, 51, 1),
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color.fromRGBO(10, 66, 51, 1)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color.fromRGBO(10, 66, 51, 1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color.fromRGBO(10, 66, 51, 1)),
            ),
          ),
        ),
      ],
    );
  }
}