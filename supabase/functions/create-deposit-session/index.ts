import { withSupabase } from 'npm:@supabase/server@^1'

const FLW_URL = 'https://api.flutterwave.com/v3/payments'

Deno.serve(withSupabase({ auth: 'user' }, async (req, ctx) => {
  if (req.method !== 'POST') return Response.json({ error: 'Method not allowed' }, { status: 405 })

  try {
    const secret = Deno.env.get('FLW_SECRET_KEY')
    if (!secret) return Response.json({ error: 'Flutterwave secret is not configured' }, { status: 503 })

    const body = await req.json()
    const amountKobo = Number(body.amountKobo)
    const email = String(body.email ?? '').trim()
    const user = (await ctx.supabase.auth.getUser()).data.user
    if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 })
    if (!Number.isInteger(amountKobo) || amountKobo < 10000) {
      return Response.json({ error: 'Minimum deposit is ₦100' }, { status: 400 })
    }
    if (!email || !email.includes('@')) {
      return Response.json({ error: 'A valid payment email is required' }, { status: 400 })
    }

    const reference = `BP-${crypto.randomUUID()}`
    const amountNaira = amountKobo / 100
    const { error: insertError } = await ctx.supabase.from('deposit_intents').insert({
      user_id: user.id,
      amount_kobo: amountKobo,
      currency: 'NGN',
      reference,
      provider: 'flutterwave',
      status: 'pending',
    })
    if (insertError) throw new Error(`Could not create deposit intent: ${insertError.message}`)

    const response = await fetch(FLW_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${secret}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        tx_ref: reference,
        amount: amountNaira,
        currency: 'NGN',
        redirect_url: 'https://bishop-pay-webhook.invalid/flutterwave/return',
        customer: {
          email,
          name: user.user_metadata?.full_name ?? 'Bishop Pay User',
          phonenumber: user.phone ?? undefined,
        },
        customizations: {
          title: 'Bishop Pay',
          description: 'Wallet funding',
        },
      }),
    })

    const result = await response.json()
    if (!response.ok || result?.status !== 'success' || !result?.data?.link) {
      await ctx.supabase.from('deposit_intents').update({ status: 'failed' }).eq('reference', reference)
      return Response.json({ error: result?.message ?? 'Flutterwave checkout could not be created' }, { status: 502 })
    }

    await ctx.supabase.from('deposit_intents').update({ checkout_url: result.data.link }).eq('reference', reference)
    return Response.json({ checkoutUrl: result.data.link, reference })
  } catch (error) {
    return Response.json({ error: String(error) }, { status: 400 })
  }
}))
