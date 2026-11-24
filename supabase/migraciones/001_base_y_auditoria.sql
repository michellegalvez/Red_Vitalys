-- 001 · Tablas comunes y auditoría (plan P-01, modelo docs/modelo.md).
-- Se pega completo en Supabase → SQL Editor → Run. Se puede correr otra vez.
-- No crea paciente, atencion, riesgo ni indicadores: son de otras personas.

create table if not exists public.rol (
  id_rol bigint generated always as identity primary key,
  nombre text not null unique
    check (nombre in ('medico', 'administrativo', 'auditor'))
);

create table if not exists public.sistema_origen (
  id_sistema bigint generated always as identity primary key,
  nombre text not null unique,
  tipo text not null
);

create table if not exists public.sede (
  id_sede bigint generated always as identity primary key,
  id_sistema bigint not null references public.sistema_origen (id_sistema),
  nombre text not null,
  nombre_corto text not null,
  tipo_sede text not null
    check (tipo_sede in ('clinica', 'centro_ambulatorio', 'laboratorio')),
  ciudad text not null
);

-- El id es el mismo uuid de Supabase Auth. La contraseña la guarda Auth.
create table if not exists public.usuario (
  id_usuario uuid primary key references auth.users (id) on delete cascade,
  id_rol bigint not null references public.rol (id_rol),
  nombre_completo text not null,
  correo text not null unique,
  activo boolean not null default true,
  foto_ruta text
);

create table if not exists public.usuario_sede (
  id_usuario uuid not null references public.usuario (id_usuario) on delete cascade,
  id_sede bigint not null references public.sede (id_sede),
  primary key (id_usuario, id_sede)
);

-- Auditoría

-- id_paciente no tiene llave foránea porque la tabla paciente aún no existe
-- (ver el final del archivo).
create table if not exists public.evento_auditoria (
  id_evento bigint generated always as identity primary key,
  id_usuario uuid references public.usuario (id_usuario),
  id_paciente bigint,
  fecha_hora_evento timestamptz not null default now(),
  accion text not null check (accion in ('ingresar', 'consultar', 'registrar')),
  tipo_recurso text not null check (tipo_recurso in (
    'sesion', 'datos_basicos', 'historia_clinica', 'riesgo_reingreso',
    'atencion', 'medicion_indicador', 'pacientes_alta_reciente',
    'auditoria_accesos'
  )),
  resultado text not null check (resultado in ('permitido', 'denegado')),
  proposito_uso text check (proposito_uso in (
    'seguimiento_reingreso', 'consulta_historia', 'atencion_paciente',
    'revision_calidad', 'urgencia'
  )),
  id_sede bigint references public.sede (id_sede),
  correo_intento text,
  -- La IP la pone la base, no la app.
  ip inet default nullif(
    trim(split_part(
      coalesce(current_setting('request.headers', true)::json ->> 'x-forwarded-for', ''),
      ',', 1)),
    '')::inet,
  -- Sin usuario solo se acepta un inicio de sesión fallido.
  constraint evento_sin_usuario_es_ingreso_fallido check (
    id_usuario is not null
    or (accion = 'ingresar' and tipo_recurso = 'sesion'
        and resultado = 'denegado' and correo_intento is not null)
  )
);

create index if not exists evento_auditoria_fecha_idx
  on public.evento_auditoria (fecha_hora_evento desc);

-- Solo se agrega: nadie edita ni borra un evento.
create or replace function public.bloquear_cambios_auditoria()
returns trigger language plpgsql as $$
begin
  raise exception 'La auditoría es de solo agregar: no se puede % un evento',
    lower(tg_op);
end;
$$;

drop trigger if exists evento_auditoria_solo_agregar on public.evento_auditoria;
create trigger evento_auditoria_solo_agregar
  before update or delete on public.evento_auditoria
  for each row execute function public.bloquear_cambios_auditoria();

revoke update, delete, truncate on public.evento_auditoria from anon, authenticated;

-- Permisos (RLS)

create or replace function public.es_auditor()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.usuario u join public.rol r using (id_rol)
    where u.id_usuario = auth.uid() and r.nombre = 'auditor' and u.activo
  );
$$;

alter table public.evento_auditoria enable row level security;

drop policy if exists auditoria_insertar_usuario on public.evento_auditoria;
create policy auditoria_insertar_usuario on public.evento_auditoria
  for insert to authenticated
  with check (id_usuario = auth.uid());

