-- =============================================================================
-- supabase/schema.sql
-- -----------------------------------------------------------------------------
-- BANCO DE DADOS do Banco de Talentos Audiovisual (PostgreSQL + PostGIS).
--
-- Como usar: no painel do Supabase, abra "SQL Editor", cole TODO este arquivo
-- e clique em "Run". O script pode ser executado mais de uma vez sem duplicar
-- nada (usa "if not exists" / "or replace" / "drop ... if exists").
--
-- Conceitos usados:
--   * PostGIS: extensão que adiciona TIPOS e FUNÇÕES GEOGRÁFICAS ao PostgreSQL.
--     É a base da "Computação Espacial" do TCC.
--   * geography(Point, 4326): um ponto na superfície da Terra (latitude e
--     longitude no sistema WGS 84, o mesmo do GPS). Distâncias calculadas em
--     METROS levando em conta a curvatura da Terra.
--   * Índice GiST: índice espacial que deixa a busca por raio rápida mesmo com
--     milhares de registros.
--   * RLS (Row Level Security): regras que dizem QUEM pode ler/alterar CADA
--     linha. Como o app acessa o banco direto, a segurança fica aqui.
--   * auth.uid(): função do Supabase que devolve o id do usuário logado.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. EXTENSÕES
-- -----------------------------------------------------------------------------

-- Ativa o PostGIS no schema "extensions" (padrão do Supabase).
create extension if not exists postgis with schema extensions;


-- -----------------------------------------------------------------------------
-- 2. PERFIS (profiles)
-- Um perfil ÚNICO para cada usuário (como no Airbnb, onde o hóspede pode
-- "tornar-se anfitrião"). A mesma conta pode ter um ou os dois papéis:
--   * PROFISSIONAL: oferece seus serviços e se candidata a vagas;
--   * CONTRATANTE: publica vagas e seleciona profissionais.
-- -----------------------------------------------------------------------------
create table if not exists public.profiles (
  -- Mesmo id do usuário no sistema de login do Supabase (auth.users).
  -- "on delete cascade": se a conta for apagada, o perfil também é.
  id uuid primary key references auth.users (id) on delete cascade,

  -- Papéis da conta (podem ser os dois ao mesmo tempo).
  is_professional boolean not null default true,  -- oferece serviços?
  is_recruiter boolean not null default false,    -- é contratante (publica vagas)?

  full_name text not null default '',
  email text,
  phone text,

  -- Função principal (ex.: 'Videomaker') e habilidades extras (lista).
  primary_role text,
  secondary_skills text[] not null default '{}',

  bio text,                       -- apresentação / mini-currículo
  avatar_url text,                -- URL pública da foto de perfil
  resume_path text,               -- caminho do PDF do currículo no Storage
  company_name text,              -- produtora/empresa (usado por contratantes)

  city text,
  state text,
  latitude double precision,
  longitude double precision,

  -- Ponto geográfico GERADO AUTOMATICAMENTE a partir da latitude/longitude.
  -- "generated always ... stored": o banco recalcula sozinho sempre que
  -- latitude ou longitude mudarem. ST_MakePoint recebe (LONGITUDE, LATITUDE).
  location extensions.geography(Point, 4326) generated always as (
    case
      when latitude is not null and longitude is not null then
        extensions.st_setsrid(extensions.st_makepoint(longitude, latitude), 4326)::extensions.geography
    end
  ) stored,

  rating numeric(2, 1) not null default 0,       -- avaliação média (0 a 5)
  is_available boolean not null default true,    -- disponível para trabalhos?

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
  -- A conta PODE ficar sem perfil ativo logo após o cadastro: a pessoa
  -- escolhe o primeiro modo na tela "Como você quer começar?" (TEL04).
);

-- MIGRAÇÃO: caso uma versão anterior deste script (com a coluna "user_type")
-- já tenha sido executada, converte para o novo modelo de papéis.
-- Em um banco novo, estes comandos simplesmente não fazem nada.
alter table public.profiles add column if not exists is_professional boolean not null default true;
alter table public.profiles add column if not exists is_recruiter boolean not null default false;
alter table public.profiles drop column if exists user_type cascade;
-- Versões anteriores exigiam pelo menos um papel; a regra saiu (TEL04).
alter table public.profiles drop constraint if exists profiles_has_role;

-- Conta desativada pela própria pessoa (TEL22). Nulo = ativa.
alter table public.profiles add column if not exists deactivated_at timestamptz;
-- Último modo usado: o app abre nele no próximo login (pendência P20).
alter table public.profiles add column if not exists last_mode text
  check (last_mode in ('professional', 'recruiter'));

-- Índice espacial: acelera a busca de profissionais por raio.
create index if not exists profiles_location_idx
  on public.profiles using gist (location);


-- -----------------------------------------------------------------------------
-- 3. VAGAS (jobs)
-- Oportunidades publicadas por CONTRATANTES: o que, quando, onde e quanto.
-- -----------------------------------------------------------------------------
create table if not exists public.jobs (
  id uuid primary key default gen_random_uuid(),
  recruiter_id uuid not null references public.profiles (id) on delete cascade,

  title text not null,                          -- ex.: 'Videomaker para casamento'
  description text not null default '',
  required_role text not null,                  -- função procurada
  fee numeric(10, 2) not null check (fee >= 0), -- cachê em R$

  -- QUANDO: período do trabalho (diária, gravação...).
  starts_at timestamptz not null,
  ends_at timestamptz not null,

  -- ONDE: local da gravação.
  address text,
  city text,
  state text,
  latitude double precision not null,
  longitude double precision not null,
  location extensions.geography(Point, 4326) generated always as (
    extensions.st_setsrid(extensions.st_makepoint(longitude, latitude), 4326)::extensions.geography
  ) stored,

  -- 'aberta' (recebendo candidaturas) ou 'encerrada'.
  status text not null default 'aberta' check (status in ('aberta', 'encerrada')),

  created_at timestamptz not null default now(),

  -- Regra: o fim precisa ser depois do início.
  constraint jobs_period_check check (ends_at > starts_at)
);

create index if not exists jobs_location_idx on public.jobs using gist (location);
create index if not exists jobs_recruiter_idx on public.jobs (recruiter_id);


-- -----------------------------------------------------------------------------
-- 4. CANDIDATURAS (job_applications)
-- Liga um PROFISSIONAL a uma VAGA. O contratante muda o status.
-- -----------------------------------------------------------------------------
create table if not exists public.job_applications (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs (id) on delete cascade,
  professional_id uuid not null references public.profiles (id) on delete cascade,

  cover_message text,  -- mensagem de apresentação enviada com a candidatura

  -- Fluxo do processo seletivo (detalhado na seção 12):
  --   pendente -> aprovado_entrevista -> proposta_enviada -> contratado
  --       |               |                    \-> proposta_recusada
  --       \-> reprovado <-/
  status text not null default 'pendente'
    constraint job_applications_status_check
    check (status in ('pendente', 'aprovado_entrevista', 'reprovado',
                      'proposta_enviada', 'contratado', 'proposta_recusada')),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- Regra: um profissional só pode se candidatar UMA vez à mesma vaga.
  constraint job_applications_unique unique (job_id, professional_id)
);

create index if not exists job_applications_job_idx on public.job_applications (job_id);
create index if not exists job_applications_professional_idx
  on public.job_applications (professional_id);


-- -----------------------------------------------------------------------------
-- 5. CHAT (conversations + messages) — usado nas próximas partes
-- Uma conversa entre duas pessoas (como no LinkedIn), opcionalmente ligada
-- a uma vaga. As mensagens chegam em TEMPO REAL (Supabase Realtime).
-- -----------------------------------------------------------------------------
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references public.jobs (id) on delete set null,
  participant_a uuid not null references public.profiles (id) on delete cascade,
  participant_b uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now(),
  constraint conversations_distinct_participants check (participant_a <> participant_b)
);

-- Impede duas conversas iguais entre as mesmas pessoas sobre a mesma vaga
-- (a ordem dos participantes não importa: usa o menor e o maior id).
create unique index if not exists conversations_unique_pair on public.conversations (
  least(participant_a, participant_b),
  greatest(participant_a, participant_b),
  coalesce(job_id, '00000000-0000-0000-0000-000000000000'::uuid)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  content text not null check (char_length(content) between 1 and 2000),
  created_at timestamptz not null default now(),
  read_at timestamptz  -- quando o destinatário leu (nulo = não lida)
);

create index if not exists messages_conversation_idx
  on public.messages (conversation_id, created_at);


-- -----------------------------------------------------------------------------
-- 6. PAGAMENTOS EM CUSTÓDIA (payments) — SIMULADO (fluxo completo na seção 14)
-- Inspirado no "Garantia OLX": o contratante paga, o valor fica RETIDO na
-- plataforma e só é LIBERADO ao profissional quando os DOIS confirmam que o
-- trabalho foi realizado. Nenhum dinheiro real é movimentado.
-- -----------------------------------------------------------------------------
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null unique
    references public.job_applications (id) on delete cascade,
  payer_id uuid not null references public.profiles (id),  -- contratante
  payee_id uuid not null references public.profiles (id),  -- profissional
  amount numeric(10, 2) not null check (amount > 0),

  -- aguardando_pagamento -> retido -> liberado
  --                              \-> em_disputa / reembolsado
  status text not null default 'aguardando_pagamento'
    check (status in ('aguardando_pagamento', 'retido', 'liberado', 'reembolsado', 'em_disputa')),

  payer_confirmed boolean not null default false,  -- contratante confirmou?
  payee_confirmed boolean not null default false,  -- profissional confirmou?

  created_at timestamptz not null default now(),
  paid_at timestamptz,
  released_at timestamptz
);


