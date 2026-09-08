import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddMoneyPage extends StatefulWidget {
  const AddMoneyPage({super.key});

  @override
  State<AddMoneyPage> createState() => _AddMoneyPageState();
}

class _AddMoneyPageState extends State<AddMoneyPage> {
  final controller = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> createCheckout() async {
    final naira = int.tryParse(controller.text.replaceAll(',', '').trim());
    if (naira == null || naira < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount of at least ₦100.')),
      );
      return;
    }

    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before adding money.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final response = await client.functions.invoke(
        'create-deposit-session',
        body: {'amountKobo': naira * 100},
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final link = data['checkoutUrl']?.toString();
      if (!mounted) return;
      if (link == null || link.isEmpty) {
        throw Exception(data['message']?.toString() ?? 'Checkout link was not returned.');
      }
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Flutterwave checkout ready'),
          content: SelectableText(link),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start payment: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Money')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Fund your Bishop Pay wallet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Payments are processed through Flutterwave. Your wallet balance is updated only after verified server-side payment confirmation.'),
          const SizedBox(height: 28),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (NGN)', prefixText: '₦ '),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1000, 2000, 5000, 10000, 20000].map((amount) => ActionChip(
              label: Text('₦$amount'),
              onPressed: () => controller.text = amount.toString(),
            )).toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: loading ? null : createCheckout,
              icon: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.lock_rounded),
              label: Text(loading ? 'Starting checkout...' : 'Continue to Flutterwave'),
            ),
          ),
        ],
      ),
    );
  }
}
