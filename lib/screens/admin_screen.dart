import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Administración'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.hotel), text: 'Habitaciones'),
              Tab(icon: Icon(Icons.shopping_bag), text: 'Productos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RoomsManagementScreen(),
            ProductsManagementScreen(),
          ],
        ),
      ),
    );
  }
}

// Función para convertir enlace de Drive a enlace directo
String convertirEnlaceDriveADirecto(String enlaceDrive) {
  final regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
  final match = regExp.firstMatch(enlaceDrive);
  if (match != null && match.groupCount >= 1) {
    final id = match.group(1);
    return 'https://drive.google.com/uc?export=view&id=$id';
  } else {
    return enlaceDrive;
  }
}

// Configuración de URLs de Drive para las imágenes
class DriveConfig {
  // URLs de las imágenes en tu carpeta de Drive
  static const Map<String, String> imageUrls = {
    'habitacion_standard': 'https://drive.google.com/file/d/1q0n9Y8Qw8X6Z5a6rT7sBc3dE4fG5hJ6K/view?usp=sharing',
    'habitacion_suite': 'https://drive.google.com/file/d/1r1oA0X9Y9W8Y7z5b4uT8dC4eF5gI7L9M/view?usp=sharing',
    'habitacion_doble': 'https://drive.google.com/file/d/1s2pB1Y0Z0X9X8a7vU9eD5fG6hJ8N0O/view?usp=sharing',
    'producto_bebida': 'https://drive.google.com/file/d/1t3qC2Z1A1Y0Y9b5wV0fE6gH7kK9P1P/view?usp=sharing',
    'producto_comida': 'https://drive.google.com/file/d/1u4rD3B2B2Z1Z0c6xW1gF7hI8lL0Q2Q/view?usp=sharing',
    'producto_aseo': 'https://drive.google.com/file/d/1v5sE4C3C3A2A1d7yX2hG8jM9mR3R3/view?usp=sharing',
    'producto_licor': 'https://drive.google.com/file/d/1w6tF5D4D4B3B2e8zY3iH9kN0nS4S4/view?usp=sharing',
  };
  
  static String getRoomImageUrl(String roomName, double price) {
    roomName = roomName.toLowerCase();
    
    if (roomName.contains('suite') || roomName.contains('presidencial') || roomName.contains('lujo') || price > 200) {
      return imageUrls['habitacion_suite']!;
    } else if (roomName.contains('doble') || roomName.contains('familiar')) {
      return imageUrls['habitacion_doble']!;
    } else {
      return imageUrls['habitacion_standard']!;
    }
  }
  
  static String getProductImageUrl(String category) {
    switch (category.toLowerCase()) {
      case 'bebida':
        return imageUrls['producto_bebida']!;
      case 'alimentos':
        return imageUrls['producto_comida']!;
      case 'aseo':
        return imageUrls['producto_aseo']!;
      case 'licores':
        return imageUrls['producto_licor']!;
      default:
        return imageUrls['producto_bebida']!;
    }
  }
}

// Pantalla para gestionar habitaciones
class RoomsManagementScreen extends StatefulWidget {
  const RoomsManagementScreen({super.key});

  @override
  State<RoomsManagementScreen> createState() => _RoomsManagementScreenState();
}