-- -----------------------------------------------------------------------------
-- 7. GATILHOS (triggers)
-- -----------------------------------------------------------------------------

-- Cria o PERFIL automaticamente quando alguém se cadastra no app.
-- Os dados (nome e papéis) vêm do "metadata" enviado pelo app no cadastro.
-- O app CineCrew cria a conta SEM perfil ativo (os dois papéis em falso);
-- a pessoa escolhe o primeiro modo em seguida (TEL04).
-- "security definer": roda com permissão do dono, pois o usuário novo ainda
-- não tem permissão de inserir em profiles.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_professional boolean := coalesce((new.raw_user_meta_data ->> 'is_professional')::boolean, false);
  v_is_recruiter boolean := coalesce((new.raw_user_meta_data ->> 'is_recruiter')::boolean, false);
begin

  insert into public.profiles (id, email, full_name, is_professional, is_recruiter)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    v_is_professional,
    v_is_recruiter
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Atualiza a coluna updated_at sempre que a linha for alterada.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists job_applications_set_updated_at on public.job_applications;
create trigger job_applications_set_updated_at
  before update on public.job_applications
  for each row execute function public.set_updated_at();


-- -----------------------------------------------------------------------------
-- 8. FUNÇÕES DE BUSCA ESPACIAL (chamadas pelo app via "rpc")
-- -----------------------------------------------------------------------------

-- Busca PROFISSIONAIS dentro de um raio (km) a partir de um ponto,
-- com filtro opcional por função/habilidade. Usada pelo contratante.
-- O próprio usuário que está buscando não aparece no resultado.
--   ST_DWithin: "está a no máximo X metros?" (usa o índice espacial)
--   ST_Distance: distância exata em metros (dividimos por 1000 -> km)
create or replace function public.search_professionals(
  p_lat double precision,
  p_lng double precision,
  p_radius_km double precision,
  p_skill text default null
)
returns table (
  id uuid,
  name text,
  email text,
  phone text,
  primary_role text,
  secondary_skills text[],
  bio text,
  avatar_url text,
  address text,
  city text,
  state text,
  latitude double precision,
  longitude double precision,
  rating numeric,
  is_available boolean,
  distance_in_km double precision
)
language sql
stable
set search_path = public, extensions
as $$
  select
    p.id,
    p.full_name as name,
    p.email,
    p.phone,
    p.primary_role,
    p.secondary_skills,
    p.bio,
    p.avatar_url,
    null::text as address,
    p.city,
    p.state,
    p.latitude,
    p.longitude,
    p.rating,
    p.is_available,
    st_distance(p.location, st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography) / 1000.0
      as distance_in_km
  from public.profiles p
  where p.is_professional
    and p.id is distinct from auth.uid()
    and p.location is not null
    and st_dwithin(
      p.location,
      st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
      p_radius_km * 1000
    )
    and (
      p_skill is null
      or p.primary_role ilike '%' || p_skill || '%'
      or exists (
        select 1 from unnest(p.secondary_skills) as s(skill)
        where s.skill ilike '%' || p_skill || '%'
      )
    )
  order by distance_in_km;
$$;

-- Busca VAGAS ABERTAS no estilo Airbnb: ONDE (ponto + raio), QUANDO
-- (período) e QUAL FUNÇÃO. Usada pelo profissional.
-- A vaga entra no resultado se o período dela SE SOBREPÕE ao período buscado.
-- As vagas publicadas pelo próprio usuário não aparecem para ele.
create or replace function public.search_jobs(
  p_lat double precision,
  p_lng double precision,
  p_radius_km double precision,
  p_role text default null,
  p_date_from timestamptz default null,
  p_date_to timestamptz default null
)
returns table (
  id uuid,
  recruiter_id uuid,
  recruiter_name text,
  recruiter_avatar_url text,
  title text,
  description text,
  required_role text,
  fee numeric,
  starts_at timestamptz,
  ends_at timestamptz,
  address text,
  city text,
  state text,
  latitude double precision,
  longitude double precision,
  status text,
  created_at timestamptz,
  distance_in_km double precision
)
language sql
stable
set search_path = public, extensions
as $$
  select
    j.id,
    j.recruiter_id,
    r.full_name as recruiter_name,
    r.avatar_url as recruiter_avatar_url,
    j.title,
    j.description,
    j.required_role,
    j.fee,
    j.starts_at,
    j.ends_at,
    j.address,
    j.city,
    j.state,
    j.latitude,
    j.longitude,
    j.status,
    j.created_at,
    st_distance(j.location, st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography) / 1000.0
      as distance_in_km
  from public.jobs j
  join public.profiles r on r.id = j.recruiter_id
  where j.status = 'aberta'
    and j.recruiter_id is distinct from auth.uid()
    and r.deactivated_at is null      -- vagas de conta desativada somem
    and j.ends_at >= now()
    and st_dwithin(
      j.location,
      st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
      p_radius_km * 1000
    )
    and (p_role is null or j.required_role ilike '%' || p_role || '%')
    and (p_date_from is null or j.ends_at >= p_date_from)
    and (p_date_to is null or j.starts_at <= p_date_to)
  order by distance_in_km;
$$;

-- Somente usuários logados podem chamar as funções de busca.
revoke execute on function public.search_professionals(double precision, double precision, double precision, text) from public, anon;
revoke execute on function public.search_jobs(double precision, double precision, double precision, text, timestamptz, timestamptz) from public, anon;
grant execute on function public.search_professionals(double precision, double precision, double precision, text) to authenticated;
grant execute on function public.search_jobs(double precision, double precision, double precision, text, timestamptz, timestamptz) to authenticated;


-- -----------------------------------------------------------------------------
-- 9. SEGURANÇA POR LINHA (RLS)
-- Com RLS ligado, NADA é permitido até que uma "policy" libere.
-- -----------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.jobs enable row level security;
alter table public.job_applications enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.payments enable row level security;

-- PERFIS: qualquer usuário logado vê perfis (é um banco de talentos);
-- cada um só altera o PRÓPRIO perfil.
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles
  for select to authenticated using (true);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- VAGAS: todos os logados veem; só CONTRATANTES criam, e só em seu nome;
-- só o dono altera ou apaga.
drop policy if exists "jobs_select" on public.jobs;
create policy "jobs_select" on public.jobs
  for select to authenticated using (true);

drop policy if exists "jobs_insert_recruiter" on public.jobs;
create policy "jobs_insert_recruiter" on public.jobs
  for insert to authenticated
  with check (
    recruiter_id = auth.uid()
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.is_recruiter
    )
  );

drop policy if exists "jobs_update_own" on public.jobs;
create policy "jobs_update_own" on public.jobs
  for update to authenticated
  using (recruiter_id = auth.uid()) with check (recruiter_id = auth.uid());

drop policy if exists "jobs_delete_own" on public.jobs;
create policy "jobs_delete_own" on public.jobs
  for delete to authenticated using (recruiter_id = auth.uid());

-- CANDIDATURAS: veem o próprio candidato e o contratante dono da vaga.
drop policy if exists "applications_select" on public.job_applications;
create policy "applications_select" on public.job_applications
  for select to authenticated
  using (
    professional_id = auth.uid()
    or exists (
      select 1 from public.jobs j
      where j.id = job_id and j.recruiter_id = auth.uid()
    )
  );

-- Só PROFISSIONAIS se candidatam, em seu nome, com status 'pendente',
-- apenas a vagas ABERTAS e nunca a uma vaga publicada por eles mesmos.
drop policy if exists "applications_insert_professional" on public.job_applications;
create policy "applications_insert_professional" on public.job_applications
  for insert to authenticated
  with check (
    professional_id = auth.uid()
    and status = 'pendente'
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.is_professional
    )
    and exists (
      select 1 from public.jobs j
      where j.id = job_id and j.status = 'aberta' and j.recruiter_id <> auth.uid()
    )
  );

-- Só o CONTRATANTE dono da vaga muda o status (aprovar/reprovar/contratar).
drop policy if exists "applications_update_recruiter" on public.job_applications;
create policy "applications_update_recruiter" on public.job_applications
  for update to authenticated
  using (
    exists (
      select 1 from public.jobs j
      where j.id = job_id and j.recruiter_id = auth.uid()
    )
  );

-- O profissional pode CANCELAR (apagar) a candidatura enquanto estiver pendente.
drop policy if exists "applications_delete_own_pending" on public.job_applications;
create policy "applications_delete_own_pending" on public.job_applications
  for delete to authenticated
  using (professional_id = auth.uid() and status = 'pendente');

-- CONVERSAS: só os dois participantes veem e criam.
drop policy if exists "conversations_select" on public.conversations;
create policy "conversations_select" on public.conversations
  for select to authenticated
  using (auth.uid() in (participant_a, participant_b));

drop policy if exists "conversations_insert" on public.conversations;
create policy "conversations_insert" on public.conversations
  for insert to authenticated
  with check (auth.uid() in (participant_a, participant_b));

drop policy if exists "conversations_update" on public.conversations;
create policy "conversations_update" on public.conversations
  for update to authenticated
  using (auth.uid() in (participant_a, participant_b));

