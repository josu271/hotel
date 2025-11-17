import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../cart_provider.dart';
import 'login_screen.dart';

class CatalogRoomsScreen extends StatefulWidget {
  const CatalogRoomsScreen({super.key});

  @override
  State<CatalogRoomsScreen> createState() => _CatalogRoomsScreenState();
}

class _CatalogRoomsScreenState extends State<CatalogRoomsScreen> {
  List<Map<String, dynamic>> rooms = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _getRooms();
  }

  Future<void> _getRooms() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Habitacion')
          .where('Disponibilidad', isEqualTo: true)
          .get();

      setState(() {
        rooms = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();
      });
    } catch (e) {
      print('Error al obtener habitaciones: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredRooms {
    if (_searchQuery.isEmpty) {
      return rooms;
    }
    return rooms.where((room) {
      return room['Nombre'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             room['Descripcion'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _convertirEnlaceDriveADirecto(String enlaceDrive) {
    final regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regExp.firstMatch(enlaceDrive);
    if (match != null && match.groupCount >= 1) {
      final id = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$id';
    } else {
      return enlaceDrive;
    }
  }

  void _addToCart(BuildContext context, Map<String, dynamic> room) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    // Si no está logueado, redirigir al login
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    final cartItem = CartItem(
      id: room['id'],
      name: room['Nombre'],
      price: (room['Precio'] as num).toDouble(),
      quantity: 1,
      type: 'habitacion',
      imageUrl: room['Url_image'] ?? '',
      details: {
        'numero': room['Numero'],
        'descripcion': room['Descripcion'],
      },
    );

    cartProvider.addItem(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${room['Nombre']} agregado al carrito'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRoomDetail(BuildContext context, Map<String, dynamic> room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(room['Nombre']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                _convertirEnlaceDriveADirecto(room['Url_image'] ?? ''),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.broken_image, size: 100),
              ),
              const SizedBox(height: 10),
              Text('Descripción: ${room['Descripcion']}'),
              Text('Precio: S/ ${room['Precio']}'),
              Text('Número: ${room['Numero']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              _addToCart(context, room);
              Navigator.pop(context);
            },
            child: const Text('Agregar al Carrito'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                labelText: 'Buscar habitaciones',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredRooms.isEmpty
                ? const Center(child: Text('No hay habitaciones disponibles'))
                : ListView.builder(
                    itemCount: _filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = _filteredRooms[index];
                      final imageUrl = _convertirEnlaceDriveADirecto(room['Url_image'] ?? '');
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.hotel, size: 40),
                          ),
                          title: Text(room['Nombre']),
                          subtitle: Text('S/ ${room['Precio']} por noche'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_shopping_cart),
                            onPressed: () => _addToCart(context, room),
                          ),
                          onTap: () => _showRoomDetail(context, room),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}