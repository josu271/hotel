import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../cart_provider.dart';
import 'login_screen.dart';

class CatalogProductsScreen extends StatefulWidget {
  const CatalogProductsScreen({super.key});

  @override
  State<CatalogProductsScreen> createState() => _CatalogProductsScreenState();
  
}

class _CatalogProductsScreenState extends State<CatalogProductsScreen> {
  List<Map<String, dynamic>> products = [];
  String _searchQuery = '';
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _getProducts();
  }

  Future<void> _getProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Producto')
          .where('Disponibilidad', isEqualTo: true)
          .get();

      setState(() {
        products = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();
      });
    } catch (e) {
      print('Error al obtener productos: $e');
    }
  }
  

  List<Map<String, dynamic>> get _filteredProducts {
    var filtered = products;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product['Nombre'].toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    if (_selectedCategory.isNotEmpty) {
      filtered = filtered.where((product) {
        return product['Categoria'] == _selectedCategory;
      }).toList();
    }
    
    return filtered;
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

  void _addToCart(BuildContext context, Map<String, dynamic> product) {
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
      id: product['id'],
      name: product['Nombre'],
      price: (product['Precio'] as num).toDouble(),
      quantity: 1,
      type: 'producto',
      imageUrl: product['Url_image'] ?? '',
      details: {
        'categoria': product['Categoria'],
        'stock': product['Stock'],
      },
    );

    cartProvider.addItem(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['Nombre']} agregado al carrito'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  

  void _showProductDetail(BuildContext context, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['Nombre']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                _convertirEnlaceDriveADirecto(product['Url_image'] ?? ''),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.broken_image, size: 100),
              ),
              const SizedBox(height: 10),
              Text('Categoría: ${product['Categoria']}'),
              Text('Precio: S/ ${product['Precio']}'),
              Text('Stock: ${product['Stock']}'),
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
              _addToCart(context, product);
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
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    labelText: 'Buscar productos',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory.isEmpty ? null : _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Todas las categorías')),
                    DropdownMenuItem(value: 'Bebida', child: Text('Bebida')),
                    DropdownMenuItem(value: 'Aseo', child: Text('Aseo')),
                    DropdownMenuItem(value: 'Alimentos', child: Text('Alimentos')),
                    DropdownMenuItem(value: 'Licores', child: Text('Licores')),
                  ],
                  onChanged: (value) => setState(() => _selectedCategory = value ?? ''),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredProducts.isEmpty
                ? const Center(child: Text('No hay productos disponibles'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      final imageUrl = _convertirEnlaceDriveADirecto(product['Url_image'] ?? '');
                      
                      return Card(
                        child: InkWell(
                          onTap: () => _showProductDetail(context, product),
                          child: Column(
                            children: [
                              Expanded(
                                child: Image.network(
                                  imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => 
                                    const Icon(Icons.shopping_bag, size: 50),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text(
                                      product['Nombre'],
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text('S/ ${product['Precio']}'),
                                    IconButton(
                                      icon: const Icon(Icons.add_shopping_cart),
                                      onPressed: () => _addToCart(context, product),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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