-- MENSAGENS: só participantes da conversa leem; só envia em nome próprio.
drop policy if exists "messages_select" on public.messages;
create policy "messages_select" on public.messages
  for select to authenticated
  using (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id and auth.uid() in (c.participant_a, c.participant_b)
    )
  );

drop policy if exists "messages_insert" on public.messages;
create policy "messages_insert" on public.messages
  for insert to authenticated
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.conversations c
      where c.id = conversation_id and auth.uid() in (c.participant_a, c.participant_b)
    )
  );

-- Permite marcar como lida (o destinatário atualiza read_at).
drop policy if exists "messages_update_read" on public.messages;
create policy "messages_update_read" on public.messages
  for update to authenticated
  using (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id and auth.uid() in (c.participant_a, c.participant_b)
    )
  );

-- PAGAMENTOS: só pagador e recebedor veem. As alterações são feitas pelas
-- funções seguras do banco (seção 14), não direto pelo app.
drop policy if exists "payments_select" on public.payments;
create policy "payments_select" on public.payments
  for select to authenticated
  using (auth.uid() in (payer_id, payee_id));


-- -----------------------------------------------------------------------------
-- 10. TEMPO REAL
-- Publica as novas mensagens para o app receber instantaneamente (chat).
-- -----------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end;
$$;


-- -----------------------------------------------------------------------------
-- 11. ARMAZENAMENTO DE ARQUIVOS (Storage)
--   avatars: fotos de perfil (pública, qualquer um vê pela URL)
--   resumes: currículos em PDF (privada, só usuários logados leem)
-- Cada usuário só grava dentro da pasta com o PRÓPRIO id: "<id>/arquivo".
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true), ('resumes', 'resumes', false)
on conflict (id) do nothing;

drop policy if exists "avatars_read" on storage.objects;
create policy "avatars_read" on storage.objects
  for select to authenticated using (bucket_id = 'avatars');

drop policy if exists "avatars_insert_own" on storage.objects;
create policy "avatars_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars_update_own" on storage.objects;
create policy "avatars_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "resumes_read" on storage.objects;
create policy "resumes_read" on storage.objects
  for select to authenticated using (bucket_id = 'resumes');

drop policy if exists "resumes_insert_own" on storage.objects;
create policy "resumes_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'resumes' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "resumes_update_own" on storage.objects;
create policy "resumes_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'resumes' and (storage.foldername(name))[1] = auth.uid()::text);


-- -----------------------------------------------------------------------------
-- 12. PROCESSO SELETIVO: REGRAS DE STATUS, CONVERSA E NOTIFICAÇÕES
--
--   pendente ──► aprovado_entrevista ──► proposta_enviada ──► contratado
--      │                 │                      └──────────► proposta_recusada
--      └──► reprovado ◄──┘
--
--   * O CONTRATANTE (dono da vaga) faz: aprovar p/ entrevista, reprovar e
--     enviar proposta ("Contratar").
--   * O PROFISSIONAL decide se ACEITA ou RECUSA a proposta.
--   * Ao aceitar, o banco cria automaticamente a CONVERSA entre os dois:
--     o chat só é liberado depois do aceite.
--   * Cada mudança gera uma NOTIFICAÇÃO para a outra pessoa.
-- -----------------------------------------------------------------------------

-- Migração para bancos criados com a versão anterior (4 status).
alter table public.job_applications drop constraint if exists job_applications_status_check;
alter table public.job_applications add constraint job_applications_status_check
  check (status in ('pendente', 'aprovado_entrevista', 'reprovado',
                    'proposta_enviada', 'contratado', 'proposta_recusada'));

-- O profissional também pode ATUALIZAR a própria candidatura
-- (para aceitar/recusar a proposta). O gatilho abaixo garante que ele só
-- consegue fazer as mudanças permitidas a ele.
drop policy if exists "applications_update_professional" on public.job_applications;
create policy "applications_update_professional" on public.job_applications
  for update to authenticated
  using (professional_id = auth.uid()) with check (professional_id = auth.uid());

-- GATILHO DE VALIDAÇÃO: confere se a mudança de status é permitida e se
-- QUEM está mudando tem esse direito. Roda ANTES de gravar.
create or replace function public.validate_application_status()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_recruiter_id uuid;
  v_actor uuid := auth.uid();  -- usuário que está fazendo a alteração
begin
  -- Nada a validar se o status não mudou.
  if new.status = old.status then
    return new;
  end if;

  select recruiter_id into v_recruiter_id from public.jobs where id = new.job_id;

  -- Mudanças feitas pelo CONTRATANTE.
  if (old.status, new.status) in (
       ('pendente', 'aprovado_entrevista'),
       ('pendente', 'reprovado'),
       ('aprovado_entrevista', 'reprovado'),
       ('aprovado_entrevista', 'proposta_enviada')
     ) then
    if v_actor is distinct from v_recruiter_id then
      raise exception 'Apenas o contratante da vaga pode fazer esta alteração.'
        using errcode = '42501';
    end if;
    return new;
  end if;

  -- Mudanças feitas pelo PROFISSIONAL (responder à proposta).
  if (old.status, new.status) in (
       ('proposta_enviada', 'contratado'),
       ('proposta_enviada', 'proposta_recusada')
     ) then
    if v_actor is distinct from new.professional_id then
      raise exception 'Apenas o profissional pode responder à proposta.'
        using errcode = '42501';
    end if;
    return new;
  end if;

  -- Qualquer outra mudança é proibida (ex.: pular etapas).
  raise exception 'Mudança de status não permitida: % -> %', old.status, new.status
    using errcode = '23514';
end;
$$;

drop trigger if exists job_applications_validate_status on public.job_applications;
create trigger job_applications_validate_status
  before update of status on public.job_applications
  for each row execute function public.validate_application_status();

-- NOTIFICAÇÕES: avisos que aparecem no sino 🔔 do app.
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,  -- quem recebe
  title text not null,
  body text not null,
  application_id uuid references public.job_applications (id) on delete cascade,
  created_at timestamptz not null default now(),
  read_at timestamptz  -- nulo = ainda não lida
);

create index if not exists notifications_user_idx
  on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;

-- Cada um só vê e marca como lidas as PRÓPRIAS notificações.
-- (Quem cria as notificações é o banco, pelos gatilhos abaixo.)
drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own" on public.notifications
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own" on public.notifications
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- GATILHO DE EVENTOS: depois de gravar, cria as notificações e, quando a
-- proposta é aceita, abre a conversa entre contratante e profissional.
-- "security definer": precisa de permissão para inserir notificações e
-- conversas em nome do sistema.
create or replace function public.on_application_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_job_title text;
  v_recruiter_id uuid;
  v_professional_name text;
begin
  select title, recruiter_id into v_job_title, v_recruiter_id
    from public.jobs where id = new.job_id;
  select full_name into v_professional_name
    from public.profiles where id = new.professional_id;

  -- Nova candidatura: avisa o contratante.
  if tg_op = 'INSERT' then
    insert into public.notifications (user_id, title, body, application_id)
    values (v_recruiter_id, 'Nova candidatura',
            coalesce(v_professional_name, 'Um profissional') ||
            ' se candidatou à vaga "' || v_job_title || '".', new.id);
    return new;
  end if;

  -- A partir daqui: UPDATE. Só interessa se o status mudou.
  if new.status = old.status then
    return new;
  end if;

  if new.status = 'aprovado_entrevista' then
    insert into public.notifications (user_id, title, body, application_id)
    values (new.professional_id, 'Você foi aprovado para entrevista! 🎬',
            'Sua candidatura para "' || v_job_title ||
            '" avançou. Aguarde o contato do contratante.', new.id);

  elsif new.status = 'reprovado' then
    insert into public.notifications (user_id, title, body, application_id)
    values (new.professional_id, 'Candidatura não selecionada',
            'Infelizmente você não foi selecionado para "' || v_job_title ||
            '". Continue se candidatando: novas vagas surgem todos os dias!', new.id);

  elsif new.status = 'proposta_enviada' then
    insert into public.notifications (user_id, title, body, application_id)
    values (new.professional_id, 'Você recebeu uma proposta! 🎉',
            'O contratante quer te contratar para "' || v_job_title ||
            '". Abra suas candidaturas para aceitar ou recusar.', new.id);

  elsif new.status = 'contratado' then
    insert into public.notifications (user_id, title, body, application_id)
    values (v_recruiter_id, 'Proposta aceita',
            coalesce(v_professional_name, 'O profissional') ||
            ' aceitou a proposta para "' || v_job_title ||
            '". O chat entre vocês foi liberado.', new.id);

    -- Abre a conversa (se já existir uma igual, não duplica).
    insert into public.conversations (job_id, participant_a, participant_b)
    values (new.job_id, v_recruiter_id, new.professional_id)
    on conflict do nothing;

  elsif new.status = 'proposta_recusada' then
    insert into public.notifications (user_id, title, body, application_id)
    values (v_recruiter_id, 'Proposta recusada',
            coalesce(v_professional_name, 'O profissional') ||
            ' recusou a proposta para "' || v_job_title || '".', new.id);
  end if;

  return new;
end;
$$;

drop trigger if exists job_applications_events on public.job_applications;
create trigger job_applications_events
  after insert or update of status on public.job_applications
  for each row execute function public.on_application_event();

-- Publica as notificações em tempo real (o sino atualiza sozinho).
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end;
$$;


