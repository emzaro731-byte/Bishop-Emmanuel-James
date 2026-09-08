import { createClient } from 'npm:@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const FLW_SECRET_KEY = Deno.env.get('FLW_SECRET_KEY')
const FLW_WEBHOOK_SECRET_HASH = Deno.env.get('FLW_WEBHOOK_SECRET_HASH')
const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { 'Content-Type': 'application/json' } })
}

Deno.serve(async (req) => {
  if (req.method === 'GET') return json({ service: 'Bishop Pay payment return', message: 'Payment processing is verified server-side. You can return to the Bishop Pay app.' })
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405)
  if (!FLW_SECRET_KEY || !FLW_WEBHOOK_SECRET_HASH) return json({ error: 'Webhook secrets are not configured' }, 503)

  const receivedHash = req.headers.get('verif-hash')
  if (!receivedHash || receivedHash !== FLW_WEBHOOK_SECRET_HASH) return json({ error: 'Invalid webhook signature' }, 401)

  try {
    const payload = await req.json()
    const data = payload?.data ?? payload
    const transactionId = String(data?.id ?? '')
    const reference = String(data?.tx_ref ?? data?.txRef ?? '')
    if (!transactionId || !reference) return json({ error: 'Missing transaction identifiers' }, 400)

    const verifyResponse = await fetch(`https://api.flutterwave.com/v3/transactions/${encodeURIComponent(transactionId)}/verify`, {
      headers: { Authorization: `Bearer ${FLW_SECRET_KEY}`, 'Content-Type': 'application/json' },
    })
    const verified = await verifyResponse.json()
    const transaction = verified?.data
    if (!verifyResponse.ok || verified?.status !== 'success' || transaction?.status !== 'successful') {
      return json({ received: true, status: 'not_successful' })
    }

    const verifiedReference = String(transaction.tx_ref ?? '')
    const verifiedCurrency = String(transaction.currency ?? '')
    const verifiedAmount = Number(transaction.amount)
    if (verifiedReference !== reference || verifiedCurrency !== 'NGN' || !Number.isFinite(verifiedAmount) || verifiedAmount <= 0) {
      return json({ error: 'Verified transaction data mismatch' }, 400)
    }

    const { data: deposit, error: depositError } = await supabase
      .from('deposit_intents')
      .select('id, amount_kobo, currency, status')
      .eq('reference', verifiedReference)
      .maybeSingle()
    if (depositError) throw depositError
    if (!deposit) return json({ error: 'Deposit intent not found' }, 404)

    const expectedKobo = Number(deposit.amount_kobo)
    if (Math.round(verifiedAmount * 100) < expectedKobo) return json({ error: 'Verified amount is below expected amount' }, 400)
    if (deposit.currency !== 'NGN') return json({ error: 'Unsupported currency' }, 400)

    const { data: settled, error: settleError } = await supabase.rpc('apply_verified_deposit', {
      p_reference: verifiedReference,
      p_provider_transaction_id: transactionId,
      p_amount_kobo: expectedKobo,
    })
    if (settleError) throw settleError

    return json({ received: true, settled: Boolean(settled) })
  } catch (error) {
    console.error(error)
    return json({ error: 'Webhook processing failed' }, 500)
  }
})
