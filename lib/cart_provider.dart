import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final String type; // 'habitacion' o 'producto'
  final String imageUrl;
  final Map<String, dynamic> details;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.type,
    required this.imageUrl,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'type': type,
      'imageUrl': imageUrl,
      'details': details,
    };
  }

  static CartItem fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'],
      type: map['type'],
      imageUrl: map['imageUrl'],
      details: Map<String, dynamic>.from(map['details']),
    );
  }
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<CartItem> get items => _items;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  // Cargar carrito desde Firebase
  Future<void> loadCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('carritos')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final itemsData = data['items'] as List<dynamic>;
        
        _items.clear();
        _items.addAll(
          itemsData.map((itemData) => CartItem.fromMap(Map<String, dynamic>.from(itemData)))
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error al cargar carrito: $e');
    }
  }

  // Guardar carrito en Firebase
  Future<void> _saveCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('carritos')
          .doc(user.uid)
          .set({
            'items': _items.map((item) => item.toMap()).toList(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error al guardar carrito: $e');
    }
  }

  void addItem(CartItem newItem) {
    final index = _items.indexWhere((item) => item.id == newItem.id && item.type == newItem.type);
    
    if (index >= 0) {
      _items[index].quantity += 1;
    } else {
      _items.add(newItem);
    }
    notifyListeners();
    _saveCart();
  }

  void removeItem(String id, String type) {
    _items.removeWhere((item) => item.id == id && item.type == type);
    notifyListeners();
    _saveCart();
  }

  void updateQuantity(String id, String type, int quantity) {
    final index = _items.indexWhere((item) => item.id == id && item.type == type);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
      _saveCart();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
    _saveCart();
  }

  // Procesar la compra final
  Future<void> processPurchase() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // Crear la orden de compra
    final orderData = {
      'userId': user.uid,
      'items': _items.map((item) => item.toMap()).toList(),
      'total': totalPrice,
      'status': 'pendiente',
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      // Guardar la orden en la colección 'ordenes'
      await _firestore.collection('ordenes').add(orderData);
      
      // Actualizar stock de productos
      for (final item in _items) {
        if (item.type == 'producto') {
          await _firestore
              .collection('Producto')
              .doc(item.id)
              .update({
                'Stock': FieldValue.increment(-item.quantity)
              });
        } else if (item.type == 'habitacion') {
          // Marcar habitación como no disponible
          await _firestore
              .collection('Habitacion')
              .doc(item.id)
              .update({
                'Disponibilidad': false
              });
        }
      }
      
      // Limpiar carrito después de la compra
      clearCart();
      
    } catch (e) {
      print('Error al procesar compra: $e');
      throw Exception('Error al procesar la compra');
    }
  }
}