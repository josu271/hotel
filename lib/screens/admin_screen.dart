import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
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
  final _imageController = TextEditingController();
  bool _disponibilidad = true;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _nameController.text = widget.room!['Nombre'] ?? '';
      _descriptionController.text = widget.room!['Descripcion'] ?? '';
      _priceController.text = widget.room!['Precio']?.toString() ?? '';
      _numberController.text = widget.room!['Numero']?.toString() ?? '';
      _imageController.text = widget.room!['Url_image'] ?? '';
      _disponibilidad = widget.room!['Disponibilidad'] ?? true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _numberController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      
      // Mostrar instrucciones para subir a Drive
      _showDriveInstructions();
    }
  }

  void _showDriveInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subir imagen a Google Drive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Para usar esta imagen:'),
            const SizedBox(height: 10),
            const Text('1. Abre Google Drive en tu navegador'),
            const Text('2. Sube la imagen seleccionada a la carpeta:'),
            const Text('   https://drive.google.com/drive/folders/1295Dv0VGK6BfLmt5AEj5bPFkdlcc_Miy'),
            const SizedBox(height: 10),
            const Text('3. Haz clic derecho en la imagen'),
            const Text('4. Selecciona "Obtener enlace"'),
            const Text('5. Pega el enlace en el campo de abajo'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _imageController,
              decoration: const InputDecoration(
                labelText: 'Pega el enlace de Google Drive aquí',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
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
          title: const Text('Imagen seleccionada'),
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

  Future<void> _saveRoom() async {
    if (_formKey.currentState!.validate()) {
      try {
        final roomData = {
          'Nombre': _nameController.text.trim(),
          'Descripcion': _descriptionController.text.trim(),
          'Precio': double.parse(_priceController.text),
          'Numero': int.parse(_numberController.text),
          'Url_image': _imageController.text.trim(),
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
                'Imagen de la habitación:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Botón para seleccionar imagen
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Seleccionar imagen del dispositivo'),
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
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Imagen seleccionada (toca para ver más grande)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              
              const SizedBox(height: 16),
              const Text(
                'Pega el enlace de Google Drive:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(
                  labelText: 'URL de Google Drive',
                  hintText: 'https://drive.google.com/file/d/ABC123/view?usp=sharing',
                  helperText: 'Después de seleccionar la imagen, súbela a Drive y pega el enlace aquí',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una URL de Google Drive';
                  }
                  return null;
                },
              ),
              
              // Vista previa de la imagen desde Drive
              if (_imageController.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Vista previa desde Drive:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Image.network(
                  convertirEnlaceDriveADirecto(_imageController.text),
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 50),
                ),
              ],
              
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
  final _imageController = TextEditingController();
  String _categoria = 'Bebida';
  bool _disponibilidad = true;
  File? _selectedImage;

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
      _imageController.text = widget.product!['Url_image'] ?? '';
      _categoria = widget.product!['Categoria'] ?? 'Bebida';
      _disponibilidad = widget.product!['Disponibilidad'] ?? true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      
      // Mostrar instrucciones para subir a Drive
      _showDriveInstructions();
    }
  }

  void _showDriveInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subir imagen a Google Drive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Para usar esta imagen:'),
            const SizedBox(height: 10),
            const Text('1. Abre Google Drive en tu navegador'),
            const Text('2. Sube la imagen seleccionada a la carpeta:'),
            const Text('   https://drive.google.com/drive/folders/1295Dv0VGK6BfLmt5AEj5bPFkdlcc_Miy'),
            const SizedBox(height: 10),
            const Text('3. Haz clic derecho en la imagen'),
            const Text('4. Selecciona "Obtener enlace"'),
            const Text('5. Pega el enlace en el campo de abajo'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _imageController,
              decoration: const InputDecoration(
                labelText: 'Pega el enlace de Google Drive aquí',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
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
          title: const Text('Imagen seleccionada'),
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

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        final productData = {
          'Nombre': _nameController.text.trim(),
          'Precio': double.parse(_priceController.text),
          'Stock': int.parse(_stockController.text),
          'Categoria': _categoria,
          'Url_image': _imageController.text.trim(),
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
                'Imagen del producto:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Botón para seleccionar imagen
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Seleccionar imagen del dispositivo'),
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
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Imagen seleccionada (toca para ver más grande)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              
              const SizedBox(height: 16),
              const Text(
                'Pega el enlace de Google Drive:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(
                  labelText: 'URL de Google Drive',
                  hintText: 'https://drive.google.com/file/d/ABC123/view?usp=sharing',
                  helperText: 'Después de seleccionar la imagen, súbela a Drive y pega el enlace aquí',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una URL de Google Drive';
                  }
                  return null;
                },
              ),
              
              // Vista previa de la imagen desde Drive
              if (_imageController.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Vista previa desde Drive:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Image.network(
                  convertirEnlaceDriveADirecto(_imageController.text),
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 50),
                ),
              ],
              
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