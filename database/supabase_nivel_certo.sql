-- =====================================================================
-- NÍVEL CERTO - banco de dados (Supabase / PostgreSQL)
--
-- Como usar: no Supabase, abra "SQL Editor", clique em "New query",
-- cole este arquivo inteiro e clique em "Run".
-- Pode ser executado mais de uma vez sem duplicar dados.
-- =====================================================================

create extension if not exists pgcrypto with schema extensions;


-- ---------------------------------------------------------------------
-- 1. TABELAS
-- ---------------------------------------------------------------------

-- Perfil do usuário. E-mail e senha ficam no Supabase Auth (auth.users),
-- que guarda a senha com hash e cuida do login e da recuperação de senha.
create table if not exists public.perfil (
  id               uuid primary key references auth.users(id) on delete cascade,
  nome             text not null,
  data_nascimento  date,
  genero           text,
  telefone         text unique,
  fuso_horario     text not null default 'America/Sao_Paulo',
  status           boolean not null default true,
  criado_em        timestamptz not null default now()
);

-- Catálogo de modelos dos fabricantes (somente leitura para o app).
-- Medidas em centímetros. A caixa é tratada como um tronco de cone:
--   altura_cm            = h  (altura do corpo, sem a tampa)
--   altura_com_tampa_cm  = H  (altura da base até o topo da tampa, onde fica o sensor)
--   diametro_topo_cm     = D  (diâmetro maior, no topo do corpo, sem a tampa)
--   diametro_base_cm     = d  (diâmetro menor, na base)
create table if not exists public.modelo_caixa (
  id                 bigint generated always as identity primary key,
  fabricante         text not null,
  formato            text not null default 'redonda',
  capacidade_litros  integer not null check (capacidade_litros > 0),
  altura_cm            numeric(7,1) not null check (altura_cm > 0),
  altura_com_tampa_cm  numeric(7,1) check (altura_com_tampa_cm > 0),
  diametro_topo_cm     numeric(7,1) not null check (diametro_topo_cm > 0),
  diametro_base_cm     numeric(7,1) not null check (diametro_base_cm > 0),
  observacao           text,
  unique (fabricante, formato, capacidade_litros)
);

-- Para quem já executou uma versão anterior deste script (coluna nova):
alter table public.modelo_caixa
  add column if not exists altura_com_tampa_cm numeric(7,1) check (altura_com_tampa_cm > 0);

-- Caixas d'água do usuário. As medidas são copiadas do catálogo (ou
-- digitadas, no caso de marca "Genérica"), assim o cálculo do volume não
-- muda se o catálogo for alterado depois.
-- altura_cm        = h (altura do corpo, sem a tampa)
-- altura_sensor_cm = H (altura da base até o sensor, no topo da tampa).
--   Copie a altura com tampa do catálogo; para ajustar com precisão, meça a
--   distância lida pelo sensor com a caixa vazia e use esse valor.
create table if not exists public.caixa_dagua (
  id                 bigint generated always as identity primary key,
  id_usu             uuid not null default auth.uid()
                       references public.perfil(id) on delete cascade,
  id_mod             bigint references public.modelo_caixa(id),
  nome               text not null,
  marca              text not null,
  formato            text not null default 'redonda',
  capacidade_litros  numeric(9,1) not null check (capacidade_litros > 0),
  altura_cm          numeric(7,1) not null check (altura_cm > 0),
  diametro_topo_cm   numeric(7,1) not null check (diametro_topo_cm > 0),
  diametro_base_cm   numeric(7,1) not null check (diametro_base_cm > 0),
  altura_sensor_cm   numeric(7,1) not null check (altura_sensor_cm > 0),
  excluida_em        timestamptz,
  criado_em          timestamptz not null default now(),
  atualizado_em      timestamptz not null default now()
);

-- Dispositivo de medição (ESP32). Pode existir antes de ter caixa.
create table if not exists public.dispositivo_medicao (
  id                  bigint generated always as identity primary key,
  identificador       text not null unique,
  modelo              text not null default 'ESP32',
  id_cai              bigint unique references public.caixa_dagua(id) on delete set null,
  data_instalacao     date,
  ultima_comunicacao  timestamptz
);

