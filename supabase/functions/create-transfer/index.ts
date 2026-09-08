import { withSupabase } from 'npm:@supabase/server@^1'

Deno.serve(withSupabase({ auth: 'user' }, async (req, ctx) => {
  if (req.method !== 'POST') return Response.json({ error: 'Method not allowed' }, { status: 405 })
  try {
    const body = await req.json()
    const amountKobo = Number(body.amountKobo)
    const recipient = String(body.recipient ?? '').trim()
    if (!Number.isInteger(amountKobo) || amountKobo <= 0 || !recipient) {
      return Response.json({ error: 'Invalid transfer request' }, { status: 400 })
    }

    // Provider API calls belong here. Never place provider secret keys in Flutter.
    // This endpoint currently creates no money movement and is safe as a scaffold.
    return Response.json({
      status: 'pending_provider_setup',
      message: 'Connect a licensed payment provider before enabling real transfers.',
      recipient,
      amountKobo,
      userId: (await ctx.supabase.auth.getUser()).data.user?.id,
    })
  } catch (error) {
    return Response.json({ error: String(error) }, { status: 400 })
  }
}))
