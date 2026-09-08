import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'profile_page.dart';
import 'send_money_page.dart';
import 'services_page.dart';
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
    home: const HomeShell(),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  int balance = 0;
  List<Map<String, dynamic>> transactions = [];
  bool loading = true;

  SupabaseClient? get client => SupabaseConfig.isConfigured ? Supabase.instance.client : null;
  bool get signedIn => client?.auth.currentUser != null;

  @override
  void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    final c = client;
    if (c == null || c.auth.currentUser == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    if (mounted) setState(() => loading = true);
    try {
      final service = WalletService(c);
      balance = await service.balanceKobo();
      transactions = await service.recentTransactions();
    } catch (_) {
      // Keep the app usable while the Supabase migration/provider is being configured.
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openAuth() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage()));
    await refresh();
  }

  Future<void> sendMoney() async {
    if (!signedIn) { await openAuth(); return; }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SendMoneyPage()));
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(balance: balance, loading: loading, signedIn: signedIn, transactions: transactions, onSend: sendMoney, onRefresh: refresh, onAuth: openAuth),
      const ServicesPage(),
      _ActivityTab(transactions: transactions),
      const ProfilePage(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Pay'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Activity'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final int balance;
  final bool loading, signedIn;
  final List<Map<String, dynamic>> transactions;
  final VoidCallback onSend, onAuth;
  final Future<void> Function() onRefresh;
  const _HomeTab({required this.balance, required this.loading, required this.signedIn, required this.transactions, required this.onSend, required this.onRefresh, required this.onAuth});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Bishop Pay', style: TextStyle(fontWeight: FontWeight.w800)),
        Text('Your money, simplified', style: TextStyle(fontSize: 12)),
      ]),
      actions: [IconButton(onPressed: onAuth, icon: Icon(signedIn ? Icons.person : Icons.login_rounded))],
    ),
    body: RefreshIndicator(
      onRefresh: onRefresh,
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
            SizedBox(width: double.infinity, child: FilledButton.tonalIcon(onPressed: () => _addMoney(context), icon: const Icon(Icons.add), label: const Text('Add Money'))),
          ]),
        ),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: _ActionTile(icon: Icons.send_rounded, label: 'Send Money', onTap: onSend)),
          const SizedBox(width: 12),
          Expanded(child: _ActionTile(icon: Icons.phone_android_rounded, label: 'Airtime', onTap: () => _soon(context, 'Airtime & Data'))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _ActionTile(icon: Icons.receipt_long_rounded, label: 'Bills', onTap: () => _soon(context, 'Bills'))),
          const SizedBox(width: 12),
          Expanded(child: _ActionTile(icon: Icons.qr_code_rounded, label: 'QR Pay', onTap: () => _soon(context, 'QR Pay'))),
        ]),
        const SizedBox(height: 28),
        Text('Recent activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (transactions.isEmpty)
          const Card(elevation: 0, child: Padding(padding: EdgeInsets.all(22), child: Column(children: [Icon(Icons.receipt_long_outlined, size: 38), SizedBox(height: 8), Text('No transactions yet'), SizedBox(height: 4), Text('Your successful activity will appear here.', textAlign: TextAlign.center)])))
        else ...transactions.take(5).map((tx) => _TransactionTile(tx: tx)),
      ]),
    ),
  );

  void _addMoney(BuildContext context) => showDialog<void>(context: context, builder: (_) => const AlertDialog(title: Text('Add Money'), content: Text('Real deposits will be enabled after a licensed payment provider and webhook flow are configured.')));
  void _soon(BuildContext context, String name) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name will be enabled after provider integration.')));
}

class _ActivityTab extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const _ActivityTab({required this.transactions});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Activity')),
    body: transactions.isEmpty
        ? const Center(child: Text('No transactions yet'))
        : ListView(padding: const EdgeInsets.all(18), children: transactions.map((tx) => _TransactionTile(tx: tx)).toList()),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap});
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
    return Card(elevation: 0, child: ListTile(
      leading: CircleAvatar(child: Icon(credit ? Icons.south_west : Icons.north_east)),
      title: Text(tx['description']?.toString() ?? 'Transaction'),
      subtitle: Text(tx['status']?.toString() ?? 'pending'),
      trailing: Text('${credit ? '+' : '-'}${formatNaira(amount)}', style: const TextStyle(fontWeight: FontWeight.w800)),
    ));
  }
}