-- Chave secreta de cada dispositivo (guardada só como hash).
-- Fica separada para nunca ser exposta ao app.
create table if not exists public.dispositivo_chave (
  id_dis      bigint primary key references public.dispositivo_medicao(id) on delete cascade,
  chave_hash  text not null
);

-- Leituras enviadas pela ESP32 (uma linha por ciclo de medição).
create table if not exists public.leitura (
  id                bigint generated always as identity primary key,
  id_dis            bigint references public.dispositivo_medicao(id) on delete set null,
  id_cai            bigint not null references public.caixa_dagua(id) on delete cascade,
  data_hora         timestamptz not null default now(),
  distancia_cm      numeric(7,1),      -- valor bruto do ultrassônico
  volume_litros     numeric(9,1),      -- volume calculado a partir da distância
  vazao_lpm         numeric(7,2),      -- vazão instantânea (L/min)
  volume_periodo_l  numeric(9,3)       -- litros que ENTRARAM (sensor de vazão na entrada) desde a leitura anterior
);

-- Litros consumidos no período = entrada - variação do volume da caixa.
-- (adicionada à parte para funcionar também em bancos já criados)
alter table public.leitura add column if not exists consumo_periodo_l numeric(9,3);

-- Distância "estável": só muda quando a medição se afasta do último valor aceito
-- por mais que a faixa de tolerância. O volume é calculado a partir dela, então
-- pequenas oscilações do sensor não alteram os litros.
alter table public.leitura add column if not exists distancia_estavel_cm numeric(7,1);

create index if not exists leitura_caixa_data_idx on public.leitura (id_cai, data_hora desc);
create index if not exists caixa_usuario_idx on public.caixa_dagua (id_usu) where excluida_em is null;


-- ---------------------------------------------------------------------
-- 2. CATÁLOGO DE MODELOS (Fortlev, Infibra e MaisPVC)
-- Ordem das medidas: h (corpo), H (com tampa), D (topo), d (base), em centímetros.
-- ---------------------------------------------------------------------
insert into public.modelo_caixa
  (fabricante, formato, capacidade_litros, altura_cm, altura_com_tampa_cm, diametro_topo_cm, diametro_base_cm, observacao)
values
  ('Fortlev', 'redonda', 100, 41.0, 51.0, 73.0, 54.0, null),
  ('Fortlev', 'redonda', 150, 43.0, 55.0, 87.0, 61.0, null),
  ('Fortlev', 'redonda', 250, 50.0, 66.0, 103.0, 75.0, null),
  ('Fortlev', 'redonda', 310, 54.0, 69.0, 103.0, 75.0, null),
  ('Fortlev', 'redonda', 500, 58.0, 72.0, 122.0, 95.0, null),
  ('Fortlev', 'redonda', 750, 58.0, 77.0, 151.0, 116.0, null),
  ('Fortlev', 'redonda', 1000, 76.0, 97.0, 151.0, 116.0, null),
  ('Fortlev', 'redonda', 1500, 83.0, 105.0, 175.0, 143.0, null),
  ('Fortlev', 'redonda', 2000, 90.0, 112.0, 199.0, 166.0, null),
  ('Fortlev', 'redonda', 3000, 121.0, 149.0, 222.0, 172.0, null),
  ('Fortlev', 'redonda', 5000, 163.0, 200.0, 237.0, 185.0, 'Modelo marcado com * na tabela do fabricante.'),
  ('Fortlev', 'redonda', 7500, 189.0, 237.0, 278.0, 226.0, 'Modelo marcado com * na tabela do fabricante.'),
  ('Fortlev', 'redonda', 10000, 203.0, 257.0, 292.0, 241.0, 'Modelo marcado com * na tabela do fabricante.'),
  ('Fortlev', 'redonda', 15000, 262.0, 313.0, 315.0, 267.0, 'Modelo marcado com * na tabela do fabricante.'),
  ('Infibra', 'redonda', 100, 45.5, 54.0, 73.0, 50.5, null),
  ('Infibra', 'redonda', 310, 58.0, 67.0, 106.0, 76.0, null),
  ('Infibra', 'redonda', 500, 59.5, 73.0, 120.0, 90.0, null),
  ('Infibra', 'redonda', 1000, 70.5, 87.5, 152.0, 119.0, null),
  ('Infibra', 'redonda', 2500, 113.0, 130.0, 196.0, 141.0, null),
  ('MaisPVC', 'redonda', 310, 54.9, 68.6, 96.4, 74.2, 'Topo = coluna C e base = coluna D da tabela (a coluna E da tabela do fabricante parece inconsistente).'),
  ('MaisPVC', 'redonda', 500, 59.1, 74.0, 118.1, 91.4, 'Topo = coluna C e base = coluna D da tabela (a coluna E da tabela do fabricante parece inconsistente).'),
  ('MaisPVC', 'redonda', 1000, 76.5, 94.0, 145.8, 112.1, 'Topo = coluna C e base = coluna D da tabela (a coluna E da tabela do fabricante parece inconsistente).'),
  ('MaisPVC', 'redonda', 2000, 96.4, 121.9, 187.6, 141.0, 'Topo = coluna C e base = coluna D da tabela (a coluna E da tabela do fabricante parece inconsistente).')
