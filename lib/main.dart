import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String> _getUserRole(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('Usuario')
        .doc(uid)
        .get();

    return doc.data()?['Cargo'] ?? 'Cliente';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartProvider()..loadCart(), // <- Cargar carrito al crear
      child: MaterialApp(
        title: 'Hotel Andino',
        theme: ThemeData(
          primarySwatch: Colors.brown,
          colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.amber),
          fontFamily: 'Poppins',
        ),
        debugShowCheckedModeBanner: false,

        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData) {
              return const LoginScreen();
            }

            final uid = snapshot.data!.uid;

            return FutureBuilder<String>(
              future: _getUserRole(uid),
              builder: (context, roleSnapshot) {
                
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final role = roleSnapshot.data ?? 'Cliente';

                return HomeScreen(userRole: role);
              },
            );
          },
        ),
      ),
    );
  }
}