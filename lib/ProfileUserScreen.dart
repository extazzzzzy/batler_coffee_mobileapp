import 'package:batler_app/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileUserScreen extends StatefulWidget {
  @override
  _ProfileUserScreenState createState() => _ProfileUserScreenState();
}

class _ProfileUserScreenState extends State<ProfileUserScreen> {
  final String smileImg = 'src/img/emoji_profilescreen.png';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  void dispose() {
    super.dispose();
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

  void saveUserData() async {
    if (_nameController.text == '' || _birthDateController.text == '') {
      showAppSnackBar(context, 'Заполните все поля');
      return;
    }

    final url = Uri.parse('${dotenv.env['API_SERVER']}save_userdata');
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': prefs.getString('token'),
          'name': _nameController.text,
          'birthday': _birthDateController.text,
        }),
      );
      if (response.statusCode == 200) {
        await prefs.setString('name', _nameController.text);
        await prefs.setString('birthday', _birthDateController.text);
        showAppSnackBar(context, 'Данные успешно сохранены');
      }
      else {
        showAppSnackBar(context, 'Повторите попытку позже');
        print('Ошибка: ${response.statusCode}');
      }
    }
    catch (e) {
      showAppSnackBar(context, 'Ошибка соединения');
      print('Ошибка соединения: $e');
    }
  }

  void getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final url = Uri.parse('${dotenv.env['API_SERVER']}fetch_userdata');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': prefs.getString('token'),
        }),
      );
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        _nameController.text = responseBody['name'];
        _birthDateController.text = responseBody['birthday'];
      }
      else {
        showAppSnackBar(context, 'Ошибка получения данных');
        print('Ошибка: ${response.statusCode}');
      }
      setState(() {
        isLoading = false;
      });
    }
    catch (e) {
      showAppSnackBar(context, 'Ошибка соединения');
      print('Ошибка соединения: $e');
    }
  }

  void exitUser() async {
    final url = Uri.parse('${dotenv.env['API_SERVER']}out');
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': prefs.getString('token'),
        }),
      );
      if (response.statusCode == 200) {
        await prefs.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      }
      else {
        showAppSnackBar(context, 'Повторите попытку позже');
        print('Ошибка: ${response.statusCode}');
      }
    }
    catch (e) {
      showAppSnackBar(context, 'Ошибка соединения');
      print('Ошибка соединения: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: isLoading
        ? Center(child: CircularProgressIndicator(color: Color.fromRGBO(10, 66, 51, 1)))
      :
      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Image.asset(smileImg, height: 170),
              const SizedBox(height: 30),

              Center(
                child: Text(
                  'Мои данные',
                  style: TextStyle(
                    fontFamily: dotenv.env['APP_FONT_FAMILY'],
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              UserDataInputField(
                controller: _nameController,
                label: 'Как вас зовут?',
                hint: 'Ваше имя',
                icon: Icons.person,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 10),
              UserDataInputField(
                controller: _birthDateController,
                label: 'Дата рождения',
                hint: 'ДД.ММ.ГГГГ',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    locale: const Locale('ru', 'RU'),
                  );
                  if (date != null) {
                    _birthDateController.text = DateFormat('dd.MM.yyyy').format(date);
                  }
                },
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
                    saveUserData();
                  },
                  child: Text(
                    'Сохранить',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: dotenv.env['APP_FONT_FAMILY'],
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    exitUser();
                  },
                  child: Text(
                    'Выйти',
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

class UserDataInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  const UserDataInputField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLength,
    this.readOnly = false,
    this.onTap,
    this.validator,
  }) : super(key: key);

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
            color: const Color.fromRGBO(10, 66, 51, 1),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
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
            counterText: '',
          ),
        ),
      ],
    );
  }
}