-- -----------------------------------------------------------------------------
-- 13. CHAT: LISTA DE CONVERSAS E REFORÇO DE SEGURANÇA
-- -----------------------------------------------------------------------------

-- Lista as conversas do usuário logado, já com:
--   * o nome e a foto da OUTRA pessoa;
--   * o título da vaga que originou a conversa;
--   * a última mensagem e o horário dela;
--   * quantas mensagens ainda não foram lidas.
-- Ordenada da conversa mais recente para a mais antiga.
-- "security invoker" (padrão): as regras de RLS continuam valendo.
create or replace function public.get_my_conversations()
returns table (
  id uuid,
  job_id uuid,
  job_title text,
  other_user_id uuid,
  other_user_name text,
  other_user_avatar_url text,
  last_message text,
  last_message_at timestamptz,
  unread_count bigint
)
language sql
stable
set search_path = public
as $$
  select
    c.id,
    c.job_id,
    j.title,
    o.id,
    o.full_name,
    o.avatar_url,
    lm.content,
    coalesce(lm.created_at, c.created_at),
    (
      select count(*) from public.messages m
      where m.conversation_id = c.id
        and m.sender_id <> auth.uid()
        and m.read_at is null
    )
  from public.conversations c
  -- "o" = a outra pessoa da conversa (quem não é o usuário logado).
  join public.profiles o
    on o.id = case when c.participant_a = auth.uid() then c.participant_b else c.participant_a end
  left join public.jobs j on j.id = c.job_id
  -- "lateral": para cada conversa, busca só a ÚLTIMA mensagem.
  left join lateral (
    select m.content, m.created_at from public.messages m
    where m.conversation_id = c.id
    order by m.created_at desc
    limit 1
  ) lm on true
  where auth.uid() in (c.participant_a, c.participant_b)
  order by coalesce(lm.created_at, c.created_at) desc;
$$;

revoke execute on function public.get_my_conversations() from public, anon;
grant execute on function public.get_my_conversations() to authenticated;

-- REFORÇO DE SEGURANÇA (permissões por COLUNA):
-- as regras de RLS dizem QUAIS LINHAS cada um pode alterar; aqui limitamos
-- QUAIS COLUNAS. Ex.: no chat, o participante só pode marcar a mensagem como
-- lida (read_at) — não pode editar o texto de uma mensagem já enviada.
revoke update on public.messages from authenticated;
grant update (read_at) on public.messages to authenticated;

revoke update on public.notifications from authenticated;
grant update (read_at) on public.notifications to authenticated;

-- Na candidatura, só o STATUS pode mudar (e o gatilho valida a mudança).
revoke update on public.job_applications from authenticated;
grant update (status) on public.job_applications to authenticated;

-- No perfil, o usuário não pode alterar a própria AVALIAÇÃO (rating),
-- o id, o e-mail nem as datas de controle.
revoke update on public.profiles from authenticated;
grant update (
  full_name, phone, is_professional, is_recruiter, primary_role,
  secondary_skills, bio, avatar_url, resume_path, company_name,
  city, state, latitude, longitude, is_available
) on public.profiles to authenticated;


-- -----------------------------------------------------------------------------
-- 14. GARANTIA, CARTEIRA E SAQUES (tudo SIMULADO — nenhum dinheiro real)
-- -----------------------------------------------------------------------------
-- Fluxo inspirado na Garantia OLX:
--
--   proposta aceita ──► aguardando_pagamento ──► retido 🔒 ──► liberado ✅
--   (o banco cria o       (contratante "paga")    (os DOIS confirmam  └─► crédito na
--    pagamento sozinho)                            o serviço)              CARTEIRA do
--                                   └──► em_disputa (qualquer um dos dois)  profissional
--
--   CARTEIRA: extrato (wallet_entries) com entradas (+) e saídas (-).
--             saldo = soma do extrato.
--   SAQUE:    o profissional cadastra a conta (Pix ou TED) e pede o saque;
--             o valor sai da carteira e o saque fica registrado.
--
-- Todas as mudanças de dinheiro passam por FUNÇÕES do banco (security
-- definer) que conferem quem está pedindo e o estado atual. O app não pode
-- inserir nem alterar essas tabelas diretamente.
-- -----------------------------------------------------------------------------

-- Campos extras do pagamento para a disputa.
alter table public.payments add column if not exists dispute_reason text;
alter table public.payments add column if not exists disputed_by uuid
  references public.profiles (id);

-- CONTA PARA RECEBER (uma por usuário). Pode ter Pix, conta para TED ou os dois.
create table if not exists public.payout_accounts (
  user_id uuid primary key references public.profiles (id) on delete cascade,

  -- Titular: nome e CPF/CNPJ (somente números: 11 ou 14 dígitos).
  holder_name text not null check (char_length(holder_name) between 3 and 120),
  holder_document text not null check (holder_document ~ '^([0-9]{11}|[0-9]{14})$'),

  -- PIX (opcional)
  pix_key_type text check (pix_key_type in ('cpf', 'cnpj', 'email', 'telefone', 'aleatoria')),
  pix_key text check (char_length(pix_key) between 3 and 140),

  -- TED (opcional): código do banco (3 dígitos), agência, conta e tipo.
  bank_code text check (bank_code ~ '^[0-9]{3}$'),
  bank_name text,
  agency text check (agency ~ '^[0-9]{1,5}$'),
  account_number text check (account_number ~ '^[0-9]{1,13}(-[0-9Xx])?$'),
  account_type text check (account_type in ('corrente', 'poupanca')),

  updated_at timestamptz not null default now(),

  -- Pix: tipo e chave andam juntos.
  constraint payout_pix_complete check ((pix_key is null) = (pix_key_type is null)),
  -- TED: ou preenche os 4 campos, ou nenhum.
  constraint payout_bank_complete
    check (num_nonnulls(bank_code, agency, account_number, account_type) in (0, 4)),
  -- Precisa de pelo menos uma forma de receber.
  constraint payout_has_method check (pix_key is not null or bank_code is not null)
);

drop trigger if exists payout_accounts_set_updated_at on public.payout_accounts;
create trigger payout_accounts_set_updated_at
  before update on public.payout_accounts
  for each row execute function public.set_updated_at();

alter table public.payout_accounts enable row level security;

-- Dados bancários: SÓ o próprio usuário vê e altera.
drop policy if exists "payout_accounts_own" on public.payout_accounts;
create policy "payout_accounts_own" on public.payout_accounts
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- SAQUES pedidos pelo usuário.
create table if not exists public.withdrawals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  amount numeric(12, 2) not null check (amount > 0),
  method text not null check (method in ('pix', 'ted')),
  -- Destino no momento do saque, já MASCARADO (ex.: "Pix · e-mail ••••.com").
  destination text not null,
  -- Simulação: o saque já nasce "concluido".
  status text not null default 'concluido'
    check (status in ('processando', 'concluido', 'falhou')),
  created_at timestamptz not null default now()
);

create index if not exists withdrawals_user_idx
  on public.withdrawals (user_id, created_at desc);

-- EXTRATO DA CARTEIRA: cada linha é uma entrada (+) ou saída (-).
create table if not exists public.wallet_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  amount numeric(12, 2) not null check (amount <> 0),
  description text not null,
  payment_id uuid references public.payments (id) on delete set null,
  withdrawal_id uuid references public.withdrawals (id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists wallet_entries_user_idx
  on public.wallet_entries (user_id, created_at desc);

-- Garante que um pagamento NUNCA é creditado duas vezes.
create unique index if not exists wallet_entries_payment_unique
  on public.wallet_entries (payment_id) where payment_id is not null;

alter table public.withdrawals enable row level security;
alter table public.wallet_entries enable row level security;

drop policy if exists "withdrawals_select_own" on public.withdrawals;
create policy "withdrawals_select_own" on public.withdrawals
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "wallet_entries_select_own" on public.wallet_entries;
create policy "wallet_entries_select_own" on public.wallet_entries
  for select to authenticated using (user_id = auth.uid());

-- Dinheiro só muda pelas funções abaixo: o app apenas LÊ estas tabelas.
revoke insert, update, delete on public.payments from authenticated, anon;
revoke insert, update, delete on public.withdrawals from authenticated, anon;
revoke insert, update, delete on public.wallet_entries from authenticated, anon;

-- Formata um valor em reais para as notificações: 1500.5 -> "R$ 1.500,50".
create or replace function public.format_brl(p_value numeric)
returns text
language sql
immutable
as $$
  select 'R$ ' || translate(to_char(p_value, 'FM999G999G990D00'), ',.', '.,');
$$;

-- Ao ACEITAR a proposta (status -> contratado), cria o pagamento em garantia
-- com o valor do cachê da vaga. Vagas com cachê zero não geram pagamento.
create or replace function public.create_payment_on_hire()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_job record;
begin
  if new.status = 'contratado' and old.status is distinct from 'contratado' then
    select recruiter_id, fee into v_job from public.jobs where id = new.job_id;
    if v_job.fee > 0 then
      insert into public.payments (application_id, payer_id, payee_id, amount)
      values (new.id, v_job.recruiter_id, new.professional_id, v_job.fee)
      on conflict (application_id) do nothing;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists job_applications_create_payment on public.job_applications;
create trigger job_applications_create_payment
  after update of status on public.job_applications
  for each row execute function public.create_payment_on_hire();

-- Contratações feitas ANTES desta parte também ganham o pagamento.
insert into public.payments (application_id, payer_id, payee_id, amount)
select a.id, j.recruiter_id, a.professional_id, j.fee
from public.job_applications a
join public.jobs j on j.id = a.job_id
where a.status = 'contratado' and j.fee > 0
on conflict (application_id) do nothing;

-- Busca o pagamento TRAVADO (for update) e confere se quem pede participa.
-- O "for update" impede que dois pedidos ao mesmo tempo bagunçem o estado.
create or replace function public.lock_my_payment(p_payment_id uuid)
returns public.payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payment public.payments;
begin
  select * into v_payment from public.payments where id = p_payment_id for update;
  if not found or auth.uid() is null
     or auth.uid() not in (v_payment.payer_id, v_payment.payee_id) then
    raise exception 'Pagamento não encontrado.' using errcode = 'P0002';
  end if;
  return v_payment;
end;
$$;

-- Título da vaga de um pagamento (para o texto das notificações).
create or replace function public.payment_job_title(p_payment public.payments)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select j.title from public.job_applications a
  join public.jobs j on j.id = a.job_id
  where a.id = p_payment.application_id;
$$;

-- 1) CONTRATANTE PAGA (simulado): o valor fica RETIDO na plataforma.
create or replace function public.pay_escrow(p_payment_id uuid)
returns public.payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payment public.payments := public.lock_my_payment(p_payment_id);
begin
  if auth.uid() <> v_payment.payer_id then
    raise exception 'Apenas o contratante pode fazer o pagamento.' using errcode = 'P0001';
  end if;
  if v_payment.status <> 'aguardando_pagamento' then
    raise exception 'Este pagamento já foi realizado.' using errcode = 'P0001';
  end if;

  update public.payments
     set status = 'retido', paid_at = now()
   where id = p_payment_id
  returning * into v_payment;

  insert into public.notifications (user_id, title, body, application_id)
  values (v_payment.payee_id, 'Pagamento em garantia 🔒',
          'O contratante pagou ' || public.format_brl(v_payment.amount) || ' por "' ||
          public.payment_job_title(v_payment) || '". O valor fica guardado e é ' ||
          'liberado quando vocês dois confirmarem o serviço.',
          v_payment.application_id);

  return v_payment;
