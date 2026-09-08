import 'package:flutter/material.dart';
import 'send_money_page.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final services = <_Service>[
      _Service('Send Money', Icons.send_rounded, 'Transfer to a bank account or wallet', true),
      _Service('Airtime', Icons.phone_android_rounded, 'Top up any Nigerian number', false),
      _Service('Data', Icons.wifi_rounded, 'Buy mobile data bundles', false),
      _Service('Electricity', Icons.bolt_rounded, 'Pay electricity bills', false),
      _Service('TV', Icons.tv_rounded, 'Pay TV subscriptions', false),
      _Service('Betting', Icons.sports_soccer_rounded, 'Fund supported wallets', false),
      _Service('QR Pay', Icons.qr_code_rounded, 'Scan and pay merchants', false),
      _Service('Bank Transfer', Icons.account_balance_rounded, 'Provider-powered bank transfers', false),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: GridView.builder(
        padding: const EdgeInsets.all(18),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05),
        itemCount: services.length,
        itemBuilder: (_, i) {
          final s = services[i];
          return Card(
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (s.enabled) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SendMoneyPage()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${s.title} will be enabled after licensed provider integration.')));
                }
              },
              child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(radius: 24, child: Icon(s.icon)),
                const Spacer(),
                Text(s.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(s.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
              ])),
            ),
          );
        },
      ),
    );
  }
}

class _Service {
  final String title, subtitle;
  final IconData icon;
  final bool enabled;
  const _Service(this.title, this.icon, this.subtitle, this.enabled);
}