on conflict (fabricante, formato, capacidade_litros) do update set
  altura_cm           = excluded.altura_cm,
  altura_com_tampa_cm = excluded.altura_com_tampa_cm,
  diametro_topo_cm    = excluded.diametro_topo_cm,
  diametro_base_cm    = excluded.diametro_base_cm,
  observacao          = excluded.observacao;

alter table public.modelo_caixa alter column altura_com_tampa_cm set not null;


-- ---------------------------------------------------------------------
-- 3. FUNÇÕES
-- ---------------------------------------------------------------------

-- Atualiza a data de alteração da caixa.
create or replace function public.set_atualizado_em()
returns trigger
language plpgsql
as $$
begin
  new.atualizado_em := now();
  return new;
end;
$$;

drop trigger if exists caixa_atualizado_em on public.caixa_dagua;
create trigger caixa_atualizado_em
  before update on public.caixa_dagua
  for each row execute function public.set_atualizado_em();

-- Cria o perfil automaticamente quando alguém se cadastra pelo app.
-- O app deve enviar nome, data_nascimento (formato AAAA-MM-DD), genero e
-- telefone nos dados extras do cadastro.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.perfil (id, nome, data_nascimento, genero, telefone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nome', ''),
    nullif(new.raw_user_meta_data->>'data_nascimento', '')::date,
    nullif(new.raw_user_meta_data->>'genero', ''),
    nullif(new.raw_user_meta_data->>'telefone', '')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Volume em litros a partir da distância medida pelo sensor.
-- Notação: A = p_distancia_cm (do sensor até a água), H = p_altura_sensor_cm
-- (altura com tampa), h = p_altura_cm (altura sem tampa), D = diâmetro do topo,
-- d = diâmetro da base.
-- 1) y = H - A, limitado entre 0 e h (acima de h a água já está na tampa);
-- 2) diâmetro no nível da água: Dy = d + (D - d) * y / h;
-- 3) volume do tronco de cone até y: (1/3) * pi * y * (r^2 + r*ry + ry^2);
-- 4) o resultado é limitado à capacidade nominal: 100% = capacidade_litros.
--    As medidas dos fabricantes são externas e a caixa tem volume sobrando acima
--    do nível de uso (ex.: 539 L geométricos no topo de uma caixa de 500 L), então
--    esse excedente não é atingido na prática.
-- Faixa de tolerância (cm) da regra de estabilidade. Para mudar, edite o valor
-- e rode este arquivo de novo.
create or replace function public.faixa_estabilidade_cm()
returns numeric language sql immutable as $$ select 1.5::numeric $$;

create or replace function public.calcular_volume_litros(
  p_distancia_cm       numeric,
  p_altura_sensor_cm   numeric,
  p_altura_cm          numeric,
  p_diametro_topo_cm   numeric,
  p_diametro_base_cm   numeric,
  p_capacidade_litros  numeric
) returns numeric
language sql
immutable
as $$
  select round(
    least(
      p_capacidade_litros,
      pi()::numeric * g.h / 3 * (g.rb * g.rb + g.rb * g.ry + g.ry * g.ry) / 1000
    ),
    1)
  from (
    select y.h,
           p_diametro_base_cm / 2 as rb,
           p_diametro_base_cm / 2
             + (p_diametro_topo_cm - p_diametro_base_cm) / 2 * y.h / p_altura_cm as ry
    from (
      select greatest(0, least(p_altura_cm, p_altura_sensor_cm - p_distancia_cm)) as h
    ) y
  ) g
