import 'package:flutter/material.dart';

class EditTradePricesScreen extends StatefulWidget {
  final Map<String, List<String>> trade;
  final Map<String, double> prices; // Ejemplo: {'Jardín': 100.0, 'Plomería': 150.0}
  const EditTradePricesScreen({super.key, required this.trade, required this.prices});

  @override
  State<EditTradePricesScreen> createState() => _EditTradePricesScreenState();
}

class _EditTradePricesScreenState extends State<EditTradePricesScreen> {
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    widget.trade.keys.forEach((category) {
      _controllers[category] = TextEditingController(
        text: widget.prices[category]?.toString() ?? '',
      );
    });
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void _savePrices() {
    Map<String, double> newPrices = {};
    _controllers.forEach((key, controller) {
      final value = double.tryParse(controller.text);
      if (value != null) {
        newPrices[key] = value;
      }
    });
    // Aquí puedes guardar los precios en tu backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Precios guardados')),
    );
    Navigator.pop(context, newPrices);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar precios por categoría')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...widget.trade.keys.map((category) => Card(
                child: ListTile(
                  title: Text(category),
                  subtitle: TextField(
                    controller: _controllers[category],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Precio'),
                  ),
                ),
              )),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _savePrices,
            child: const Text('Guardar precios'),
          ),
        ],
      ),
    );
  }
}