import 'package:batler_app/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PromocodesScreen extends StatefulWidget {
  @override
  _PromocodesScreenState createState() => _PromocodesScreenState();
}

class _PromocodesScreenState extends State<PromocodesScreen> {
  List<dynamic> promocodes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getPromocodes();
  }

  void getPromocodes() async {
    final prefs = await SharedPreferences.getInstance();
    final url = Uri.parse('${dotenv.env['API_SERVER']}fetch_promocodes');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        setState(() {
          promocodes = responseBody['orders'] ?? [];
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
    }
    catch (e) {
      showAppSnackBar(context, 'Ошибка соединения');
      print('Ошибка соединения: $e');
      setState(() => isLoading = false);
    }
  }

  void _copyToClipboard(String promocode) {
    Clipboard.setData(ClipboardData(text: promocode));
    showAppSnackBar(context, 'Промокод "$promocode" скопирован');
  }

  void showAppSnackBar(BuildContext context, String message) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Акции',
            style: TextStyle(fontFamily: dotenv.env['APP_FONT_FAMILY'], fontSize: 24)),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : promocodes.isEmpty
          ? Center(child: Text('Нет доступных акций'))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: promocodes.length,
        itemBuilder: (context, index) {
          final promo = promocodes[index];
          return Card(
            margin: EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12)),
                  child: Image.network(
                    promo['src_img'],
                    headers: {
                      "Access-Control-Allow-Origin": "*",
                    },
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: Icon(Icons.image, size: 50),
                        ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Промокод: ${promo['promocode']}',
                              style: TextStyle(
                                fontFamily: dotenv.env['APP_FONT_FAMILY'],
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              promo['description'],
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontFamily: dotenv.env['APP_FONT_FAMILY'],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.content_copy,
                            color: Color.fromRGBO(10, 66, 51, 1)),
                        onPressed: () =>
                            _copyToClipboard(promo['promocode']),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}