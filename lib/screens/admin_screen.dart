import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                // Navegar a pantalla para agregar/editar habitaciones
              },
              child: const Text('Gestionar Habitaciones'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navegar a pantalla para agregar/editar productos
              },
              child: const Text('Gestionar Productos'),
            ),
          ],
        ),
      ),
    );
  }
}