import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  void _showRoomDetail(Map<String, dynamic> room) {
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
              // Agregar al carrito
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
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _showRoomDetail(room),
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