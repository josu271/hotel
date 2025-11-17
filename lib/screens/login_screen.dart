import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = false;

  Future<void> _login() async {
  setState(() => _isLoading = true);
  try {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // 📌 OBTENER EL ROL DEL USUARIO DESDE FIRESTORE
    final doc = await FirebaseFirestore.instance
        .collection('Usuario')
        .doc(credential.user!.uid)
        .get();

    final String rol = doc.data()?['Cargo'] ?? 'Cliente';

    // 👇 ENVIAR EL ROL AL HOME
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(userRole: rol),
      ),
    );

  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message ?? 'Error al iniciar sesión')),
    );
  }
  setState(() => _isLoading = false);
}



  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('Usuario')
          .doc(userCredential.user!.uid)
          .set({
        'Nombre': _nameController.text.trim(),
        'Apellido': _lastNameController.text.trim(),
        'Correo': _emailController.text.trim(),
        'Cargo': 'Cliente',
      });
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error al registrar')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'HOTEL ANDINO',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 30),
            if (_isRegistering) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _isRegistering ? _register : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B4513),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(_isRegistering ? 'Registrarse' : 'Iniciar Sesión'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          setState(() => _isRegistering = !_isRegistering);
                        },
                        child: Text(
                          _isRegistering
                              ? '¿Ya tienes cuenta? Inicia Sesión'
                              : '¿No tienes cuenta? Regístrate',
                          style: const TextStyle(color: Color(0xFF8B4513)),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}