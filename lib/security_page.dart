import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});
  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final LocalAuthentication auth = LocalAuthentication();
  bool biometricEnabled = false;
  bool checking = true;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    try {
      final supported = await auth.isDeviceSupported();
      if (mounted) setState(() => checking = false);
      if (!supported && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This device does not support biometric authentication.')));
      }
    } catch (_) {
      if (mounted) setState(() => checking = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!value) {
      setState(() => biometricEnabled = false);
      return;
    }
    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'Confirm your identity to protect Bishop Pay',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true, useErrorDialogs: true),
      );
      if (mounted) setState(() => biometricEnabled = authenticated);
      if (authenticated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric protection enabled on this device.')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric authentication could not be completed.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Security')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [Color(0xFF123A9A), Color(0xFF2D6BFF)]),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.shield_rounded, color: Colors.white, size: 34),
          SizedBox(height: 14),
          Text('Protect your wallet', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text('Use device authentication before sensitive actions.', style: TextStyle(color: Colors.white70)),
        ]),
      ),
      const SizedBox(height: 18),
      Card(elevation: 0, child: SwitchListTile.adaptive(
        secondary: const Icon(Icons.fingerprint_rounded),
        title: const Text('Biometric protection', style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(checking ? 'Checking device support…' : 'Require device authentication for protected actions'),
        value: biometricEnabled,
        onChanged: checking ? null : _toggleBiometric,
      )),
      const SizedBox(height: 10),
      const Card(elevation: 0, child: ListTile(
        leading: Icon(Icons.lock_outline_rounded),
        title: Text('Transaction PIN', style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('Server-side transaction PIN setup will be enabled before real money movement.'),
      )),
      const SizedBox(height: 10),
      const Card(elevation: 0, child: ListTile(
        leading: Icon(Icons.verified_user_outlined),
        title: Text('Secure payments', style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('Real transfers will use authenticated server functions, provider verification and idempotent references.'),
      )),
    ]),
  );
}
