-- memorial-peng2 后端初始化脚本
-- 使用方法：Supabase 项目 -> SQL Editor -> New query -> 粘贴全部内容 -> Run

create extension if not exists pgcrypto;

create table if not exists public.memorial_actions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  visitor_name text not null,
  visitor_key text not null,
  action_type text not null check (action_type in ('flower', 'candle', 'message', 'image')),
  content text,
  image_url text,
  image_path text
);

create index if not exists memorial_actions_created_at_idx on public.memorial_actions (created_at desc);
create index if not exists memorial_actions_visitor_key_idx on public.memorial_actions (visitor_key);
create index if not exists memorial_actions_action_type_idx on public.memorial_actions (action_type);

alter table public.memorial_actions enable row level security;

drop policy if exists "Public read memorial actions" on public.memorial_actions;
create policy "Public read memorial actions"
on public.memorial_actions
for select
using (true);

drop policy if exists "Public insert memorial actions" on public.memorial_actions;
create policy "Public insert memorial actions"
on public.memorial_actions
for insert
with check (
  visitor_name is not null
  and char_length(trim(visitor_name)) between 1 and 30
  and visitor_key is not null
  and char_length(trim(visitor_key)) between 8 and 120
  and action_type in ('flower', 'candle', 'message', 'image')
  and (
    action_type <> 'message'
    or (content is not null and char_length(trim(content)) between 1 and 1000)
  )
  and (
    action_type <> 'image'
    or (image_url is not null and image_path is not null)
  )
);

grant usage on schema public to anon, authenticated;
grant select, insert on public.memorial_actions to anon, authenticated;

-- 统计函数：按北京时间/中国标准时间计算“今日吊唁人数”
create or replace function public.get_memorial_stats()
returns table (
  flower_count bigint,
  candle_count bigint,
  today_visitors bigint,
  total_visitors bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    count(*) filter (where action_type = 'flower')::bigint as flower_count,
    count(*) filter (where action_type = 'candle')::bigint as candle_count,
    count(distinct visitor_key) filter (
      where (created_at at time zone 'Asia/Shanghai')::date = (now() at time zone 'Asia/Shanghai')::date
    )::bigint as today_visitors,
    count(distinct visitor_key)::bigint as total_visitors
  from public.memorial_actions;
$$;

grant execute on function public.get_memorial_stats() to anon, authenticated;

-- 开启 Realtime：让网页能实时收到新留言/送花/点烛/图片记录
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'memorial_actions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.memorial_actions;
  END IF;
END $$;

-- 图片存储桶：公开读取、允许匿名上传常见图片，单张最大 5MB
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'memorial-images',
  'memorial-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public read memorial images" on storage.objects;
create policy "Public read memorial images"
on storage.objects
for select
using (bucket_id = 'memorial-images');

drop policy if exists "Public upload memorial images" on storage.objects;
create policy "Public upload memorial images"
on storage.objects
for insert
with check (bucket_id = 'memorial-images');
