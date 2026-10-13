-- 紫竹创业孵化器 · 共享会议室预约 —— Supabase 数据库脚本
-- 用法：Supabase 控制台 → SQL Editor → 粘贴全部内容 → Run（可重复执行）
-- 设计：
--   * 同一会议室同一天时间段重叠由数据库排他约束拒绝（多台设备同时提交也只会成功一个）
--   * 访客只能读公开字段；新增/取消只能通过下面两个函数
--   * 取消需要提交时生成的 token（只保存在提交预约的那台设备上）；管理员可在控制台 Table Editor 直接删除

create extension if not exists btree_gist;

create table if not exists public.bookings (
  id          uuid primary key default gen_random_uuid(),
  room        text not null check (room in ('roadshow','big','a','b')),
  day         date not null,
  start_min   int  not null check (start_min >= 480 and start_min % 30 = 0),
  end_min     int  not null check (end_min <= 1260 and end_min % 30 = 0 and end_min > start_min and end_min - start_min <= 240),
  org         text not null check (char_length(org) between 1 and 40),
  contact     text not null check (char_length(contact) between 1 and 20),
  topic       text not null check (char_length(topic) between 1 and 60),
  people      int  not null check (people between 1 and 200),
  token       uuid not null default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  constraint no_overlap exclude using gist (room with =, day with =, int4range(start_min, end_min) with &&)
);

alter table public.bookings enable row level security;
drop policy if exists bookings_read on public.bookings;
create policy bookings_read on public.bookings for select to anon, authenticated using (true);

-- 访客只能读公开列（不含 token），不能直接写表
revoke all on public.bookings from anon, authenticated;
grant select (id, room, day, start_min, end_min, org, contact, topic, people, created_at)
  on public.bookings to anon, authenticated;

create or replace function public.book(
  p_room text, p_day date, p_start int, p_end int,
  p_org text, p_contact text, p_topic text, p_people int)
returns table (id uuid, token uuid)
language plpgsql security definer set search_path = public as $$
declare
  today date := (now() at time zone 'Asia/Shanghai')::date;
  now_min int := extract(hour from now() at time zone 'Asia/Shanghai')::int * 60
               + extract(minute from now() at time zone 'Asia/Shanghai')::int;
  cap int := case p_room when 'roadshow' then 60 when 'big' then 20 when 'a' then 8 when 'b' then 6 end;
begin
  if p_day < today or p_day > today + 30 then raise exception 'bad_date'; end if;
  if p_day = today and p_end <= now_min then raise exception 'past'; end if;
  if cap is null or p_people > cap then raise exception 'capacity'; end if;
  return query
    insert into public.bookings as b (room, day, start_min, end_min, org, contact, topic, people)
    values (p_room, p_day, p_start, p_end, trim(p_org), trim(p_contact), trim(p_topic), p_people)
    returning b.id, b.token;
end $$;

create or replace function public.cancel_booking(p_id uuid, p_token uuid)
returns boolean
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  delete from public.bookings where id = p_id and token = p_token;
  get diagnostics n = row_count;
  return n > 0;
end $$;

revoke all on function public.book(text, date, int, int, text, text, text, int) from public;
revoke all on function public.cancel_booking(uuid, uuid) from public;
grant execute on function public.book(text, date, int, int, text, text, text, int) to anon, authenticated;
grant execute on function public.cancel_booking(uuid, uuid) to anon, authenticated;

-- 让接口立即识别新表和函数
notify pgrst, 'reload schema';