$$;

-- Usada pela ESP32 para enviar uma leitura.
-- Confere o identificador e a chave do dispositivo; sem isso, nada é gravado.
-- Se o dispositivo ainda não estiver vinculado a uma caixa, só registra
-- que ele está online.
create or replace function public.registrar_leitura(
  p_identificador     text,
  p_chave             text,
  p_distancia_cm      numeric default null,
  p_vazao_lpm         numeric default null,
  p_volume_periodo_l  numeric default null,
  p_data_hora         timestamptz default null
) returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_dis     public.dispositivo_medicao%rowtype;
  v_cai     public.caixa_dagua%rowtype;
  v_volume  numeric;
  v_ant     numeric;
  v_consumo numeric;
  v_est     numeric;
  v_est_ant numeric;
  v_hora    timestamptz := coalesce(p_data_hora, now());
begin
  select d.* into v_dis
    from public.dispositivo_medicao d
    join public.dispositivo_chave c on c.id_dis = d.id
   where d.identificador = p_identificador
     and c.chave_hash = encode(extensions.digest(p_chave, 'sha256'), 'hex');

  if not found then
    raise exception 'dispositivo ou chave invalidos' using errcode = '28000';
  end if;

  update public.dispositivo_medicao
     set ultima_comunicacao = now()
   where id = v_dis.id;

  if v_dis.id_cai is null then
    return;
  end if;

  select * into v_cai
    from public.caixa_dagua
   where id = v_dis.id_cai and excluida_em is null;

  if not found then
    return;
  end if;

  if v_hora > now() + interval '5 minutes' then
    v_hora := now();
  end if;

  -- leitura impossível do sensor é descartada
  if p_distancia_cm is not null and (p_distancia_cm < 0 or p_distancia_cm > 1000) then
    p_distancia_cm := null;
  end if;

  if p_distancia_cm is not null then
    -- último valor aceito (estável) desta caixa
    select coalesce(l.distancia_estavel_cm, l.distancia_cm) into v_est_ant
      from public.leitura l
     where l.id_cai = v_cai.id and l.data_hora < v_hora
       and coalesce(l.distancia_estavel_cm, l.distancia_cm) is not null
     order by l.data_hora desc
     limit 1;

    if v_est_ant is not null
       and abs(p_distancia_cm - v_est_ant) < public.faixa_estabilidade_cm() then
      v_est := v_est_ant;        -- oscilação pequena: mantém o valor anterior
    else
      v_est := p_distancia_cm;   -- mudança real (ou primeira leitura)
    end if;

    v_volume := public.calcular_volume_litros(
      v_est, v_cai.altura_sensor_cm, v_cai.altura_cm,
      v_cai.diametro_topo_cm, v_cai.diametro_base_cm, v_cai.capacidade_litros);
  end if;

  -- consumo = o que entrou - quanto o volume da caixa aumentou
  if v_volume is not null and p_volume_periodo_l is not null then
    select l.volume_litros into v_ant
      from public.leitura l
     where l.id_cai = v_cai.id and l.data_hora < v_hora
     order by l.data_hora desc
     limit 1;
    if v_ant is not null then
      v_consumo := p_volume_periodo_l - (v_volume - v_ant);
    end if;
  end if;

  insert into public.leitura
    (id_dis, id_cai, data_hora, distancia_cm, distancia_estavel_cm, volume_litros, vazao_lpm, volume_periodo_l, consumo_periodo_l)
  values
    (v_dis.id, v_cai.id, v_hora, p_distancia_cm, v_est, v_volume, p_vazao_lpm, p_volume_periodo_l, v_consumo);
end;
$$;

