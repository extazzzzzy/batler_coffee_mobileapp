import 'package:batler_app/MenuScreen.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:now/now.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> cartItems = [];
  int totalCartPrice = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getStringList('cart_items') ?? [];

    setState(() {
      cartItems = cartJson.map((item) => CartItem.fromJson(json.decode(item))).toList();
      totalCartPrice = cartItems.fold(0, (sum, item) => sum + item.totalPrice);
      isLoading = false;
    });
  }

  Future<void> _removeItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalCartPrice -= cartItems[index].totalPrice;
      cartItems.removeAt(index);
    });

    await prefs.setStringList(
      'cart_items',
      cartItems.map((item) => json.encode(item.toJson())).toList(),
    );
  }

  Future<void> _updateQuantity(int index, int newQuantity) async {
    if (newQuantity < 1) {
      _removeItem(index);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalCartPrice -= cartItems[index].totalPrice;

      // Рассчитываем новую цену с учетом количества
      int singleItemPrice = cartItems[index].basePrice;
      for (var ing in cartItems[index].selectedIngredients) {
        singleItemPrice += int.parse(ing['price']);
      }

      cartItems[index] = CartItem(
        productId: cartItems[index].productId,
        name: cartItems[index].name,
        imageUrl: cartItems[index].imageUrl,
        basePrice: cartItems[index].basePrice,
        quantity: newQuantity,
        selectedIngredients: cartItems[index].selectedIngredients,
        totalPrice: singleItemPrice * newQuantity,
      );

      totalCartPrice += cartItems[index].totalPrice;
    });

    await prefs.setStringList(
      'cart_items',
      cartItems.map((item) => json.encode(item.toJson())).toList(),
    );
  }

  void _showAppSnackBar(String message) {
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

  void _placeAnOrder() async {
    // Получаем время работы из .env
    final workingHoursFrom = dotenv.env['WORKING_HOURS_FROM'] ?? '10:00';
    final workingHoursUpTo = dotenv.env['WORKING_HOURS_UP_TO'] ?? '20:00';

    // Парсим время работы
    final fromTime = TimeOfDay(
      hour: int.parse(workingHoursFrom.split(':')[0]),
      minute: int.parse(workingHoursFrom.split(':')[1]),
    );
    final toTime = TimeOfDay(
      hour: int.parse(workingHoursUpTo.split(':')[0]),
      minute: int.parse(workingHoursUpTo.split(':')[1]),
    );

    // Генерируем временные интервалы
    final timeSlots = <String>['Как можно скорее'];
    var currentHour = fromTime.hour;
    var currentMinute = fromTime.minute;

    while (currentHour < toTime.hour ||
        (currentHour == toTime.hour && currentMinute < toTime.minute)) {
      final nextHour = currentMinute + 30 >= 60 ? currentHour + 1 : currentHour;
      final nextMinute = (currentMinute + 30) % 60;

      final startTime = TimeOfDay(hour: currentHour, minute: currentMinute);
      final endTime = TimeOfDay(hour: nextHour, minute: nextMinute);

      final now = DateTime.now();
      final slotStartTime = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      );

      if (slotStartTime.isAfter(now)) {
        timeSlots.add('${formatTimeOfDay24(startTime)} - ${formatTimeOfDay24(endTime)}');
      }

      currentHour = nextHour;
      currentMinute = nextMinute;
    }

    String? selectedTimeSlot = "Как можно скорее";
    String? promoCode;
    bool isPromoApplied = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Оформление заказа',
                style: TextStyle(
                  fontFamily: dotenv.env['APP_FONT_FAMILY'],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Список заказа
                    Text(
                      'Ваш заказ:',
                      style: TextStyle(
                        fontFamily: dotenv.env['APP_FONT_FAMILY'],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: cartItems.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '$index) ${item.name} ${item.basePrice}р'
                                '${item.selectedIngredients.isNotEmpty ? ' (' +
                                item.selectedIngredients.map((i) => '${i['name']} +${i['price']}р').join(', ') +
                                ')' : ''}: ${item.quantity}шт.',
                            style: TextStyle(
                              fontFamily: dotenv.env['APP_FONT_FAMILY'],
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Итоговая сумма: ${totalCartPrice}р',
                      style: TextStyle(
                        fontFamily: dotenv.env['APP_FONT_FAMILY'],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Выбор времени
                    Text(
                      'К какому времени приготовить?:',
                      style: TextStyle(
                        fontFamily: dotenv.env['APP_FONT_FAMILY'],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedTimeSlot,
                      items: timeSlots.map((slot) {
                        return DropdownMenuItem(
                          value: slot,
                          child: Text(
                            slot,
                            style: TextStyle(
                              fontFamily: dotenv.env['APP_FONT_FAMILY'],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTimeSlot = value;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Выберите время',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),

                    // Промокод
                    Text(
                      'Промокод:',
                      style: TextStyle(
                        fontFamily: dotenv.env['APP_FONT_FAMILY'],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Введите промокод',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onChanged: (value) {
                              promoCode = value;
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            isPromoApplied ? Icons.check_circle : Icons.arrow_forward,
                            color: isPromoApplied ? Colors.green : Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            // Здесь можно добавить проверку промокода
                            setState(() {
                              isPromoApplied = !isPromoApplied;
                              if (isPromoApplied) {
                                // Применить скидку (примерно 10%)
                                // В реальном приложении нужно проверять промокод на сервере
                                totalCartPrice = (totalCartPrice * 0.9).round();
                              } else {
                                // Вернуть исходную цену
                                _loadCartItems();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Отмена',
                    style: TextStyle(
                      fontFamily: dotenv.env['APP_FONT_FAMILY'],
                      color: Colors.black,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(10, 66, 51, 1),
                  ),
                  onPressed: selectedTimeSlot == null
                      ? null
                      : () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('cart_items');

                    _showAppSnackBar(
                      'Заказ оформлен на сумму $totalCartPriceр.\nВремя приготовления: $selectedTimeSlot',
                    );

                    setState(() {
                      cartItems = [];
                      totalCartPrice = 0;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Подтвердить',
                    style: TextStyle(
                      fontFamily: dotenv.env['APP_FONT_FAMILY'],
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String formatTimeOfDay24(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Корзина',
          style: TextStyle(
              fontFamily: dotenv.env['APP_FONT_FAMILY'],
              fontSize: 24
          ),
        ),
        centerTitle: true,
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('cart_items');
                setState(() {
                  cartItems = [];
                  totalCartPrice = 0;
                });
                _showAppSnackBar('Корзина очищена');
              },
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color.fromRGBO(10, 66, 51, 1)))
          : cartItems.isEmpty
          ? Center(
        child: Text(
          'Корзина пуста',
          style: TextStyle(
            fontFamily: dotenv.env['APP_FONT_FAMILY'],
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Dismissible(
                  key: Key(item.productId + index.toString()),
                  background: Container(color: Colors.red),
                  onDismissed: (direction) {
                    _removeItem(index);
                    _showAppSnackBar('Товар удален из корзины');
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.fastfood, color: Colors.grey),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.fastfood, color: Colors.grey),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontFamily: dotenv.env['APP_FONT_FAMILY'],
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${item.basePrice}р (базовая цена)',
                                  style: TextStyle(
                                    fontFamily: dotenv.env['APP_FONT_FAMILY'],
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (item.selectedIngredients.isNotEmpty) ...[
                                  SizedBox(height: 6),
                                  Text(
                                    'Дополнительно:',
                                    style: TextStyle(
                                      fontFamily: dotenv.env['APP_FONT_FAMILY'],
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 4,
                                    children: item.selectedIngredients.map((ingredient) {
                                      return Chip(
                                        label: Text(
                                          '${ingredient['name']} (+${ingredient['price']}р)',
                                          style: TextStyle(
                                            fontFamily: dotenv.env['APP_FONT_FAMILY'],
                                            fontSize: 10,
                                          ),
                                        ),
                                        labelPadding: EdgeInsets.symmetric(horizontal: -5),
                                        backgroundColor: Colors.green[50],
                                        visualDensity: VisualDensity.compact,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove, size: 20),
                                    onPressed: () {
                                      _updateQuantity(index, item.quantity - 1);
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    item.quantity.toString(),
                                    style: TextStyle(
                                      fontFamily: dotenv.env['APP_FONT_FAMILY'],
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(Icons.add, size: 20),
                                    onPressed: () {
                                      _updateQuantity(index, item.quantity + 1);
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${item.totalPrice}р',
                                style: TextStyle(
                                  fontFamily: dotenv.env['APP_FONT_FAMILY'],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(10, 66, 51, 1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Итого:',
                      style: TextStyle(
                        fontFamily: dotenv.env['APP_FONT_FAMILY'],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$totalCartPriceр',
                      style: TextStyle(
                        fontFamily: dotenv.env['APP_FONT_FAMILY'],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(10, 66, 51, 1),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      backgroundColor: Color.fromRGBO(10, 66, 51, 1),
                    ),
                    onPressed: () {
                      _placeAnOrder();
                      _showAppSnackBar('Заказ оформлен на сумму $totalCartPriceр');
                    },
                    child: Text(
                      'Оформить заказ',
                      style: TextStyle(
                        fontFamily: dotenv.env['APP_FONT_FAMILY'],
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}