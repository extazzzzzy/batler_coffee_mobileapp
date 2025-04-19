import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String productId;
  final String name;
  final String imageUrl;
  final int basePrice;
  final int quantity;
  final List<dynamic> selectedIngredients;
  final int totalPrice;
  final String weight;

  CartItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.basePrice,
    required this.quantity,
    required this.selectedIngredients,
    required this.totalPrice,
    required this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'basePrice': basePrice,
      'quantity': quantity,
      'selectedIngredients': selectedIngredients,
      'totalPrice': totalPrice,
      'weight': weight,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      basePrice: json['basePrice'],
      quantity: json['quantity'],
      selectedIngredients: json['selectedIngredients'],
      totalPrice: json['totalPrice'],
      weight: json['weight'],
    );
  }
}

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<dynamic> menuItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getMenuData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> addToCart(dynamic product, Set<dynamic> selectedIngredients, int totalPrice) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartKey = 'cart_items';

      final cartJson = prefs.getStringList(cartKey) ?? [];
      List<CartItem> cartItems = cartJson.map((item) => CartItem.fromJson(json.decode(item))).toList();

      bool itemExists = false;
      for (int i = 0; i < cartItems.length; i++) {
        if (cartItems[i].productId == product['id'].toString() &&
            _areIngredientsEqual(cartItems[i].selectedIngredients, selectedIngredients.toList())) {
          cartItems[i] = CartItem(
            productId: cartItems[i].productId,
            name: cartItems[i].name,
            imageUrl: cartItems[i].imageUrl,
            basePrice: cartItems[i].basePrice,
            quantity: cartItems[i].quantity + 1,
            selectedIngredients: cartItems[i].selectedIngredients,
            totalPrice: cartItems[i].totalPrice + (totalPrice - int.parse(product['price'])),
            weight: cartItems[i].weight,
          );
          itemExists = true;
          break;
        }
      }

      if (!itemExists) {
        cartItems.add(CartItem(
          productId: product['id'].toString(),
          name: product['name'],
          imageUrl: product['src_img'],
          basePrice: int.parse(product['price']),
          quantity: 1,
          selectedIngredients: selectedIngredients.toList(),
          totalPrice: totalPrice,
          weight: product['weight'],
        ));
      }

      await prefs.setStringList(
        cartKey,
        cartItems.map((item) => json.encode(item.toJson())).toList(),
      );
      showAppSnackBar(context, 'Товар добавлен в корзину');
      Navigator.pop(context);
    } catch (e) {
      showAppSnackBar(context, 'Ошибка при добавлении в корзину');
      print('Ошибка добавления в корзину: $e');
    }
  }

  bool _areIngredientsEqual(List<dynamic> ingredients1, List<dynamic> ingredients2) {
    if (ingredients1.length != ingredients2.length) return false;

    for (var ing1 in ingredients1) {
      bool found = false;
      for (var ing2 in ingredients2) {
        if (ing1['id'] == ing2['id']) {
          found = true;
          break;
        }
      }
      if (!found) return false;
    }

    return true;
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
        duration: Duration(seconds: 2),
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

  void getMenuData() async {
    final url = Uri.parse('${dotenv.env['API_SERVER']}fetch_products');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        setState(() {
          menuItems = data['products'];
          isLoading = false;
        });
      }
      else {
        showAppSnackBar(context, 'Ошибка загрузки меню');
      }
    }
    catch (e) {
      showAppSnackBar(context, 'Ошибка соединения');
    }
  }

  void _showProductDetails(BuildContext context, dynamic product) {
    final basePrice = int.parse(product['price']);
    Set<dynamic> selectedIngredients = {};
    int totalPrice = basePrice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: product['src_img'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(  // или Expanded
                        child: AutoSizeText(
                          product['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: dotenv.env['APP_FONT_FAMILY'],
                          ),
                          minFontSize: 10,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${totalPrice}р',
                        style: TextStyle(
                          fontSize: 24,
                          color: Color.fromRGBO(10, 66, 51, 1),
                          fontFamily: dotenv.env['APP_FONT_FAMILY'],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Text(
                    product['description'],
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontFamily: dotenv.env['APP_FONT_FAMILY']),
                  ),
                  Divider(height: 40),
                  _buildDetailItem('Состав', product['composition']),
                  _buildDetailItem('Масса нетто/Объём', product['weight']),
                  _buildNutritionRow(
                    double.tryParse(product['protein']?.toString() ?? '0') ?? 0,
                    double.tryParse(product['fats']?.toString() ?? '0') ?? 0,
                    double.tryParse(product['carbohydrates']?.toString() ?? '0') ?? 0,
                    int.tryParse(product['kilocalories']?.toString() ?? '0') ?? 0,
                  ),

                  // Блок с дополнительными ингредиентами
                  if (product['ingredients'] != null && product['ingredients'].isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(height: 40),
                        Text('Дополнительные ингредиенты:',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: dotenv.env['APP_FONT_FAMILY'])),
                        Column(
                          children: product['ingredients'].map<Widget>((ingredient) {
                            return CheckboxListTile(
                              title: Text(ingredient['name'],
                                  style: TextStyle(fontFamily: dotenv.env['APP_FONT_FAMILY'])),
                              subtitle: Text('+${ingredient['price']}р',
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontFamily: dotenv.env['APP_FONT_FAMILY'])),
                              value: selectedIngredients.contains(ingredient),
                              onChanged: (bool? value) {
                                setModalState(() {
                                  if (value == true) {
                                    selectedIngredients.add(ingredient);
                                    totalPrice += int.parse(ingredient['price']);
                                  } else {
                                    selectedIngredients.remove(ingredient);
                                    totalPrice -= int.parse(ingredient['price']);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Итоговая стоимость: ${totalPrice}р',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontFamily: dotenv.env['APP_FONT_FAMILY']),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        backgroundColor: Color.fromRGBO(10, 66, 51, 1),
                      ),
                      onPressed: () {
                        addToCart(product, selectedIngredients, totalPrice);
                      },
                      child: Text(
                        'Добавить в корзину',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontFamily: dotenv.env['APP_FONT_FAMILY']),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: dotenv.env['APP_FONT_FAMILY'])),
          Text(value,
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: dotenv.env['APP_FONT_FAMILY'])),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(double protein, double fats, double carbs, int kcal) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.brown[50],
          borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNutritionCircle('Б', '${protein}г', Colors.orange),
          _buildNutritionCircle('Ж', '${fats}г', Colors.red),
          _buildNutritionCircle('У', '${carbs}г', Colors.green),
          _buildNutritionCircle('Ккал', '$kcal', Colors.brown),
        ],
      ),
    );
  }

  Widget _buildNutritionCircle(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle),
          child: Center(
            child: Text(value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, fontFamily: dotenv.env['APP_FONT_FAMILY'])),
          ),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: dotenv.env['APP_FONT_FAMILY'])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Меню',
            style: TextStyle(fontFamily: dotenv.env['APP_FONT_FAMILY'], fontSize: 24)),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color.fromRGBO(10, 66, 51, 1)))
          : GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return GestureDetector(
            onTap: item['is_available']
                ? () => _showProductDetails(context, item)
                : null,
            child: Stack(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          child: CachedNetworkImage(
                            imageUrl: item['src_img'],
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                Icon(Icons.coffee, size: 50, color: Colors.brown),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AutoSizeText(
                                    item['name'],
                                    style: TextStyle(
                                      fontSize: 16,  // это будет максимальный размер
                                      fontWeight: FontWeight.bold,
                                      fontFamily: dotenv.env['APP_FONT_FAMILY'],
                                    ),
                                    minFontSize: 10,  // минимальный размер, до которого будет уменьшаться текст
                                    maxLines: 3,     // количество строк (можно увеличить при необходимости)
                                    overflow: TextOverflow.ellipsis,  // что делать, если текст не помещается
                                    softWrap: true,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_shopping_cart, color: Colors.black),
                                  onPressed: () => _showProductDetails(context, item),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item['weight'],
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14, fontFamily: dotenv.env['APP_FONT_FAMILY'])),
                                Text('${item['price']}р',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: dotenv.env['APP_FONT_FAMILY'],
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!item['is_available']) Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20)),
                    child: Center(
                      child: Text('Нет в наличии',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: dotenv.env['APP_FONT_FAMILY'],
                              fontWeight: FontWeight.bold)),
                    ),
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