end;
$$;

-- 2) CONFIRMAR O SERVIÇO: cada um confirma a sua parte. Quando os DOIS
--    confirmam, o pagamento é LIBERADO e o valor entra na carteira do
--    profissional.
create or replace function public.confirm_service(p_payment_id uuid)
returns public.payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payment public.payments := public.lock_my_payment(p_payment_id);
  v_is_payer boolean := auth.uid() = v_payment.payer_id;
  v_title text := public.payment_job_title(v_payment);
begin
  if v_payment.status <> 'retido' then
    raise exception 'Só é possível confirmar quando o valor está em garantia.'
      using errcode = 'P0001';
  end if;
  if (v_is_payer and v_payment.payer_confirmed)
     or (not v_is_payer and v_payment.payee_confirmed) then
    raise exception 'Você já confirmou este serviço.' using errcode = 'P0001';
  end if;

  update public.payments
     set payer_confirmed = payer_confirmed or v_is_payer,
         payee_confirmed = payee_confirmed or not v_is_payer
   where id = p_payment_id
  returning * into v_payment;

  if v_payment.payer_confirmed and v_payment.payee_confirmed then
    -- Os dois confirmaram: libera e credita na carteira do profissional.
    update public.payments
       set status = 'liberado', released_at = now()
     where id = p_payment_id
    returning * into v_payment;

    insert into public.wallet_entries (user_id, amount, description, payment_id)
    values (v_payment.payee_id, v_payment.amount,
            'Pagamento recebido: ' || v_title, v_payment.id);

    insert into public.notifications (user_id, title, body, application_id)
    values
      (v_payment.payee_id, 'Pagamento liberado ✅',
       public.format_brl(v_payment.amount) || ' de "' || v_title ||
       '" entrou na sua carteira. Você já pode sacar via Pix ou TED.',
       v_payment.application_id),
      (v_payment.payer_id, 'Pagamento liberado ✅',
       'O pagamento de "' || v_title || '" foi liberado ao profissional.',
       v_payment.application_id);
  else
    -- Só um confirmou: avisa o outro.
    insert into public.notifications (user_id, title, body, application_id)
    values (
      case when v_is_payer then v_payment.payee_id else v_payment.payer_id end,
      'Confirmação de serviço',
      case when v_is_payer then 'O contratante' else 'O profissional' end ||
        ' confirmou que o serviço de "' || v_title ||
        '" foi realizado. Confirme também para liberar o pagamento.',
      v_payment.application_id);
  end if;

  return v_payment;
end;
$$;

-- 3) ABRIR DISPUTA: algo deu errado; o valor continua retido até a
--    plataforma analisar (na simulação, a análise não é implementada).
create or replace function public.open_payment_dispute(p_payment_id uuid, p_reason text)
returns public.payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payment public.payments := public.lock_my_payment(p_payment_id);
  v_reason text := btrim(coalesce(p_reason, ''));
begin
  if v_payment.status <> 'retido' then
    raise exception 'Só é possível abrir disputa enquanto o valor está em garantia.'
      using errcode = 'P0001';
  end if;
  if char_length(v_reason) < 10 or char_length(v_reason) > 1000 then
    raise exception 'Descreva o problema com 10 a 1000 caracteres.' using errcode = 'P0001';
  end if;

  update public.payments
     set status = 'em_disputa', dispute_reason = v_reason, disputed_by = auth.uid()
   where id = p_payment_id
  returning * into v_payment;

  insert into public.notifications (user_id, title, body, application_id)
  values (
    case when auth.uid() = v_payment.payer_id then v_payment.payee_id else v_payment.payer_id end,
    'Disputa aberta ⚠️',
    'Foi aberta uma disputa sobre o pagamento de "' || public.payment_job_title(v_payment) ||
      '". O valor continua guardado até a análise.',
    v_payment.application_id);

  return v_payment;
end;
$$;

-- SALDO da carteira do usuário logado (soma do extrato).
create or replace function public.get_wallet_balance()
returns numeric
language sql
stable
set search_path = public
as $$
  select coalesce(sum(amount), 0)::numeric(12, 2)
  from public.wallet_entries where user_id = auth.uid();
$$;

-- 4) SACAR (simulado): tira o valor da carteira e registra o saque para a
--    conta cadastrada (Pix ou TED).
create or replace function public.request_withdrawal(p_amount numeric, p_method text)
returns public.withdrawals
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_account public.payout_accounts;
  v_balance numeric;
  v_destination text;
  v_withdrawal public.withdrawals;
begin
  if v_uid is null then
    raise exception 'Faça login novamente.' using errcode = 'P0001';
  end if;
  if p_amount is null or p_amount <= 0 or round(p_amount, 2) <> p_amount then
    raise exception 'Informe um valor de saque válido.' using errcode = 'P0001';
  end if;

  -- Trava o perfil: dois saques ao mesmo tempo não conseguem usar o mesmo saldo.
  perform 1 from public.profiles where id = v_uid for update;

  select * into v_account from public.payout_accounts where user_id = v_uid;
  if not found then
    raise exception 'Cadastre sua conta para receber antes de sacar.' using errcode = 'P0001';
  end if;

  if p_method = 'pix' then
    if v_account.pix_key is null then
      raise exception 'Cadastre uma chave Pix para sacar via Pix.' using errcode = 'P0001';
    end if;
    v_destination := 'Pix · ' || v_account.pix_key_type || ' ••••' || right(v_account.pix_key, 4);
  elsif p_method = 'ted' then
    if v_account.bank_code is null then
      raise exception 'Cadastre uma conta bancária para sacar via TED.' using errcode = 'P0001';
    end if;
    v_destination := 'TED · Banco ' || v_account.bank_code || ' · Ag. ' || v_account.agency ||
                     ' · Conta ••••' || right(v_account.account_number, 4);
  else
    raise exception 'Forma de saque inválida.' using errcode = 'P0001';
  end if;

  select coalesce(sum(amount), 0) into v_balance
    from public.wallet_entries where user_id = v_uid;
  if p_amount > v_balance then
    raise exception 'Saldo insuficiente. Disponível: %', public.format_brl(v_balance)
      using errcode = 'P0001';
  end if;

  insert into public.withdrawals (user_id, amount, method, destination)
  values (v_uid, p_amount, p_method, v_destination)
  returning * into v_withdrawal;

  insert into public.wallet_entries (user_id, amount, description, withdrawal_id)
  values (v_uid, -p_amount, 'Saque · ' || v_destination, v_withdrawal.id);

  insert into public.notifications (user_id, title, body)
  values (v_uid, 'Saque realizado 💸',
          public.format_brl(p_amount) || ' enviado para ' || v_destination ||
          ' (simulação: nenhum valor real foi transferido).');

  return v_withdrawal;
end;
$$;

-- Quem pode chamar cada função: só usuários logados.
-- (As funções auxiliares não são chamadas pelo app.)
revoke execute on function public.lock_my_payment(uuid) from public, anon, authenticated;
revoke execute on function public.payment_job_title(public.payments) from public, anon, authenticated;
revoke execute on function public.create_payment_on_hire() from public, anon, authenticated;
revoke execute on function public.pay_escrow(uuid) from public, anon;
revoke execute on function public.confirm_service(uuid) from public, anon;
revoke execute on function public.open_payment_dispute(uuid, text) from public, anon;
revoke execute on function public.get_wallet_balance() from public, anon;
revoke execute on function public.request_withdrawal(numeric, text) from public, anon;
grant execute on function public.pay_escrow(uuid) to authenticated;
grant execute on function public.confirm_service(uuid) to authenticated;
grant execute on function public.open_payment_dispute(uuid, text) to authenticated;
grant execute on function public.get_wallet_balance() to authenticated;
grant execute on function public.request_withdrawal(numeric, text) to authenticated;

