-- =========================================================
-- BLACK & WHITE BARBEARIA — Schema do Supabase
-- Cole este arquivo inteiro no SQL Editor do seu projeto
-- Supabase (https://app.supabase.com) e clique em "Run".
-- =========================================================

-- 1) TABELA DE AGENDAMENTOS -------------------------------
create table if not exists public.bookings (
  id            uuid primary key default gen_random_uuid(),
  seq           bigint generated always as identity,
  code          text generated always as ('BW-' || lpad(seq::text, 4, '0')) stored,
  service_id    text not null check (service_id in
                  ('corte','barba','combo','sobrancelha','platinado','infantil','progressiva','alisamento')),
  barber_id     text not null check (barber_id in
                  ('any','thales','marcelo','darlheson')),
  date          date not null,
  time          time not null,
  customer_name  text not null,
  customer_phone text,
  customer_email text,
  note          text,
  created_at    timestamptz not null default now()
);

create unique index if not exists bookings_code_idx on public.bookings (code);
create index if not exists bookings_date_idx on public.bookings (date);

-- 2) SEGURANÇA (Row Level Security) ------------------------
alter table public.bookings enable row level security;

-- Ninguém lê a tabela diretamente sem estar logado (barbeiro autenticado).
create policy "Barbeiros logados podem ver todos os agendamentos"
  on public.bookings for select
  to authenticated
  using (true);

create policy "Barbeiros logados podem editar agendamentos"
  on public.bookings for update
  to authenticated
  using (true)
  with check (true);

create policy "Barbeiros logados podem excluir agendamentos"
  on public.bookings for delete
  to authenticated
  using (true);

-- Não existe política de INSERT direto na tabela: toda criação de
-- agendamento (pelo cliente OU pelo barbeiro) passa pela função
-- segura create_booking() definida abaixo. Isso evita expor a tabela
-- inteira para visitantes anônimos do site.

-- 3) FUNÇÃO SEGURA: CRIAR AGENDAMENTO -----------------------
-- Usada tanto pelo cliente (sem login) quanto pelo barbeiro (logado,
-- agendamento manual). Roda com privilégio de dono da função
-- (security definer), então não é afetada pelo RLS acima, mas só
-- devolve o código do agendamento — nunca a lista completa.
create or replace function public.create_booking(
  p_service_id     text,
  p_barber_id      text,
  p_date           date,
  p_time           time,
  p_customer_name  text,
  p_customer_phone text,
  p_customer_email text,
  p_note           text
) returns table(code text)
language plpgsql
security definer
set search_path = public
as $$
declare
  new_code text;
begin
  insert into public.bookings
    (service_id, barber_id, date, time, customer_name, customer_phone, customer_email, note)
  values
    (p_service_id, p_barber_id, p_date, p_time, p_customer_name, p_customer_phone, p_customer_email, p_note)
  returning bookings.code into new_code;

  return query select new_code;
end;
$$;

grant execute on function public.create_booking
  (text, text, date, time, text, text, text, text) to anon, authenticated;

-- 4) FUNÇÃO SEGURA: CONSULTAR HORÁRIOS OCUPADOS --------------
-- Permite que o site (mesmo sem o visitante estar logado) saiba quais
-- horários já estão ocupados num dia, sem expor nomes/telefones de
-- clientes — só devolve os horários.
create or replace function public.get_booked_times(
  p_date      date,
  p_barber_id text default null
) returns table(time_slot time)
language sql
security definer
set search_path = public
as $$
  select time from public.bookings
  where date = p_date
    and (p_barber_id is null or p_barber_id = 'any' or barber_id = p_barber_id);
$$;

grant execute on function public.get_booked_times(date, text) to anon, authenticated;

-- =========================================================
-- PRÓXIMO PASSO: criar os logins dos barbeiros
-- =========================================================
-- No painel do Supabase, vá em Authentication > Users > Add user
-- e crie um usuário para cada barbeiro, por exemplo:
--
--   thales@blackandwhite.com.br      (defina uma senha forte)
--   marcelo@blackandwhite.com.br
--   darlheson@blackandwhite.com.br
--
-- Esses e-mails precisam ser EXATAMENTE os mesmos configurados no
-- objeto "staffDirectory" dentro do index.html, para o site saber
-- qual barbeiro está logado.
-- =========================================================
