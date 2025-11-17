import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'catalog_rooms_screen.dart';
import 'catalog_products_screen.dart';
import 'location_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'admin_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userRole;

  const HomeScreen({super.key, required this.userRole});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const LoginScreen();
    }

    // 👇 USAMOS EL ROL QUE VIENE DEL LOGIN O DEL MAIN
    final bool isEmpleado = widget.userRole == 'Empleado';

    final List<Widget> _screens = isEmpleado
        ? [
            CatalogRoomsScreen(),
            CatalogProductsScreen(),
            AdminScreen(),
            ProfileScreen(),
          ]
        : [
            CatalogRoomsScreen(),
            CatalogProductsScreen(),
            LocationScreen(),
            ProfileScreen(),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('HOTEL ANDINO'),
        backgroundColor: const Color(0xFF8B4513),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF8B4513),
        items: isEmpleado
            ? const [
                BottomNavigationBarItem(icon: Icon(Icons.hotel), label: 'Habitaciones'),
                BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Productos'),
                BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
              ]
            : const [
                BottomNavigationBarItem(icon: Icon(Icons.hotel), label: 'Habitaciones'),
                BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Productos'),
                BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Ubicación'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
              ],
      ),
    );
  }
}