-- Quien falla al iniciar sesión todavía no tiene sesión.
drop policy if exists auditoria_insertar_ingreso_fallido on public.evento_auditoria;
create policy auditoria_insertar_ingreso_fallido on public.evento_auditoria
  for insert to anon, authenticated
  with check (
    id_usuario is null and accion = 'ingresar' and tipo_recurso = 'sesion'
    and resultado = 'denegado'
  );

drop policy if exists auditoria_leer_auditor on public.evento_auditoria;
create policy auditoria_leer_auditor on public.evento_auditoria
  for select to authenticated
  using (public.es_auditor());

alter table public.rol enable row level security;
alter table public.sistema_origen enable row level security;
alter table public.sede enable row level security;
alter table public.usuario enable row level security;
alter table public.usuario_sede enable row level security;

drop policy if exists rol_leer on public.rol;
create policy rol_leer on public.rol for select to authenticated using (true);
drop policy if exists sistema_origen_leer on public.sistema_origen;
create policy sistema_origen_leer on public.sistema_origen
  for select to authenticated using (true);
drop policy if exists sede_leer on public.sede;
create policy sede_leer on public.sede for select to authenticated using (true);
drop policy if exists usuario_leer on public.usuario;
create policy usuario_leer on public.usuario for select to authenticated using (true);
drop policy if exists usuario_sede_leer on public.usuario_sede;
create policy usuario_sede_leer on public.usuario_sede
  for select to authenticated using (true);

-- Cada usuario solo puede cambiar su propia foto.
revoke update on public.usuario from authenticated;
grant update (foto_ruta) on public.usuario to authenticated;
drop policy if exists usuario_actualizar_foto on public.usuario;
create policy usuario_actualizar_foto on public.usuario
  for update to authenticated
  using (id_usuario = auth.uid()) with check (id_usuario = auth.uid());

-- Datos iniciales (los de lib/datos/datos_simulados.dart).
-- Los usuarios no van aquí: se crean primero en Authentication → Users.

insert into public.rol (nombre) values ('medico'), ('administrativo'), ('auditor')
  on conflict (nombre) do nothing;

insert into public.sistema_origen (nombre, tipo)
  values ('Historia clínica Red Vitalys', 'historia_clinica')
  on conflict (nombre) do nothing;

insert into public.sede (id_sistema, nombre, nombre_corto, tipo_sede, ciudad)
select so.id_sistema, v.nombre, v.nombre_corto, v.tipo_sede, v.ciudad
from public.sistema_origen so,
  (values
    ('Clínica Vitalys Cali Norte', 'Cali Norte', 'clinica', 'Cali'),
    ('Clínica Vitalys Bogotá Usaquén', 'Bogotá Usaquén', 'clinica', 'Bogotá'),
    ('Clínica Vitalys Bogotá Chapinero', 'Bogotá Chapinero', 'clinica', 'Bogotá'),
    ('Clínica Vitalys Medellín El Poblado', 'Medellín El Poblado', 'clinica', 'Medellín'),
    ('Clínica Vitalys Barranquilla Prado', 'Barranquilla Prado', 'clinica', 'Barranquilla'),
    ('Clínica Vitalys Bucaramanga Cabecera', 'Bucaramanga Cabecera', 'clinica', 'Bucaramanga'),
    ('Centro Ambulatorio Cali Sur', 'Amb. Cali Sur', 'centro_ambulatorio', 'Cali'),
    ('Centro Ambulatorio Envigado', 'Amb. Envigado', 'centro_ambulatorio', 'Envigado'),
    ('Laboratorio Clínico Vitalys Cali', 'Lab. Cali', 'laboratorio', 'Cali'),
    ('Laboratorio Clínico Vitalys Bogotá', 'Lab. Bogotá', 'laboratorio', 'Bogotá')
  ) as v(nombre, nombre_corto, tipo_sede, ciudad)
where so.nombre = 'Historia clínica Red Vitalys'
  and not exists (select 1 from public.sede s where s.nombre = v.nombre);

-- Quien cree la tabla paciente debe correr esto:
-- alter table public.evento_auditoria
--   add constraint evento_auditoria_paciente_fk
--   foreign key (id_paciente) references public.paciente (id_paciente);
