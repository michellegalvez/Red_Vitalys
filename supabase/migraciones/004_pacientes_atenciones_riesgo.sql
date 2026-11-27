-- 004 · Pacientes, atenciones y riesgo de reingreso (Plan P-04, F-02, F-04, F-07).
-- Idempotente: se puede ejecutar repetidamente en Supabase SQL Editor sin errores.
-- No contiene credenciales ni secretos en texto plano.

create table if not exists public.paciente (
  id_paciente bigint generated always as identity primary key,
  primer_nombre text not null,
  segundo_nombre text,
  primer_apellido text not null,
  segundo_apellido text,
  fecha_nacimiento date not null,
  sexo char(1) not null check (sexo in ('M', 'F')),
  direccion text,
  telefono text
);

create table if not exists public.identificador_paciente (
  id_identificador bigint generated always as identity primary key,
  id_paciente bigint not null references public.paciente (id_paciente) on delete cascade,
  id_sistema bigint not null references public.sistema_origen (id_sistema),
  tipo_documento text not null check (tipo_documento in ('CC', 'TI', 'RC')),
  numero_identificacion text not null,
  es_principal boolean not null default false,
  unique (id_sistema, tipo_documento, numero_identificacion)
);

create unique index if not exists identificador_principal_idx
  on public.identificador_paciente (id_paciente) where es_principal;

create table if not exists public.atencion (
  id_atencion bigint generated always as identity primary key,
  id_paciente bigint not null references public.paciente (id_paciente) on delete cascade,
  id_sede bigint not null references public.sede (id_sede),
  id_usuario uuid not null references public.usuario (id_usuario),
  tipo_atencion text not null
    check (tipo_atencion in ('hospitalizacion', 'urgencias', 'consulta_externa')),
  fecha_inicio timestamptz not null,
  fecha_fin timestamptz,
  destino_alta text,
  proposito text not null check (proposito in (
    'seguimiento_reingreso', 'consulta_historia', 'atencion_paciente',
    'revision_calidad', 'urgencia'
  )),
  constraint atencion_fechas check (fecha_fin is null or fecha_fin >= fecha_inicio)
);

create index if not exists atencion_paciente_idx on public.atencion (id_paciente);
create index if not exists atencion_usuario_idx on public.atencion (id_usuario);
create index if not exists atencion_fecha_idx on public.atencion (fecha_inicio desc);

create table if not exists public.prediccion_reingreso (
  id_prediccion bigint generated always as identity primary key,
  id_atencion bigint not null references public.atencion (id_atencion) on delete cascade,
  score_riesgo numeric(5, 2) not null
    check (score_riesgo >= 0 and score_riesgo <= 100),
  fecha_prediccion date not null
);

create table if not exists public.factor_riesgo (
  id_factor bigint generated always as identity primary key,
  id_prediccion bigint not null
    references public.prediccion_reingreso (id_prediccion) on delete cascade,
  variable text not null,
  contribucion numeric(8, 4) not null
);

-- Llave foránea diferida en evento_auditoria (AD-08)
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'evento_auditoria_paciente_fk'
  ) then
    alter table public.evento_auditoria
      add constraint evento_auditoria_paciente_fk
      foreign key (id_paciente) references public.paciente (id_paciente);
  end if;
end $$;

-- Permisos y RLS
alter table public.paciente enable row level security;
alter table public.identificador_paciente enable row level security;
alter table public.atencion enable row level security;
alter table public.prediccion_reingreso enable row level security;
alter table public.factor_riesgo enable row level security;

-- Lectura para usuarios autenticados
drop policy if exists paciente_leer on public.paciente;
create policy paciente_leer on public.paciente
  for select to authenticated using (true);

drop policy if exists identificador_leer on public.identificador_paciente;
create policy identificador_leer on public.identificador_paciente
  for select to authenticated using (true);

drop policy if exists atencion_leer on public.atencion;
create policy atencion_leer on public.atencion
  for select to authenticated using (true);

drop policy if exists prediccion_leer on public.prediccion_reingreso;
create policy prediccion_leer on public.prediccion_reingreso
  for select to authenticated using (true);

drop policy if exists factor_leer on public.factor_riesgo;
create policy factor_leer on public.factor_riesgo
  for select to authenticated using (true);

-- Inserción de atenciones: solo médicos autenticados registran con su propio usuario (F-04)
create or replace function public.es_medico()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.usuario u join public.rol r using (id_rol)
    where u.id_usuario = auth.uid() and r.nombre = 'medico' and u.activo
  );
$$;

drop policy if exists atencion_insertar_medico on public.atencion;
create policy atencion_insertar_medico on public.atencion
  for insert to authenticated
  with check (
    id_usuario = auth.uid() and public.es_medico()
  );

-- Inserción en predicción y factores: gestionado por el sistema/trigger o médico autorizado
drop policy if exists prediccion_insertar_medico on public.prediccion_reingreso;
create policy prediccion_insertar_medico on public.prediccion_reingreso
  for insert to authenticated
  with check (
    exists (
      select 1 from public.atencion a
      where a.id_atencion = prediccion_reingreso.id_atencion
        and a.id_usuario = auth.uid()
    )
  );

drop policy if exists factor_insertar_medico on public.factor_riesgo;
create policy factor_insertar_medico on public.factor_riesgo
  for insert to authenticated
  with check (
    exists (
      select 1 from public.prediccion_reingreso pr
      join public.atencion a using (id_atencion)
      where pr.id_prediccion = factor_riesgo.id_prediccion
        and a.id_usuario = auth.uid()
    )
  );

-- Revocar modificaciones destructivas para no alterar la integridad del expediente
revoke update, delete, truncate on
  public.paciente, public.identificador_paciente, public.atencion,
  public.prediccion_reingreso, public.factor_riesgo
  from anon, authenticated;
