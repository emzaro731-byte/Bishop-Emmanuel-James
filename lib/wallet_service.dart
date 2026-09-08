import 'package:supabase_flutter/supabase_flutter.dart';

class WalletService {
  final SupabaseClient client;
  WalletService(this.client);

  Future<int> balanceKobo() async {
    final user = client.auth.currentUser;
    if (user == null) return 0;
    final row = await client.from('wallets').select('balance_kobo').eq('user_id', user.id).maybeSingle();
    return (row?['balance_kobo'] as num?)?.toInt() ?? 0;
  }

  Future<List<Map<String, dynamic>>> recentTransactions() async {
    final rows = await client
        .from('transactions')
        .select('id,type,amount_kobo,currency,status,reference,description,created_at')
        .order('created_at', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> createTransfer({required int amountKobo, required String recipient}) async {
    final response = await client.functions.invoke(
      'create-transfer',
      body: {'amountKobo': amountKobo, 'recipient': recipient},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}

String formatNaira(int kobo) {
  final naira = kobo / 100;
  return '₦${naira.toStringAsFixed(2)}';
}
