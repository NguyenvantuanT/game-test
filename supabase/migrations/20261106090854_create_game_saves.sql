-- Bản lưu game-test: 1 dòng / tài khoản, dữ liệu JSON do game gửi lên.
create table public.saves (
  user_id uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  -- Bản lưu thật vài KB; chặn ghi rác cỡ lớn.
  constraint saves_data_size check (octet_length(data::text) <= 262144)
);

alter table public.saves enable row level security;

revoke all on table public.saves from anon, authenticated;
grant select, insert, update on table public.saves to authenticated;

create policy saves_select_own on public.saves
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy saves_insert_own on public.saves
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy saves_update_own on public.saves
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
