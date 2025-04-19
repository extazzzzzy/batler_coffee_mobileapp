import 'dart:async';

import 'package:batler_app/LoginScreen.dart';
import 'package:batler_app/VerificationScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserOrdersScreen extends StatefulWidget {
  @override
  _UserOrdersScreenState createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends State<UserOrdersScreen> {
  List<dynamic> orders = [];
  int orderCount = 0;
  bool isLoading = true;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    getUserOrders();
    _pollingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      getUserOrders();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
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

  void getUserOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final url = Uri.parse('${dotenv.env['API_SERVER']}fetch_user_orders');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': prefs.getString('token'),
          'created_at_token': prefs.getString('created_at_token'),
        }),
      );

      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        setState(() {
          orders = responseBody['orders'] ?? [];
          orderCount = responseBody['count'] ?? 0;
          isLoading = false;
        });
      }
      else if (response.statusCode == 401) {
        showAppSnackBar(context, 'Сеанс пользователя истёк');
        await prefs.clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
        );
      }
      else {
        showAppSnackBar(context, 'Ошибка получения данных');
        print('Ошибка: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    }
    catch (e) {
      showAppSnackBar(context, 'Ошибка соединения');
      print('Ошибка соединения: $e');
      setState(() => isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Новый': return Colors.red;
      case 'Готовится': return Colors.amber;
      case 'Готов к выдаче': return Colors.green;
      case 'Завершён':
      case 'Отменён':
        return Colors.grey;
      default: return Colors.blue;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showOrderDetails(BuildContext context, dynamic order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Заказ от ${_formatDate(order['created_at'])}',
                  style: TextStyle(
                    fontFamily: dotenv.env['APP_FONT_FAMILY'],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${order['total_sum']}р',
                  style: TextStyle(
                    fontFamily: dotenv.env['APP_FONT_FAMILY'],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['status']),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  order['status'],
                  style: TextStyle(
                    fontFamily: dotenv.env['APP_FONT_FAMILY'],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Text(
              'Готовность: ${order['ready_for']}',
              style: TextStyle(
                fontFamily: dotenv.env['APP_FONT_FAMILY'],
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Состав заказа:',
              style: TextStyle(
                fontFamily: dotenv.env['APP_FONT_FAMILY'],
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),
            Text(
              order['description'],
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontFamily: dotenv.env['APP_FONT_FAMILY'],
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child:
                    Text(
                      'Закрыть',
                      style: TextStyle(
                        fontFamily: dotenv.env['APP_FONT_FAMILY'],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(10, 66, 51, 1), // Changed from primary to backgroundColor
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мои заказы ($orderCount)',
          style: TextStyle(
            fontFamily: dotenv.env['APP_FONT_FAMILY'],
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),),
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(child: Text('У вас пока нет заказов', style: TextStyle(
      fontFamily: dotenv.env['APP_FONT_FAMILY'],
        fontSize: 18,
        color: Colors.grey,
      ),))
          : ListView.builder(
        padding: EdgeInsets.all(10),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: EdgeInsets.only(bottom: 15),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showOrderDetails(context, order),
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Заказ от ${_formatDate(order['created_at'])}',
                          style: TextStyle(
                            fontFamily: dotenv.env['APP_FONT_FAMILY'],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${order['total_sum']}р',
                          style: TextStyle(
                            fontFamily: dotenv.env['APP_FONT_FAMILY'],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _getStatusColor(order['status']),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(order['status'],
                          style: TextStyle(fontFamily: dotenv.env['APP_FONT_FAMILY'],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,),),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}