-- Cadastra (ou troca a chave de) um dispositivo. Uso apenas pelo administrador,
-- no SQL Editor. Veja o exemplo no final do arquivo.
create or replace function public.criar_dispositivo(
  p_identificador  text,
  p_chave          text,
  p_modelo         text default 'ESP32'
) returns bigint
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_id bigint;
begin
  if length(p_chave) < 20 then
    raise exception 'use uma chave com pelo menos 20 caracteres';
  end if;

  insert into public.dispositivo_medicao (identificador, modelo)
  values (p_identificador, p_modelo)
  on conflict (identificador) do update set modelo = excluded.modelo
  returning id into v_id;

  insert into public.dispositivo_chave (id_dis, chave_hash)
  values (v_id, encode(extensions.digest(p_chave, 'sha256'), 'hex'))
  on conflict (id_dis) do update set chave_hash = excluded.chave_hash;

  return v_id;
end;
$$;

-- Usada pelo app para vincular um dispositivo a uma caixa do próprio usuário.
-- A chave do dispositivo serve de prova de que a pessoa tem o aparelho.
create or replace function public.vincular_dispositivo(
  p_identificador  text,
  p_chave          text,
  p_id_cai         bigint
) returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_id_dis bigint;
begin
  if auth.uid() is null then
    raise exception 'login necessario' using errcode = '28000';
  end if;

  if not exists (
    select 1 from public.caixa_dagua
     where id = p_id_cai and id_usu = auth.uid() and excluida_em is null
  ) then
    raise exception 'caixa nao encontrada' using errcode = 'P0002';
  end if;

  select d.id into v_id_dis
    from public.dispositivo_medicao d
    join public.dispositivo_chave c on c.id_dis = d.id
   where d.identificador = p_identificador
     and c.chave_hash = encode(extensions.digest(p_chave, 'sha256'), 'hex');

  if v_id_dis is null then
    raise exception 'dispositivo ou chave invalidos' using errcode = '28000';
  end if;

  update public.dispositivo_medicao set id_cai = null
   where id_cai = p_id_cai and id <> v_id_dis;

  update public.dispositivo_medicao
     set id_cai = p_id_cai, data_instalacao = current_date
   where id = v_id_dis;
end;
$$;

-- Recalcula o volume de todas as leituras de uma caixa (use depois de
-- corrigir as medidas ou a altura do sensor).
create or replace function public.recalcular_volumes(p_id_cai bigint)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r      record;
  v_est  numeric;
  v_prev numeric;
begin
  if not exists (
    select 1 from public.caixa_dagua where id = p_id_cai and id_usu = auth.uid()
  ) then
    raise exception 'caixa nao encontrada' using errcode = 'P0002';
  end if;

  -- refaz a distância estável e o volume, leitura por leitura, em ordem de data
  for r in
    select l.id, l.distancia_cm, c.altura_sensor_cm, c.altura_cm,
           c.diametro_topo_cm, c.diametro_base_cm, c.capacidade_litros
      from public.leitura l
      join public.caixa_dagua c on c.id = l.id_cai
     where l.id_cai = p_id_cai and l.distancia_cm is not null
     order by l.data_hora
  loop
    if v_prev is not null
       and abs(r.distancia_cm - v_prev) < public.faixa_estabilidade_cm() then
      v_est := v_prev;
    else
      v_est := r.distancia_cm;
    end if;
    v_prev := v_est;

    update public.leitura
       set distancia_estavel_cm = v_est,
           volume_litros = public.calcular_volume_litros(
             v_est, r.altura_sensor_cm, r.altura_cm,
             r.diametro_topo_cm, r.diametro_base_cm, r.capacidade_litros)
     where id = r.id;
  end loop;

  -- refaz o consumo de cada leitura com o volume da leitura anterior
  update public.leitura l
     set consumo_periodo_l = case
           when x.volume_litros is not null and x.ant is not null and x.volume_periodo_l is not null
           then x.volume_periodo_l - (x.volume_litros - x.ant) end
    from (select id, volume_litros, volume_periodo_l,
                 lag(volume_litros) over (order by data_hora) as ant
            from public.leitura
           where id_cai = p_id_cai) x
   where l.id = x.id;
end;
$$;

