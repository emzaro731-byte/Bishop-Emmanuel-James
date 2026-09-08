# Edge Function security

Keep payment-provider API secrets in Supabase Edge Function secrets, never in Flutter or GitHub. Authenticated functions should validate the caller and rely on RLS for user-scoped reads/writes.
