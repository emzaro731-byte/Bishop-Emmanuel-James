import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AddMoneyPage extends StatefulWidget {
  const AddMoneyPage({super.key});

  @override
  State<AddMoneyPage> createState() => _AddMoneyPageState();
}

class _AddMoneyPageState extends State<AddMoneyPage> {
  final amountController = TextEditingController();
  final emailController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    amountController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> startCheckout() async {
    final amount = double.tryParse(amountController.text.replaceAll(',', '').trim());
    final email = emailController.text.trim();
    if (amount == null || amount < 100 || email.isEmpty || !email.contains('@')) {
      _message('Enter a valid email and an amount of at least ₦100.');
      return;
    }
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) {
      _message('Please sign in before adding money.');
      return;
    }
    setState(() => loading = true);
    try {
      final response = await client.functions.invoke(
        'create-deposit-session',
        body: {'amountKobo': (amount * 100).round(), 'email': email},
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final checkoutUrl = data['checkoutUrl']?.toString();
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception(data['error']?.toString() ?? 'Checkout link was not returned.');
      }
      final launched = await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('Could not open Flutterwave checkout.');
      if (mounted) Navigator.pop(context, true);
    } on FunctionException catch (e) {
      final details = e.details is Map ? Map<String, dynamic>.from(e.details as Map) : null;
      _message(details?['error']?.toString() ?? e.reasonPhrase ?? 'Unable to start payment.');
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Add Money')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF123A9A), Color(0xFF2D6BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 34),
                SizedBox(height: 18),
                Text('Fund your Bishop Pay wallet', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text('Secure checkout powered by Flutterwave.', style: TextStyle(color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '₦ ', hintText: '5,000'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Payment email', hintText: 'you@example.com'),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: loading ? null : startCheckout,
              icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.lock_rounded),
              label: Text(loading ? 'Opening checkout…' : 'Continue to payment'),
            ),
            const SizedBox(height: 12),
            const Text('Your wallet is credited only after the server verifies the completed transaction.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
