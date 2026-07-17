import 'package:flutter/material.dart';

class GtechHomePage extends StatelessWidget {
  const GtechHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gtech')),
      body: const Center(child: Text('MVP: painel Gtech')),
    );
  }
}

