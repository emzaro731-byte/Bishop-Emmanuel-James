import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'supabase_config.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final client = SupabaseConfig.isConfigured ? Supabase.instance.client : null;
    final user = client?.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Security')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
          const CircleAvatar(radius: 30, child: Icon(Icons.person_rounded, size: 30)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user == null ? 'Guest user' : 'Bishop Pay user', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(user?.phone ?? 'Sign in to activate your wallet'),
          ])),
        ]))),
        const SizedBox(height: 14),
        _Item(Icons.verified_user_outlined, 'Identity verification', 'KYC status and account limits', () => _info(context, 'KYC', 'Identity verification will be connected to the licensed provider/compliance flow.')),
        _Item(Icons.lock_outline, 'PIN & biometrics', 'Protect sensitive actions', () => _info(context, 'Security', 'Transaction PIN and biometric confirmation are planned for the secure payment flow.')),
        _Item(Icons.notifications_none_rounded, 'Notifications', 'Payment and security alerts', () => _info(context, 'Notifications', 'Push and transaction notifications will be enabled with the backend notification service.')),
        _Item(Icons.help_outline, 'Help & support', 'Get help with Bishop Pay', () => _info(context, 'Support', 'Support centre placeholder.')),
        if (user == null) FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage())), icon: const Icon(Icons.login), label: const Text('Sign in')),
        if (user != null) OutlinedButton.icon(onPressed: () async { await client!.auth.signOut(); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.logout), label: const Text('Sign out')),
      ],
    );
  }

  void _info(BuildContext context, String title, String body) => showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(title), content: Text(body), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
}

class _Item extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  const _Item(this.icon, this.title, this.subtitle, this.onTap);
  @override
  Widget build(BuildContext context) => Card(elevation: 0, child: ListTile(leading: CircleAvatar(child: Icon(icon)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right), onTap: onTap));
}
