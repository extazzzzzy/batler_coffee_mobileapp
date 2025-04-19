import 'package:batler_app/CartScreen.dart';
import 'package:batler_app/MenuScreen.dart';
import 'package:batler_app/ProfileUserScreen.dart';
import 'package:batler_app/PromocodesScreen.dart';
import 'package:batler_app/UserOrdersScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class UserProfileNavigator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: 'profile',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case 'profile':
            return MaterialPageRoute(builder: (_) => ProfileUserScreen());
          case 'orders':
            return MaterialPageRoute(builder: (_) => UserOrdersScreen());
          default:
            return MaterialPageRoute(builder: (_) => ProfileUserScreen());
        }
      },
    );
  }
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    MenuScreen(),
    CartScreen(),
    PromocodesScreen(),
    UserProfileNavigator(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildFancyNavBar(),
    );
  }


  Widget _buildFancyNavBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: _AnimatedNavIcon(icon: Icons.coffee, isSelected: _selectedIndex == 0),
                label: 'Меню'
            ),
            BottomNavigationBarItem(
                icon: _AnimatedNavIcon(icon: Icons.shopping_basket_rounded, isSelected: _selectedIndex == 1),
                label: 'Корзина'
            ),
            BottomNavigationBarItem(
                icon: _AnimatedNavIcon(icon: Icons.discount, isSelected: _selectedIndex == 2),
                label: 'Акции'
            ),
            BottomNavigationBarItem(
                icon: _AnimatedNavIcon(icon: Icons.person, isSelected: _selectedIndex == 3),
                label: 'Профиль'
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Color.fromRGBO(10, 66, 51, 1),
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedLabelStyle: TextStyle(
              fontFamily: dotenv.env['APP_FONT_FAMILY'],
              fontWeight: FontWeight.w600,
              fontSize: 12
          ),
          unselectedLabelStyle: TextStyle(
              fontFamily: dotenv.env['APP_FONT_FAMILY'],
              fontWeight: FontWeight.w500,
              fontSize: 12
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const _AnimatedNavIcon({required this.icon, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: isSelected ? Color(0xFF0A4233).withOpacity(0.1) : Colors.transparent,
          shape: BoxShape.circle
      ),
      child: Icon(icon, size: 26),
    );
  }
}