class _RoomsManagementScreenState extends State<RoomsManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final snapshot = await _firestore.collection('Habitacion').get();
      setState(() {
        _rooms.clear();
        _rooms.addAll(snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }));
      });
    } catch (e) {
      print('Error al cargar habitaciones: $e');
    }
  }

  void _showRoomForm({Map<String, dynamic>? room}) {
    showDialog(
      context: context,
      builder: (context) => RoomFormDialog(
        room: room,
        onSaved: _loadRooms,
      ),
    );
  }

  Future<void> _deleteRoom(String roomId) async {
    try {
      await _firestore.collection('Habitacion').doc(roomId).delete();
      _loadRooms();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habitación eliminada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showRoomForm(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Habitación'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        Expanded(
          child: _rooms.isEmpty
              ? const Center(child: Text('No hay habitaciones registradas'))
              : ListView.builder(
                  itemCount: _rooms.length,
                  itemBuilder: (context, index) {
                    final room = _rooms[index];
                    final urlImagenDirecta = convertirEnlaceDriveADirecto(room['Url_image'] ?? '');
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: room['Url_image']?.isNotEmpty == true
                            ? Image.network(
                                urlImagenDirecta,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.hotel, size: 40),
                              )
                            : const Icon(Icons.hotel, size: 40),
                        title: Text(room['Nombre']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('S/ ${room['Precio']}'),
                            Text('Número: ${room['Numero']}'),
                            Text('Disponible: ${room['Disponibilidad'] == true ? 'Sí' : 'No'}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showRoomForm(room: room),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar Habitación'),
                                    content: const Text('¿Estás seguro de que quieres eliminar esta habitación?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteRoom(room['id']);
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// Pantalla para gestionar productos
class ProductsManagementScreen extends StatefulWidget {
  const ProductsManagementScreen({super.key});

  @override
  State<ProductsManagementScreen> createState() => _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends State<ProductsManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final snapshot = await _firestore.collection('Producto').get();
      setState(() {
        _products.clear();
        _products.addAll(snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }));
      });
    } catch (e) {
      print('Error al cargar productos: $e');
    }
  }

  void _showProductForm({Map<String, dynamic>? product}) {
    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(
        product: product,
        onSaved: _loadProducts,
      ),
    );
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await _firestore.collection('Producto').doc(productId).delete();
      _loadProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto eliminado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showProductForm(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Producto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        Expanded(
          child: _products.isEmpty
              ? const Center(child: Text('No hay productos registrados'))
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final urlImagenDirecta = convertirEnlaceDriveADirecto(product['Url_image'] ?? '');
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: product['Url_image']?.isNotEmpty == true
                            ? Image.network(
                                urlImagenDirecta,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.shopping_bag, size: 40),
                              )
                            : const Icon(Icons.shopping_bag, size: 40),
                        title: Text(product['Nombre']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('S/ ${product['Precio']}'),
                            Text('Categoría: ${product['Categoria']}'),
                            Text('Stock: ${product['Stock']}'),
                            Text('Disponible: ${product['Disponibilidad'] == true ? 'Sí' : 'No'}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showProductForm(product: product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar Producto'),
                                    content: const Text('¿Estás seguro de que quieres eliminar este producto?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteProduct(product['id']);
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// Diálogo para formulario de habitaciones
class RoomFormDialog extends StatefulWidget {
  final Map<String, dynamic>? room;
  final VoidCallback onSaved;

  const RoomFormDialog({
    super.key,
    this.room,
    required this.onSaved,
  });

  @override
  State<RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<RoomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _numberController = TextEditingController();
  bool _disponibilidad = true;
  File? _selectedImage;
  bool _imageSelected = false;

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _nameController.text = widget.room!['Nombre'] ?? '';
      _descriptionController.text = widget.room!['Descripcion'] ?? '';
      _priceController.text = widget.room!['Precio']?.toString() ?? '';
      _numberController.text = widget.room!['Numero']?.toString() ?? '';
      _disponibilidad = widget.room!['Disponibilidad'] ?? true;
      _imageSelected = widget.room!['Url_image']?.isNotEmpty == true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
  try {
    // El image_picker maneja automáticamente los permisos en versiones recientes
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _imageSelected = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagen seleccionada como referencia'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    print('Error al seleccionar imagen: $e');
    
    // Si hay error de permisos, mostrar diálogo
    if (e.toString().contains('PERMISSION') || e.toString().contains('permission')) {
      _showPermissionDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al seleccionar imagen')),
      );
    }
  }
}

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso requerido'),
        content: const Text('Para seleccionar imágenes, necesitas permitir el acceso a la galería en la configuración de la aplicación.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Abrir configuración'),
          ),
        ],
      ),
    );
  }

  void _showImagePreview() {
    if (_selectedImage != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Imagen de referencia'),
          content: Image.file(_selectedImage!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  // Obtener URL de imagen basada en el tipo y nombre
  String _getImageUrl() {
    if (widget.room != null && widget.room!['Url_image']?.isNotEmpty == true) {
      return widget.room!['Url_image'];
    }
    
    // Asignar URL basada en el nombre de la habitación y precio
    double price = double.tryParse(_priceController.text) ?? 0;
    return DriveConfig.getRoomImageUrl(_nameController.text.trim(), price);
  }

  Future<void> _saveRoom() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Obtener la URL de la imagen (automáticamente)
        String imageUrl = _getImageUrl();

        final roomData = {
          'Nombre': _nameController.text.trim(),
          'Descripcion': _descriptionController.text.trim(),
          'Precio': double.parse(_priceController.text),
          'Numero': int.parse(_numberController.text),
          'Url_image': imageUrl,
          'Disponibilidad': _disponibilidad,
        };

        if (widget.room != null) {
          // Actualizar habitación existente
          await FirebaseFirestore.instance
              .collection('Habitacion')
              .doc(widget.room!['id'])
              .update(roomData);
        } else {
          // Crear nueva habitación
          await FirebaseFirestore.instance
              .collection('Habitacion')
              .add(roomData);
        }

        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.room != null ? 'Habitación actualizada' : 'Habitación creada')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String previewImageUrl = _getImageUrl();
    
    return AlertDialog(
      title: Text(widget.room != null ? 'Editar Habitación' : 'Nueva Habitación'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre de la habitación'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Precio por noche'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor ingresa un número válido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: 'Número de habitación'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un número';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor ingresa un número válido';
                  }
                  return null;
                },
              ),
              
              // Sección para imagen
              const SizedBox(height: 16),
              const Text(
                'Imagen de referencia (opcional):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Botón para seleccionar imagen
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Seleccionar imagen de referencia'),
              ),
              
              // Mostrar vista previa de imagen seleccionada
              if (_selectedImage != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showImagePreview,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Imagen de referencia seleccionada',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
              
              // Vista previa de la imagen que se usará
              const SizedBox(height: 16),
              const Text(
                'Imagen que se mostrará en la app:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.network(
                  convertirEnlaceDriveADirecto(previewImageUrl),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Imagen\npredeterminada', 
                               textAlign: TextAlign.center, 
                               style: TextStyle(fontSize: 12)),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Imagen automática basada en el tipo de habitación',
                style: TextStyle(fontSize: 12, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
              
              SwitchListTile(
                title: const Text('Disponible'),
                value: _disponibilidad,
                onChanged: (value) {
                  setState(() {
                    _disponibilidad = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveRoom,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// Diálogo para formulario de productos
class ProductFormDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final VoidCallback onSaved;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.onSaved,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  String _categoria = 'Bebida';
  bool _disponibilidad = true;
  File? _selectedImage;
  bool _imageSelected = false;

  final List<String> _categorias = [
    'Bebida',
    'Aseo',
    'Alimentos',
    'Licores'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!['Nombre'] ?? '';
      _priceController.text = widget.product!['Precio']?.toString() ?? '';
      _stockController.text = widget.product!['Stock']?.toString() ?? '';
      _categoria = widget.product!['Categoria'] ?? 'Bebida';
      _disponibilidad = widget.product!['Disponibilidad'] ?? true;
      _imageSelected = widget.product!['Url_image']?.isNotEmpty == true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Verificar y solicitar permisos
      PermissionStatus status = await Permission.photos.status;
      
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }
      
      if (status.isGranted) {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        
        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
            _imageSelected = true;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen seleccionada como referencia'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (status.isPermanentlyDenied) {
        // Mostrar diálogo para ir a configuración
        _showPermissionDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso denegado para acceder a la galería')),
        );
      }
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al seleccionar imagen')),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso requerido'),
        content: const Text('Para seleccionar imágenes, necesitas permitir el acceso a la galería en la configuración de la aplicación.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Abrir configuración'),
          ),
        ],
      ),
    );
  }

  void _showImagePreview() {
    if (_selectedImage != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Imagen de referencia'),
          content: Image.file(_selectedImage!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  // Obtener URL de imagen basada en la categoría
  String _getImageUrl() {
    if (widget.product != null && widget.product!['Url_image']?.isNotEmpty == true) {
      return widget.product!['Url_image'];
    }
    
    // Asignar URL basada en la categoría
    return DriveConfig.getProductImageUrl(_categoria);
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Obtener la URL de la imagen (automáticamente)
        String imageUrl = _getImageUrl();

        final productData = {
          'Nombre': _nameController.text.trim(),
          'Precio': double.parse(_priceController.text),
          'Stock': int.parse(_stockController.text),
          'Categoria': _categoria,
          'Url_image': imageUrl,
          'Disponibilidad': _disponibilidad,
        };

        if (widget.product != null) {
          // Actualizar producto existente
          await FirebaseFirestore.instance
              .collection('Producto')
              .doc(widget.product!['id'])
              .update(productData);
        } else {
          // Crear nuevo producto
          await FirebaseFirestore.instance
              .collection('Producto')
              .add(productData);
        }

        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.product != null ? 'Producto actualizado' : 'Producto creado')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String previewImageUrl = _getImageUrl();
    
    return AlertDialog(
      title: Text(widget.product != null ? 'Editar Producto' : 'Nuevo Producto'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre del producto'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor ingresa un número válido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el stock';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor ingresa un número válido';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _categoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categorias.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoria = value!;
                  });
                },
              ),
              
              // Sección para imagen
              const SizedBox(height: 16),
              const Text(
                'Imagen de referencia (opcional):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Botón para seleccionar imagen
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Seleccionar imagen de referencia'),
              ),
              
              // Mostrar vista previa de imagen seleccionada
              if (_selectedImage != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showImagePreview,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Imagen de referencia seleccionada',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
              
              // Vista previa de la imagen que se usará
              const SizedBox(height: 16),
              const Text(
                'Imagen que se mostrará en la app:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.network(
                  convertirEnlaceDriveADirecto(previewImageUrl),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Imagen\npredeterminada', 
                               textAlign: TextAlign.center, 
                               style: TextStyle(fontSize: 12)),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Imagen automática basada en la categoría',
                style: TextStyle(fontSize: 12, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
              
              SwitchListTile(
                title: const Text('Disponible'),
                value: _disponibilidad,
                onChanged: (value) {
                  setState(() {
                    _disponibilidad = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveProduct,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}