-- Consumo por dia (no fuso horário do usuário), para o gráfico do histórico.
-- qtd_leituras = 0 significa "sem dados naquele dia" (e não consumo zero).
-- Exemplo: select * from consumo_diario(1, '2026-11-15', '2026-11-21');
create or replace function public.consumo_diario(
  p_id_cai  bigint,
  p_inicio  date,
  p_fim     date
) returns table (data date, consumo_litros numeric, qtd_leituras bigint)
language sql
stable
set search_path = public
as $$
  with tz as (
    select coalesce(
      (select fuso_horario from public.perfil where id = auth.uid()),
      'America/Sao_Paulo') as z
  )
  select (p_inicio + g.i)                           as data,
         greatest(coalesce(sum(l.consumo_periodo_l), 0), 0) as consumo_litros,
         count(l.consumo_periodo_l)                 as qtd_leituras
    from tz
   cross join generate_series(0, least(p_fim - p_inicio, 92)) as g(i)
    left join public.leitura l
      on l.id_cai = p_id_cai
     and l.data_hora >= (p_inicio::timestamp at time zone tz.z)
     and l.data_hora <  ((p_fim + 1)::timestamp at time zone tz.z)
     and (l.data_hora at time zone tz.z)::date = p_inicio + g.i
   group by g.i
   order by g.i
$$;


-- Litros que ENTRARAM na caixa por dia (sensor de vazão da entrada), para o
-- Histórico de Abastecimento. qtd_leituras = 0 significa "sem dados naquele dia".
-- Exemplo: select * from abastecimento_diario(1, '2026-11-15', '2026-11-21');
create or replace function public.abastecimento_diario(
  p_id_cai  bigint,
  p_inicio  date,
  p_fim     date
) returns table (data date, litros_entrada numeric, qtd_leituras bigint)
language sql
stable
set search_path = public
as $$
  with tz as (
    select coalesce(
      (select fuso_horario from public.perfil where id = auth.uid()),
      'America/Sao_Paulo') as z
  )
  select (p_inicio + g.i)                           as data,
         coalesce(sum(l.volume_periodo_l), 0)       as litros_entrada,
         count(l.volume_periodo_l)                  as qtd_leituras
    from tz
   cross join generate_series(0, least(p_fim - p_inicio, 92)) as g(i)
    left join public.leitura l
      on l.id_cai = p_id_cai
     and l.data_hora >= (p_inicio::timestamp at time zone tz.z)
     and l.data_hora <  ((p_fim + 1)::timestamp at time zone tz.z)
     and (l.data_hora at time zone tz.z)::date = p_inicio + g.i
   group by g.i
   order by g.i
$$;


-- ---------------------------------------------------------------------
-- 4. SEGURANÇA (RLS): cada usuário só enxerga os próprios dados
-- ---------------------------------------------------------------------
alter table public.perfil              enable row level security;
alter table public.modelo_caixa        enable row level security;
alter table public.caixa_dagua         enable row level security;
alter table public.dispositivo_medicao enable row level security;
alter table public.dispositivo_chave   enable row level security;
alter table public.leitura             enable row level security;

drop policy if exists perfil_select on public.perfil;
create policy perfil_select on public.perfil
  for select to authenticated using (id = (select auth.uid()));

drop policy if exists perfil_update on public.perfil;
create policy perfil_update on public.perfil
  for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

drop policy if exists modelo_select on public.modelo_caixa;
create policy modelo_select on public.modelo_caixa
  for select to authenticated using (true);

drop policy if exists caixa_select on public.caixa_dagua;
create policy caixa_select on public.caixa_dagua
  for select to authenticated using (id_usu = (select auth.uid()));

drop policy if exists caixa_insert on public.caixa_dagua;
create policy caixa_insert on public.caixa_dagua
  for insert to authenticated with check (id_usu = (select auth.uid()));

drop policy if exists caixa_update on public.caixa_dagua;
create policy caixa_update on public.caixa_dagua
  for update to authenticated
  using (id_usu = (select auth.uid())) with check (id_usu = (select auth.uid()));

drop policy if exists dispositivo_select on public.dispositivo_medicao;
create policy dispositivo_select on public.dispositivo_medicao
  for select to authenticated
  using (id_cai in (select id from public.caixa_dagua where id_usu = (select auth.uid())));

