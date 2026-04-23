import 'package:flutter/material.dart';
import 'sidebar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(), // Ne pas toucher le sidebar
          Expanded(
            child: Container(
              color: const Color(0xfff6f7fb), // Couleur de fond ici
              child: child, // Contenu principal
            ),
          ),
        ],
      ),
    );
  }
}
