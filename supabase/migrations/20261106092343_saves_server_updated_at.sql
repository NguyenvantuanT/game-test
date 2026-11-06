-- updated_at luôn lấy giờ server (không tin đồng hồ máy người chơi).
create or replace function public.saves_set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke execute on function public.saves_set_updated_at() from public, anon, authenticated;

create trigger saves_set_updated_at
  before insert or update on public.saves
  for each row execute function public.saves_set_updated_at();
