import 'package:flutter/material.dart';

void main() => runApp(const BishopPayApp());

class BishopPayApp extends StatelessWidget {
  const BishopPayApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Bishop Pay',
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: const HomePage(),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bishop Pay')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Available Balance'),
        const SizedBox(height: 8),
        Text('₦0.00', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 12),
        FilledButton(onPressed: () {}, child: const Text('Add Money')),
      ]))),
      const SizedBox(height: 16),
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: const [
        ActionTile(icon: Icons.send, label: 'Send Money'),
        ActionTile(icon: Icons.phone_android, label: 'Airtime & Data'),
        ActionTile(icon: Icons.receipt_long, label: 'Pay Bills'),
        ActionTile(icon: Icons.history, label: 'Transactions'),
      ]),
      const SizedBox(height: 20),
      const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const ListTile(leading: Icon(Icons.info_outline), title: Text('No transactions yet')),
    ]),
  );
}

class ActionTile extends StatelessWidget {
  final IconData icon; final String label;
  const ActionTile({super.key, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Card(child: InkWell(onTap: () {}, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 32), const SizedBox(height: 8), Text(label)]))));
}