-- Tempo real: a tela de garantia e a carteira atualizam sozinhas.
do $$
declare
  v_table text;
begin
  foreach v_table in array array['payments', 'wallet_entries'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = v_table
    ) then
      execute format('alter publication supabase_realtime add table public.%I', v_table);
    end if;
  end loop;
end;
$$;


-- -----------------------------------------------------------------------------
-- 15. AVALIAÇÕES (estrelas + comentário, como as recomendações do LinkedIn)
-- -----------------------------------------------------------------------------
-- Depois da contratação (e do pagamento liberado, quando a vaga tem cachê),
-- contratante e profissional avaliam UM AO OUTRO: nota de 1 a 5 estrelas e
-- um comentário opcional. Cada lado avalia uma única vez por contratação.
-- A média fica gravada no perfil (profiles.rating) e as avaliações são
-- PÚBLICAS para quem está logado, para ajudar na escolha de quem contratar.
-- -----------------------------------------------------------------------------

-- Quantidade de avaliações recebidas (a média já existe: profiles.rating).
alter table public.profiles add column if not exists reviews_count integer not null default 0;

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.job_applications (id) on delete cascade,
  reviewer_id uuid not null references public.profiles (id) on delete cascade,  -- quem avalia
  reviewee_id uuid not null references public.profiles (id) on delete cascade,  -- quem é avaliado
  rating smallint not null check (rating between 1 and 5),
  comment text check (char_length(comment) <= 500),
  created_at timestamptz not null default now(),

  -- Uma avaliação de cada lado por contratação; ninguém avalia a si mesmo.
  constraint reviews_one_per_side unique (application_id, reviewer_id),
  constraint reviews_not_self check (reviewer_id <> reviewee_id)
);

create index if not exists reviews_reviewee_idx
  on public.reviews (reviewee_id, created_at desc);

alter table public.reviews enable row level security;

-- Avaliações são públicas para usuários logados.
drop policy if exists "reviews_select" on public.reviews;
create policy "reviews_select" on public.reviews
  for select to authenticated using (true);

-- Criar avaliação só pela função abaixo (que confere as regras).
revoke insert, update, delete on public.reviews from authenticated, anon;

-- Envia uma avaliação. Regras:
--   * só quem participou da contratação (contratante ou profissional);
--   * só com a candidatura em "contratado";
--   * se a vaga tem pagamento em garantia, só depois de LIBERADO;
--   * uma avaliação por lado (a segunda tentativa é recusada).
create or replace function public.submit_review(
  p_application_id uuid,
  p_rating integer,
  p_comment text
)
returns public.reviews
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_status text;
  v_professional_id uuid;
  v_recruiter_id uuid;
  v_job_title text;
  v_reviewee uuid;
  v_payment_status text;
  v_comment text := nullif(btrim(coalesce(p_comment, '')), '');
  v_review public.reviews;
  v_reviewer_name text;
begin
  select a.status, a.professional_id, j.recruiter_id, j.title
    into v_status, v_professional_id, v_recruiter_id, v_job_title
    from public.job_applications a
    join public.jobs j on j.id = a.job_id
   where a.id = p_application_id;

  if not found or v_uid is null or v_uid not in (v_professional_id, v_recruiter_id) then
    raise exception 'Contratação não encontrada.' using errcode = 'P0002';
  end if;
  if v_status <> 'contratado' then
    raise exception 'Só é possível avaliar depois da contratação.' using errcode = 'P0001';
  end if;

  select status into v_payment_status
    from public.payments where application_id = p_application_id;
  if found and v_payment_status <> 'liberado' then
    raise exception 'A avaliação fica disponível depois que o pagamento for liberado.'
      using errcode = 'P0001';
  end if;

  if p_rating is null or p_rating not between 1 and 5 then
    raise exception 'Escolha de 1 a 5 estrelas.' using errcode = 'P0001';
  end if;
  if char_length(v_comment) > 500 then
    raise exception 'O comentário pode ter no máximo 500 caracteres.' using errcode = 'P0001';
  end if;

  -- Quem é avaliado é sempre "o outro lado".
  v_reviewee := case when v_uid = v_recruiter_id then v_professional_id else v_recruiter_id end;

  begin
    insert into public.reviews (application_id, reviewer_id, reviewee_id, rating, comment)
    values (p_application_id, v_uid, v_reviewee, p_rating, v_comment)
    returning * into v_review;
  exception when unique_violation then
    raise exception 'Você já avaliou esta contratação.' using errcode = 'P0001';
  end;

  -- Recalcula a média (1 casa decimal) e a quantidade no perfil do avaliado.
  update public.profiles p
     set rating = s.average, reviews_count = s.total
    from (
      select round(avg(rating), 1) as average, count(*)::integer as total
      from public.reviews where reviewee_id = v_reviewee
    ) s
   where p.id = v_reviewee;

  select full_name into v_reviewer_name from public.profiles where id = v_uid;
  insert into public.notifications (user_id, title, body, application_id)
  values (v_reviewee, 'Nova avaliação ⭐',
          coalesce(nullif(v_reviewer_name, ''), 'Alguém') || ' te avaliou com ' ||
          p_rating || case when p_rating = 1 then ' estrela' else ' estrelas' end ||
          ' por "' || v_job_title || '".',
          p_application_id);

  return v_review;
end;
$$;

-- Avaliações recebidas por um usuário, com nome e foto de quem avaliou e o
-- título da vaga. Da mais recente para a mais antiga.
-- "security definer": as candidaturas são privadas (RLS), mas aqui só saem
-- campos públicos (nota, comentário, nome, foto e título da vaga).
create or replace function public.get_reviews(p_user_id uuid)
returns table (
  id uuid,
  rating smallint,
  comment text,
  created_at timestamptz,
  reviewer_name text,
  reviewer_avatar_url text,
  reviewer_was_recruiter boolean,
  job_title text
)
language sql
stable
security definer
set search_path = public
as $$
  select r.id, r.rating, r.comment, r.created_at,
         p.full_name, p.avatar_url,
         r.reviewer_id = j.recruiter_id,
         j.title
    from public.reviews r
    join public.profiles p on p.id = r.reviewer_id
    join public.job_applications a on a.id = r.application_id
    join public.jobs j on j.id = a.job_id
   where r.reviewee_id = p_user_id
   order by r.created_at desc
   limit 50;
$$;

revoke execute on function public.submit_review(uuid, integer, text) from public, anon;
revoke execute on function public.get_reviews(uuid) from public, anon;
grant execute on function public.submit_review(uuid, integer, text) to authenticated;
grant execute on function public.get_reviews(uuid) to authenticated;


-- -----------------------------------------------------------------------------
-- 16. PERFIL ESTILO LINKEDIN: capa, título, portfólio e experiências
-- -----------------------------------------------------------------------------
--   * headline:  "título profissional" abaixo do nome
--                (ex.: "Videomaker de casamentos · 8 anos de set");
--   * cover_url: foto de CAPA no topo do perfil;
--   * portfolio_items: fotos (enviadas para o Storage) e vídeos (links do
--     YouTube, Vimeo, Instagram...) dos trabalhos;
--   * experiences: trabalhos anteriores (função, produção, período).
-- Tudo é PÚBLICO para usuários logados e só o dono altera.
-- -----------------------------------------------------------------------------

alter table public.profiles add column if not exists headline text
  check (char_length(headline) <= 120);
alter table public.profiles add column if not exists cover_url text;

-- O próprio usuário pode alterar o título e a capa (seção 13 lista as demais).
grant update (headline, cover_url) on public.profiles to authenticated;

-- PASTA "portfolio" (pública): capa e fotos do portfólio, em "<id>/...".
insert into storage.buckets (id, name, public)
values ('portfolio', 'portfolio', true)
on conflict (id) do nothing;

drop policy if exists "portfolio_read" on storage.objects;
create policy "portfolio_read" on storage.objects
  for select to authenticated using (bucket_id = 'portfolio');

drop policy if exists "portfolio_insert_own" on storage.objects;
create policy "portfolio_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'portfolio' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "portfolio_update_own" on storage.objects;
create policy "portfolio_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'portfolio' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "portfolio_delete_own" on storage.objects;
create policy "portfolio_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'portfolio' and (storage.foldername(name))[1] = auth.uid()::text);

-- ITENS DO PORTFÓLIO: uma foto OU um vídeo (link).
create table if not exists public.portfolio_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  media_type text not null check (media_type in ('foto', 'video')),
  title text not null check (char_length(title) between 1 and 80),
  description text check (char_length(description) <= 500),
  image_path text,                                       -- foto: caminho no Storage
  video_url text check (video_url ~ '^https://'),        -- vídeo: link https
  created_at timestamptz not null default now(),

  -- Foto tem arquivo e não tem link; vídeo tem link e não tem arquivo.
  constraint portfolio_media_complete check (
    (media_type = 'foto' and image_path is not null and video_url is null) or
    (media_type = 'video' and video_url is not null and image_path is null)
  )
);

