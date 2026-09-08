create table if not exists public.deposit_intents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount_kobo bigint not null check (amount_kobo > 0),
  currency text not null default 'NGN',
  reference text not null unique,
  provider text not null default 'flutterwave',
  provider_transaction_id text,
  checkout_url text,
  status text not null default 'pending' check (status in ('pending','successful','failed','reversed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.deposit_intents enable row level security;

drop policy if exists "deposit own rows" on public.deposit_intents;
create policy "deposit own rows" on public.deposit_intents
for select to authenticated using (user_id = auth.uid());

create or replace function public.apply_verified_deposit(
  p_reference text,
  p_provider_transaction_id text,
  p_amount_kobo bigint
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  d public.deposit_intents%rowtype;
begin
  select * into d
  from public.deposit_intents
  where reference = p_reference
  for update;

  if not found then
    raise exception 'deposit_not_found';
  end if;

  if d.amount_kobo <> p_amount_kobo or d.currency <> 'NGN' then
    raise exception 'deposit_amount_mismatch';
  end if;

  if d.status = 'successful' then
    return false;
  end if;

  update public.deposit_intents
  set status = 'successful',
      provider_transaction_id = p_provider_transaction_id,
      updated_at = now()
  where id = d.id;

  update public.wallets
  set balance_kobo = balance_kobo + d.amount_kobo,
      updated_at = now()
  where user_id = d.user_id;

  if not found then
    raise exception 'wallet_not_found';
  end if;

  insert into public.transactions(user_id, type, amount_kobo, currency, status, reference, description)
  values (d.user_id, 'credit', d.amount_kobo, 'NGN', 'successful', d.reference, 'Flutterwave wallet deposit')
  on conflict (reference) do nothing;

  return true;
end;
$$;
