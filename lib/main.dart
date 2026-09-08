import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'send_money_page.dart';
import 'supabase_config.dart';
import 'wallet_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const BishopPayApp());
}

class BishopPayApp extends StatelessWidget {
  const BishopPayApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Bishop Pay',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2457E6), brightness: Brightness.light),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF6F8FC),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    ),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int balance = 0;
  List<Map<String, dynamic>> transactions = [];
  bool loading = true;

  SupabaseClient? get client => SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  @override
  void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    final c = client;
    if (c == null || c.auth.currentUser == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    setState(() => loading = true);
    try {
      final service = WalletService(c);
      balance = await service.balanceKobo();
      transactions = await service.recentTransactions();
    } catch (_) {
      // Keep the dashboard usable if the database has not been deployed yet.
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openAuth() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage()));
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = client?.auth.currentUser != null;
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bishop Pay', style: TextStyle(fontWeight: FontWeight.w800)),
          Text('Your money, simplified', style: TextStyle(fontSize: 12)),
        ]),
        actions: [
          IconButton(onPressed: openAuth, icon: Icon(signedIn ? Icons.person : Icons.login_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 30), children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF123A9A), Color(0xFF2D6BFF)]),
              boxShadow: const [BoxShadow(blurRadius: 24, offset: Offset(0, 12), color: Color(0x332457E6))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.account_balance_wallet_outlined, color: Colors.white), const Spacer(), Text(signedIn ? 'ACTIVE WALLET' : 'PREVIEW', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700))]),
              const SizedBox(height: 24),
              const Text('Available balance', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(loading ? '₦••••••' : formatNaira(balance), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: FilledButton.tonalIcon(onPressed: () => showDialog(context: context, builder: (_) => const AlertDialog(title: Text('Add Money'), content: Text('A licensed payment provider must be connected before real deposits are enabled.'),)), icon: const Icon(Icons.add), label: const Text('Add Money'))),
            ]),
          ),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: ActionTile(icon: Icons.send_rounded, label: 'Send Money', onTap: () async { if (!signedIn) return openAuth(); await Navigator.push(context, MaterialPageRoute(builder: (_) => const SendMoneyPage())); await refresh(); })),
            const SizedBox(width: 12),
            Expanded(child: ActionTile(icon: Icons.phone_android_rounded, label: 'Airtime', onTap: () => _comingSoon('Airtime & Data'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ActionTile(icon: Icons.receipt_long_rounded, label: 'Bills', onTap: () => _comingSoon('Pay Bills'))),
            const SizedBox(width: 12),
            Expanded(child: ActionTile(icon: Icons.history_rounded, label: 'History', onTap: () => _showHistory(context))),
          ]),
          const SizedBox(height: 28),
          Row(children: [Text('Recent activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const Spacer(), Text('${transactions.length}', style: const TextStyle(fontWeight: FontWeight.w700))]),
          const SizedBox(height: 10),
          if (transactions.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(22), child: Column(children: [Icon(Icons.receipt_long_outlined, size: 38), SizedBox(height: 8), Text('No transactions yet'), SizedBox(height: 4), Text('Your successful activity will appear here.', textAlign: TextAlign.center)])))
          else ...transactions.map((tx) => _TransactionTile(tx: tx)),
        ]),
      ),
    );
  }

  void _comingSoon(String name) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name will be enabled after provider integration.')));

  void _showHistory(BuildContext context) => showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [Text('Transaction history', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 12), if (transactions.isEmpty) const Text('No transactions yet.') else ...transactions.map((tx) => _TransactionTile(tx: tx))])));
}

class ActionTile extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const ActionTile({super.key, required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(elevation: 0, child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 18), child: Column(children: [Icon(icon, size: 28), const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))]))));
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionTile({required this.tx});
  @override
  Widget build(BuildContext context) {
    final credit = tx['type'] == 'credit';
    final amount = (tx['amount_kobo'] as num?)?.toInt() ?? 0;
    return Card(elevation: 0, child: ListTile(leading: CircleAvatar(child: Icon(credit ? Icons.south_west : Icons.north_east)), title: Text(tx['description']?.toString() ?? 'Transaction'), subtitle: Text(tx['status']?.toString() ?? 'pending'), trailing: Text('${credit ? '+' : '-'}${formatNaira(amount)}', style: const TextStyle(fontWeight: FontWeight.w800))));
  }
}
