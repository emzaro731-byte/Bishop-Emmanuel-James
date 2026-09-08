import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final phone = TextEditingController();
  final code = TextEditingController();
  bool sent = false, busy = false;

  Future<void> sendOtp() async {
    if (phone.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: phone.text.trim());
      if (mounted) setState(() => sent = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> verify() async {
    try {
      await Supabase.instance.client.auth.verifyOTP(phone: phone.text.trim(), token: code.text.trim(), type: OtpType.sms);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Secure sign in')),
    body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Bishop Pay', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Use your phone number to continue.'),
      const SizedBox(height: 24),
      TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number', hintText: '+2348012345678', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      if (sent) TextField(controller: code, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'OTP code', border: OutlineInputBorder())),
      const SizedBox(height: 16),
      FilledButton(onPressed: busy ? null : (sent ? verify : sendOtp), child: Text(busy ? 'Please wait…' : (sent ? 'Verify OTP' : 'Send OTP'))),
    ])),
  );
}
