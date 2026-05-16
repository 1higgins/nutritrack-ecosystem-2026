import 'package:flutter/material.dart';

class TemperaturaPage extends StatelessWidget {
  const TemperaturaPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Temperatura')),
    body: const Center(child: Text('Monitoreo de temperatura')),
  );
}