create index if not exists portfolio_items_user_idx
  on public.portfolio_items (user_id, created_at desc);

-- EXPERIÊNCIAS: trabalhos anteriores, como no LinkedIn.
create table if not exists public.experiences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null check (char_length(role) between 2 and 80),            -- função
  production text not null check (char_length(production) between 2 and 120), -- produção/empresa
  category text check (category in ('Filme', 'Série', 'Publicidade', 'Videoclipe',
                                    'Evento', 'Casamento', 'Institucional', 'Outro')),
  start_date date not null check (start_date >= date '1950-01-01'),
  end_date date,                                           -- nulo = trabalho atual
  description text check (char_length(description) <= 500),
  created_at timestamptz not null default now(),
  constraint experiences_period check (end_date is null or end_date >= start_date)
);

create index if not exists experiences_user_idx
  on public.experiences (user_id, start_date desc);

alter table public.portfolio_items enable row level security;
alter table public.experiences enable row level security;

-- Leitura pública (logados); escrita só do dono.
drop policy if exists "portfolio_items_select" on public.portfolio_items;
create policy "portfolio_items_select" on public.portfolio_items
  for select to authenticated using (true);

drop policy if exists "portfolio_items_own" on public.portfolio_items;
create policy "portfolio_items_own" on public.portfolio_items
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "experiences_select" on public.experiences;
create policy "experiences_select" on public.experiences
  for select to authenticated using (true);

drop policy if exists "experiences_own" on public.experiences;
create policy "experiences_own" on public.experiences
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- LIMITE de itens por usuário (evita abuso do armazenamento):
-- 30 itens no portfólio e 30 experiências.
create or replace function public.limit_profile_items()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_total integer;
begin
  execute format('select count(*) from public.%I where user_id = $1', tg_table_name)
    into v_total using new.user_id;
  if v_total >= 30 then
    raise exception 'Limite de 30 itens atingido. Apague algum para adicionar outro.'
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists portfolio_items_limit on public.portfolio_items;
create trigger portfolio_items_limit
  before insert on public.portfolio_items
  for each row execute function public.limit_profile_items();

drop trigger if exists experiences_limit on public.experiences;
create trigger experiences_limit
  before insert on public.experiences
  for each row execute function public.limit_profile_items();


-- -----------------------------------------------------------------------------
-- 17. ACEITE DO USO DA LOCALIZAÇÃO (LGPD) e POSIÇÃO APROXIMADA
-- -----------------------------------------------------------------------------
-- Documentação visual CineCrew: TEL07 (finalidade e aceite), TEL08
-- (localização), RF28/RF29/RF30 e RN33 a RN36.
--
--   * O profissional só aparece nas buscas depois de ACEITAR o uso da sua
--     localização para esta finalidade. O aceite fica registrado com data,
--     hora e versão do texto, e pode ser revogado (TEL22).
--   * A coordenada EXATA nunca sai do servidor para outras pessoas:
--       - a busca usa a coordenada exata para decidir "está dentro do raio?"
--         (d <= R) e para ordenar por distância;
--       - quem busca recebe só a POSIÇÃO APROXIMADA (grade de 0,01 grau,
--         cerca de 1,1 km) e a distância ARREDONDADA em km inteiros.
--   * O próprio usuário lê a sua coordenada exata pela função
--     get_my_location() (para editar o ponto no mapa).
-- -----------------------------------------------------------------------------

-- Registro dos aceites (um por vez; revogar fecha o registro atual).
create table if not exists public.location_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  terms_version text not null,                -- versão do texto aceito
  accepted_at timestamptz not null default now(),
  revoked_at timestamptz                      -- nulo = aceite em vigor
);

-- No máximo UM aceite em vigor por pessoa.
create unique index if not exists location_consents_active_unique
  on public.location_consents (user_id) where revoked_at is null;

alter table public.location_consents enable row level security;

drop policy if exists "location_consents_select_own" on public.location_consents;
create policy "location_consents_select_own" on public.location_consents
  for select to authenticated using (user_id = auth.uid());

-- Aceitar e revogar só pelas funções abaixo (que guardam data e versão).
revoke insert, update, delete on public.location_consents from authenticated, anon;

-- Registra o aceite. Se já houver um em vigor, só devolve a data dele.
create or replace function public.accept_location_terms(p_version text)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_accepted timestamptz;
begin
  if v_uid is null then
    raise exception 'Faça login novamente.' using errcode = 'P0001';
  end if;
  if coalesce(btrim(p_version), '') = '' then
    raise exception 'Versão do termo não informada.' using errcode = 'P0001';
  end if;

  select accepted_at into v_accepted
    from public.location_consents
   where user_id = v_uid and revoked_at is null;
  if found then
    return v_accepted;
  end if;

  insert into public.location_consents (user_id, terms_version)
  values (v_uid, btrim(p_version))
  returning accepted_at into v_accepted;
  return v_accepted;
end;
$$;

-- Revoga o aceite em vigor: o perfil deixa de aparecer nas buscas (TEL22-E2).
create or replace function public.revoke_location_consent()
returns void
language sql
security definer
set search_path = public
as $$
  update public.location_consents
     set revoked_at = now()
   where user_id = auth.uid() and revoked_at is null;
$$;

-- POSIÇÃO APROXIMADA: arredonda para 2 casas decimais (grade de ~1,1 km).
-- Colunas GERADAS: o banco recalcula sozinho quando o ponto muda.
alter table public.profiles add column if not exists approx_latitude double precision
  generated always as (round(latitude::numeric, 2)::double precision) stored;
alter table public.profiles add column if not exists approx_longitude double precision
  generated always as (round(longitude::numeric, 2)::double precision) stored;

-- COLUNAS VISÍVEIS: outros usuários NÃO leem latitude, longitude nem
-- location (a coordenada exata). Tudo o mais do perfil continua público
-- para quem está logado (é um banco de talentos).
revoke select on public.profiles from authenticated, anon;
grant select (
  id, email, full_name, phone, is_professional, is_recruiter,
  primary_role, secondary_skills, bio, avatar_url, resume_path, company_name,
  city, state, rating, reviews_count, is_available, headline, cover_url,
  approx_latitude, approx_longitude, created_at, updated_at
) on public.profiles to authenticated;

-- A coordenada EXATA do próprio usuário (só dele).
create or replace function public.get_my_location()
returns table (latitude double precision, longitude double precision)
language sql
stable
security definer
set search_path = public
as $$
  select p.latitude, p.longitude from public.profiles p where p.id = auth.uid();
$$;

-- Data do aceite em vigor do próprio usuário (nulo = não aceitou).
create or replace function public.get_my_location_consent()
returns timestamptz
language sql
stable
security definer
set search_path = public
as $$
  select accepted_at from public.location_consents
   where user_id = auth.uid() and revoked_at is null;
$$;

-- BUSCA DE PROFISSIONAIS (nova versão, com as regras de privacidade):
--   * só perfis profissionais com aceite em vigor e localização definida;
--   * o próprio usuário não aparece (RN44);
--   * devolve a POSIÇÃO APROXIMADA e a distância arredondada (mínimo 1 km).
-- "security definer": precisa ler a coordenada exata (protegida acima),
-- mas só devolve dados aproximados.
create or replace function public.search_professionals(
  p_lat double precision,
  p_lng double precision,
  p_radius_km double precision,
  p_skill text default null
)
returns table (
  id uuid,
  name text,
  email text,
  phone text,
  primary_role text,
  secondary_skills text[],
  bio text,
  avatar_url text,
  address text,
  city text,
  state text,
  latitude double precision,
  longitude double precision,
  rating numeric,
  is_available boolean,
  distance_in_km double precision
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  with found as (
    select
      p.*,
      st_distance(p.location, st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography) / 1000.0
        as exact_km
    from public.profiles p
    where p.is_professional
      and p.id is distinct from auth.uid()
      and p.deactivated_at is null                -- conta desativada some
      and p.location is not null
      and exists (
        select 1 from public.location_consents c
        where c.user_id = p.id and c.revoked_at is null
      )
      and st_dwithin(
        p.location,
        st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
        p_radius_km * 1000
      )
      and (
        p_skill is null
        or p.primary_role ilike '%' || p_skill || '%'
        or exists (
          select 1 from unnest(p.secondary_skills) as s(skill)
          where s.skill ilike '%' || p_skill || '%'
        )
      )
  )
  select
    f.id, f.full_name, f.email, f.phone, f.primary_role, f.secondary_skills,
    f.bio, f.avatar_url, null::text, f.city, f.state,
    f.approx_latitude, f.approx_longitude,          -- posição APROXIMADA
    f.rating, f.is_available,
    greatest(1, round(f.exact_km))::double precision -- "≈ N km", mínimo 1
  from found f
  order by f.exact_km;                               -- ordem pela distância real
$$;

revoke execute on function public.accept_location_terms(text) from public, anon;
revoke execute on function public.revoke_location_consent() from public, anon;
revoke execute on function public.get_my_location() from public, anon;
revoke execute on function public.get_my_location_consent() from public, anon;
grant execute on function public.accept_location_terms(text) to authenticated;
grant execute on function public.revoke_location_consent() to authenticated;
grant execute on function public.get_my_location() to authenticated;
grant execute on function public.get_my_location_consent() to authenticated;


-- -----------------------------------------------------------------------------
-- 18. MODO CONTRATAR: PROJETOS e BUSCA POR VÁRIAS ESPECIALIDADES
-- -----------------------------------------------------------------------------
-- Documentação visual: TEL10 (Explorar), TEL11 (Definir busca e projeto),
-- TEL12/TEL13 (Resultados em lista e mapa), TEL15 (Meus projetos).
--
-- Decisões tomadas para as pendências:
--   * P05 (faixa do raio): mínimo 1 km, máximo 200 km, padrão 50 km;
--   * P06 (várias especialidades): mostra quem tem QUALQUER UMA delas;
--   * P13 (projeto persistido): sim — o projeto guarda o local do set, o raio
--     e as especialidades, para repetir a busca depois;
--   * P11 (paginação): até 100 resultados, ordenados pela distância.
-- -----------------------------------------------------------------------------

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),

  -- Local do set (o contratante escolhe; não é dado pessoal de terceiros).
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  location_label text not null default '',
  city text,
  state text,

  radius_km integer not null default 50 check (radius_km between 1 and 200),
  specialties text[] not null check (cardinality(specialties) >= 1),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- (0, 0) nunca é aceito "por omissão" (regra da TEL08).
  constraint projects_not_null_island check (not (latitude = 0 and longitude = 0))
);

