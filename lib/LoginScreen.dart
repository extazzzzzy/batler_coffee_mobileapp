import 'package:batler_app/VerificationScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isTelegramSelected = false;
  final TextEditingController _loginController = TextEditingController();
  final String logoImg = 'src/img/batler_logo.png';

  @override
  void initState() {
    super.initState();
    _loginController.text = '+79';
    _loginController.addListener(_protectPrefix);
  }

  @override
  void dispose() {
    _loginController.removeListener(_protectPrefix);
    _loginController.dispose();
    super.dispose();
  }

  void _protectPrefix() {
    if (!_loginController.text.startsWith('+79')) {
      _loginController.text = '+79';
      _loginController.selection = TextSelection.collapsed(offset: 3);
    }
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

  Future<void> sendVerifyCode(phone_number, isAuthTelegram) async{
    if (phone_number.length != 12) {
      showAppSnackBar(context, 'Неверный формат номера телефона');
      return;
    }

    if (!isAuthTelegram) {
      showAppSnackBar(context, 'Данный тип авторизации недоступен');
      return;
    }
    else {
      final url = Uri.parse('${dotenv.env['API_SERVER']}verify_tg');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'phone_number': phone_number,
            'type_auth': isAuthTelegram ? 'Telegram' : 'WhatsApp'
          }),
        );

        if (response.statusCode == 200) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                authType: isAuthTelegram ? 'Telegram' : 'WhatsApp',
                phoneNumber: phone_number,
              ),
            ),
          );
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
              Row(
                children: [
                  Expanded(
                    child: _AuthTypeButton(
                      text: 'Telegram',
                      isSelected: _isTelegramSelected,
                      onTap: () => setState(() => _isTelegramSelected = true),
                    ),
                  ),
                  Expanded(
                    child: _AuthTypeButton(
                      text: 'WhatsApp',
                      isSelected: !_isTelegramSelected,
                      onTap: () => setState(() => _isTelegramSelected = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _LoginInputField(
                controller: _loginController,
                label: 'Номер телефона',
                hint: 'Ваш номер телефона',
                icon: Icons.phone_android,
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
                    sendVerifyCode(_loginController.text, _isTelegramSelected);
                  },
                  child: Text(
                    'Получить код',
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

class _AuthTypeButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _AuthTypeButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: isSelected ? const Color.fromRGBO(10, 66, 51, 1) : Colors.white,
          border: Border.all(
            color: const Color.fromRGBO(10, 66, 51, 1),
            width: 1.5,
          ),
          borderRadius: BorderRadius.horizontal(
            left: text == 'Telegram' ? const Radius.circular(8) : Radius.zero,
            right: text == 'WhatsApp' ? const Radius.circular(8) : Radius.zero,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: dotenv.env['APP_FONT_FAMILY'],
              color: isSelected ? Colors.white : const Color.fromRGBO(10, 66, 51, 1),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const _LoginInputField({
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
          LengthLimitingTextInputFormatter(12),
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