drop policy if exists leitura_select on public.leitura;
create policy leitura_select on public.leitura
  for select to authenticated
  using (id_cai in (select id from public.caixa_dagua where id_usu = (select auth.uid())));

-- dispositivo_chave não tem política: ninguém acessa pelo app.


-- ---------------------------------------------------------------------
-- 5. PERMISSÕES
-- ---------------------------------------------------------------------
revoke all on public.perfil, public.modelo_caixa, public.caixa_dagua,
              public.dispositivo_medicao, public.dispositivo_chave, public.leitura
  from anon, authenticated;

grant select on public.modelo_caixa, public.dispositivo_medicao, public.leitura to authenticated;
grant select, insert, update on public.caixa_dagua to authenticated;
grant select on public.perfil to authenticated;
grant update (nome, data_nascimento, genero, telefone, fuso_horario) on public.perfil to authenticated;

revoke all on function public.set_atualizado_em() from public, anon, authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.criar_dispositivo(text, text, text) from public, anon, authenticated;
revoke all on function public.registrar_leitura(text, text, numeric, numeric, numeric, timestamptz) from public, anon, authenticated;
revoke all on function public.vincular_dispositivo(text, text, bigint) from public, anon, authenticated;
revoke all on function public.recalcular_volumes(bigint) from public, anon, authenticated;
revoke all on function public.consumo_diario(bigint, date, date) from public, anon, authenticated;
revoke all on function public.abastecimento_diario(bigint, date, date) from public, anon, authenticated;
revoke all on function public.calcular_volume_litros(numeric, numeric, numeric, numeric, numeric, numeric) from public, anon, authenticated;
revoke all on function public.faixa_estabilidade_cm() from public, anon, authenticated;

-- A ESP32 usa a chave pública (anon): só consegue chamar esta função.
grant execute on function public.registrar_leitura(text, text, numeric, numeric, numeric, timestamptz) to anon, authenticated;

grant execute on function public.vincular_dispositivo(text, text, bigint) to authenticated;
grant execute on function public.recalcular_volumes(bigint) to authenticated;
grant execute on function public.consumo_diario(bigint, date, date) to authenticated;
grant execute on function public.abastecimento_diario(bigint, date, date) to authenticated;
grant execute on function public.calcular_volume_litros(numeric, numeric, numeric, numeric, numeric, numeric) to authenticated;


-- ---------------------------------------------------------------------
-- 6. EXEMPLOS (não fazem parte da instalação: rode separadamente, se quiser)
-- ---------------------------------------------------------------------
-- a) Gerar uma chave aleatória para um dispositivo (copie o resultado):
--    select encode(extensions.gen_random_bytes(24), 'hex');
--
-- b) Cadastrar o dispositivo (use o MAC da ESP32 e a chave gerada acima):
--    select public.criar_dispositivo('AA:BB:CC:DD:EE:FF', 'COLE_A_CHAVE_AQUI');
--
-- c) Corpo (JSON) que a ESP32 envia para a função registrar_leitura:
--    {
--      "p_identificador": "AA:BB:CC:DD:EE:FF",
--      "p_chave": "COLE_A_CHAVE_AQUI",
--      "p_distancia_cm": 31.5,
--      "p_vazao_lpm": 4.2,
--      "p_volume_periodo_l": 4.2     (litros que ENTRARAM na caixa no período)
--    }
--
-- e) Vincular o dispositivo à sua caixa (troque o MAC e o id da caixa;
--    o id aparece na tabela caixa_dagua, em Table Editor):
--    update public.dispositivo_medicao set id_cai = 1
--     where identificador = 'AA:BB:CC:DD:EE:FF';
--
-- d) Testar o cálculo do volume com a Fortlev de 500 L
--    (ordem: A, H, h, D, d, capacidade):
--    select public.calcular_volume_litros(43, 72, 58, 122, 95, 500);  -- água em y = 29 cm  -> ~236 L
--    select public.calcular_volume_litros(18, 72, 58, 122, 95, 500);  -- água em y = 54 cm  -> ~497 L
--    select public.calcular_volume_litros(14, 72, 58, 122, 95, 500);  -- água no topo (539 L) -> 500 L (limite)
--    select public.calcular_volume_litros(72, 72, 58, 122, 95, 500);  -- vazia             -> 0 L