create index if not exists projects_owner_idx on public.projects (owner_id, updated_at desc);

drop trigger if exists projects_set_updated_at on public.projects;
create trigger projects_set_updated_at
  before update on public.projects
  for each row execute function public.set_updated_at();

alter table public.projects enable row level security;

-- Projetos são PRIVADOS: só o dono vê e altera.
drop policy if exists "projects_own" on public.projects;
create policy "projects_own" on public.projects
  for all to authenticated
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- BUSCA DE TALENTOS do modo Contratar (TEL12/TEL13).
-- Mesmas regras de privacidade da seção 17 (só posição aproximada e
-- distância arredondada; aceite obrigatório; o próprio usuário fica fora),
-- agora com VÁRIAS especialidades e o filtro "somente disponíveis".
create or replace function public.search_talents(
  p_lat double precision,
  p_lng double precision,
  p_radius_km double precision,
  p_specialties text[] default null,
  p_only_available boolean default false
)
returns table (
  id uuid,
  name text,
  headline text,
  primary_role text,
  secondary_skills text[],
  avatar_url text,
  cover_url text,
  city text,
  state text,
  rating numeric,
  reviews_count integer,
  is_available boolean,
  latitude double precision,
  longitude double precision,
  distance_in_km double precision
)
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
begin
  if p_lat is null or p_lng is null or p_lat not between -90 and 90
     or p_lng not between -180 and 180 or (p_lat = 0 and p_lng = 0) then
    raise exception 'Defina o local do set.' using errcode = 'P0001';
  end if;
  if p_radius_km is null or p_radius_km < 1 or p_radius_km > 200 then
    raise exception 'O raio deve ficar entre 1 e 200 km.' using errcode = 'P0001';
  end if;

  return query
  with found as (
    select
      p.*,
      st_distance(p.location, st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography) / 1000.0
        as exact_km
    from public.profiles p
    where p.is_professional
      and p.id is distinct from auth.uid()                       -- RN44
      and p.deactivated_at is null                               -- desativada
      and p.location is not null
      and exists (                                               -- aceite em vigor
        select 1 from public.location_consents c
        where c.user_id = p.id and c.revoked_at is null
      )
      and st_dwithin(                                            -- d <= R (exato)
        p.location,
        st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
        p_radius_km * 1000
      )
      and (                                                      -- QUALQUER UMA (P06)
        p_specialties is null
        or cardinality(p_specialties) = 0
        or p.primary_role = any (p_specialties)
        or p.secondary_skills && p_specialties
      )
      and (not p_only_available or p.is_available)
  )
  select
    f.id, f.full_name, f.headline, f.primary_role, f.secondary_skills,
    f.avatar_url, f.cover_url, f.city, f.state, f.rating, f.reviews_count,
    f.is_available,
    f.approx_latitude, f.approx_longitude,                       -- APROXIMADA
    greatest(1, round(f.exact_km))::double precision             -- "≈ N km"
  from found f
  order by f.exact_km
  limit 100;
end;
$$;

revoke execute on function public.search_talents(double precision, double precision, double precision, text[], boolean) from public, anon;
grant execute on function public.search_talents(double precision, double precision, double precision, text[], boolean) to authenticated;



-- -----------------------------------------------------------------------------
-- 19. CONTA E PRIVACIDADE (TEL20 a TEL22)
-- -----------------------------------------------------------------------------
--   * last_mode: o app abre no último modo usado (P20);
--   * desativar: a conta some das buscas e não entra no app; no login, a
--     pessoa vê o aviso e pode REATIVAR (decisão para a pendência P01,
--     opção "a": o login de conta desativada serve só para reativar);
--   * excluir: apaga a conta de login e, em cascata, o perfil e tudo que
--     depende dele (candidaturas, mensagens, aceites, projetos...). Os
--     arquivos (foto, capa, currículo, portfólio) são apagados pelo app,
--     pela API do Storage, antes de chamar a exclusão.
--   * Desativação e exclusão valem para a conta INTEIRA (pendência P18).
-- -----------------------------------------------------------------------------

-- Pagamentos SEGUEM a conta na exclusão (como a candidatura, de que dependem).
-- Antes, as chaves de pagador/recebedor impediam excluir a conta.
alter table public.payments drop constraint if exists payments_payer_id_fkey;
alter table public.payments add constraint payments_payer_id_fkey
  foreign key (payer_id) references public.profiles (id) on delete cascade;
alter table public.payments drop constraint if exists payments_payee_id_fkey;
alter table public.payments add constraint payments_payee_id_fkey
  foreign key (payee_id) references public.profiles (id) on delete cascade;
alter table public.payments drop constraint if exists payments_disputed_by_fkey;
alter table public.payments add constraint payments_disputed_by_fkey
  foreign key (disputed_by) references public.profiles (id) on delete set null;

-- Leitura das colunas novas (a lista completa está na seção 17).
grant select (deactivated_at, last_mode) on public.profiles to authenticated;
-- O próprio usuário pode trocar o último modo (a desativação é por função).
grant update (last_mode) on public.profiles to authenticated;

create or replace function public.deactivate_my_account()
returns void
language sql
security definer
set search_path = public
as $$
  update public.profiles set deactivated_at = now()
   where id = auth.uid() and deactivated_at is null;
$$;

create or replace function public.reactivate_my_account()
returns void
language sql
security definer
set search_path = public
as $$
  update public.profiles set deactivated_at = null where id = auth.uid();
$$;

-- Exclusão DEFINITIVA da conta (TEL22-E1). Apagar em auth.users dispara o
-- "on delete cascade" de profiles, que apaga o resto em cascata.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Faça login novamente.' using errcode = 'P0001';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

-- Quando o e-mail de login muda (TEL21, após a confirmação), o perfil acompanha.
create or replace function public.sync_profile_email()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles set email = new.email where id = new.id;
  return new;
end;
$$;

drop trigger if exists on_auth_user_email_changed on auth.users;
create trigger on_auth_user_email_changed
  after update of email on auth.users
  for each row
  when (old.email is distinct from new.email)
  execute function public.sync_profile_email();

revoke execute on function public.deactivate_my_account() from public, anon;
revoke execute on function public.reactivate_my_account() from public, anon;
revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.deactivate_my_account() to authenticated;
grant execute on function public.reactivate_my_account() to authenticated;
grant execute on function public.delete_my_account() to authenticated;

-- Para "Excluir conta e dados": cada um pode APAGAR os próprios arquivos
-- (foto e currículo). A pasta "portfolio" já tinha essa regra (seção 16).
drop policy if exists "avatars_delete_own" on storage.objects;
create policy "avatars_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "resumes_delete_own" on storage.objects;
create policy "resumes_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'resumes' and (storage.foldername(name))[1] = auth.uid()::text);



-- -----------------------------------------------------------------------------
-- 20. CORREÇÃO DO LOGIN: GARANTIR QUE TODA CONTA TENHA PERFIL
-- -----------------------------------------------------------------------------
--   * Contas criadas ANTES do gatilho handle_new_user (ou quando ele falhou)
--     ficam sem linha em `profiles`, e o app não consegue abrir a sessão.
--   * ensure_my_profile(): o próprio usuário logado cria a linha que falta
--     (o app chama sozinho quando não encontra o perfil).
--   * O INSERT abaixo corrige de uma vez as contas que já existem sem perfil.
--     Não altera nem apaga nenhum perfil existente (on conflict do nothing).
-- -----------------------------------------------------------------------------

create or replace function public.ensure_my_profile()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Faça login para continuar.';
  end if;

  insert into public.profiles (id, email, full_name, is_professional, is_recruiter)
  select u.id,
         u.email,
         coalesce(u.raw_user_meta_data ->> 'full_name', ''),
         false,
         false
    from auth.users u
   where u.id = auth.uid()
  on conflict (id) do nothing;
end;
$$;

revoke execute on function public.ensure_my_profile() from public, anon;
grant execute on function public.ensure_my_profile() to authenticated;

-- Contas antigas sem perfil: cria a linha (a pessoa escolhe o modo no app).
insert into public.profiles (id, email, full_name, is_professional, is_recruiter)
select u.id, u.email, coalesce(u.raw_user_meta_data ->> 'full_name', ''), false, false
  from auth.users u
 where not exists (select 1 from public.profiles p where p.id = u.id)
on conflict (id) do nothing;
