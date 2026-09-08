import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'wallet_service.dart';

class SendMoneyPage extends StatefulWidget {
  const SendMoneyPage({super.key});
  @override State<SendMoneyPage> createState() => _SendMoneyPageState();
}

class _SendMoneyPageState extends State<SendMoneyPage> {
  final recipient = TextEditingController();
  final amount = TextEditingController();
  bool busy = false;

  Future<void> send() async {
    final naira = double.tryParse(amount.text.trim().replaceAll(',', ''));
    final target = recipient.text.trim();
    if (naira == null || naira <= 0 || target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid recipient and amount.')));
      return;
    }
    setState(() => busy = true);
    try {
      final result = await WalletService(Supabase.instance.client).createTransfer(
        amountKobo: (naira * 100).round(),
        recipient: target,
      );
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Transfer request created'),
          content: Text(result['message']?.toString() ?? 'The transfer is pending provider setup.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transfer failed: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() { recipient.dispose(); amount.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Send Money')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Icon(Icons.send_rounded, size: 54),
      const SizedBox(height: 14),
      Text('Send securely', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('Transfers remain protected until a licensed payment provider is connected.'),
      const SizedBox(height: 24),
      TextField(controller: recipient, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Recipient phone / account', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())),
      const SizedBox(height: 14),
      TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (NGN)', prefixText: '₦ ', prefixIcon: Icon(Icons.payments_outlined), border: OutlineInputBorder())),
      const SizedBox(height: 22),
      FilledButton.icon(onPressed: busy ? null : send, icon: const Icon(Icons.lock_outline), label: Text(busy ? 'Processing…' : 'Continue securely')),
    ]),
  );
}
