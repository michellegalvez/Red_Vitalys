-- 004 · Pacientes, atenciones y riesgo de reingreso (TS-06, TS-05, TS-18).
-- Se pega completo en Supabase → SQL Editor → Run. Se puede correr otra vez.
-- Los datos de prueba usan fechas fijas, porque en la app "hoy" es el 6 de
-- noviembre de 2026 (RNF-04).

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
  id_paciente bigint not null references public.paciente (id_paciente),
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
  id_paciente bigint not null references public.paciente (id_paciente),
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

create table if not exists public.prediccion_reingreso (
  id_prediccion bigint generated always as identity primary key,
  id_atencion bigint not null references public.atencion (id_atencion),
  score_riesgo numeric(5, 2) not null
    check (score_riesgo >= 0 and score_riesgo <= 100),
  fecha_prediccion date not null
);

create table if not exists public.factor_riesgo (
  id_factor bigint generated always as identity primary key,
  id_prediccion bigint not null
    references public.prediccion_reingreso (id_prediccion),
  variable text not null,
  contribucion numeric(8, 4) not null
);

-- La auditoría ya puede apuntar a un paciente.
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

-- Permisos (RLS): solo lectura para quien tiene sesión; nadie escribe desde la app
-- todavía (el registro de atenciones llega con su propia tarea).

alter table public.paciente enable row level security;
alter table public.identificador_paciente enable row level security;
alter table public.atencion enable row level security;
alter table public.prediccion_reingreso enable row level security;
alter table public.factor_riesgo enable row level security;

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

revoke insert, update, delete, truncate on
  public.paciente, public.identificador_paciente, public.atencion,
  public.prediccion_reingreso, public.factor_riesgo
  from anon, authenticated;

-- Datos de prueba (los de lib/datos/datos_simulados.dart).
-- Solo se cargan si la tabla paciente está vacía.

do $$
declare
  hoy_simulado constant date := date '2026-11-06';
  sistema bigint;
  medico_camila uuid;
  medico_tomas uuid;
  fila record;
  v_paciente bigint;
  v_atencion bigint;
  v_prediccion bigint;
  v_medico uuid;
  escala numeric;
begin
  if exists (select 1 from public.paciente) then
    raise notice 'paciente ya tiene datos: no se carga nada';
    return;
  end if;

  select id_sistema into sistema from public.sistema_origen
    where nombre = 'Historia clínica Red Vitalys';
  select id_usuario into medico_camila from public.usuario
    where correo = 'camila.martinez@vitalys.co';
  select id_usuario into medico_tomas from public.usuario
    where correo = 'tomas.herrera@vitalys.co';
  if sistema is null or medico_camila is null or medico_tomas is null then
    raise exception 'Faltan el sistema de origen o los médicos de prueba (scripts 001 y 002)';
  end if;

  for fila in
    select * from (values
      ('Jorge', 'Eliécer', 'Pardo', 'Villamizar', 78, 'M', 'CC', '79457654', 'Clínica Vitalys Bogotá Usaquén', 'hospitalizacion', date '2026-10-14', 15, 91, true),
      ('María', 'Fernanda', 'Rojas', 'Benítez', 75, 'F', 'CC', '31285876', 'Clínica Vitalys Cali Norte', 'hospitalizacion', date '2026-10-16', 11, 82, false),
      ('Hernán', 'Darío', 'Quintero', 'Salcedo', 71, 'M', 'CC', '72105531', 'Clínica Vitalys Barranquilla Prado', 'hospitalizacion', date '2026-10-17', 16, 77, false),
      ('Carlos', 'Andrés', 'Gómez', 'Ruiz', 63, 'M', 'CC', '80234310', 'Clínica Vitalys Bogotá Chapinero', 'hospitalizacion', date '2026-10-15', 7, 72, false),
      ('Luz', 'Marina', 'Cardona', 'Arias', 67, 'F', 'CC', '43518902', 'Clínica Vitalys Medellín El Poblado', 'urgencias', date '2026-10-15', 1, 48, false),
      ('Ana', 'Lucía', 'Ibarra', 'Medina', 58, 'F', 'CC', '63451204', 'Clínica Vitalys Bucaramanga Cabecera', 'hospitalizacion', date '2026-10-18', 6, 37, false),
      ('Santiago', null, 'Restrepo', 'Mejía', 14, 'M', 'TI', '1023456778', 'Clínica Vitalys Medellín El Poblado', 'hospitalizacion', date '2026-10-13', 3, 23, false),
      ('Valentina', null, 'Ortiz', 'Salazar', 3, 'F', 'RC', '1107052145', 'Centro Ambulatorio Cali Sur', 'urgencias', date '2026-10-19', 0, 12, false),
      ('Rosa', 'Elena', 'Muñoz', 'Patiño', 81, 'F', 'CC', '29874512', 'Clínica Vitalys Cali Norte', 'hospitalizacion', date '2026-09-22', 9, 88, false),
      ('Ricardo', 'Alberto', 'Henao', 'Zuluaga', 69, 'M', 'CC', '70589234', 'Clínica Vitalys Bogotá Chapinero', 'hospitalizacion', date '2026-09-20', 8, 54, false),
      ('Gloria', 'Patricia', 'Mejía', 'Londoño', 72, 'F', 'CC', '43217655', 'Clínica Vitalys Medellín El Poblado', 'hospitalizacion', date '2026-08-30', 12, 66, false),
      ('Andrés', 'Felipe', 'Cárdenas', 'Rueda', 45, 'M', 'CC', '1098765432', 'Clínica Vitalys Bucaramanga Cabecera', 'urgencias', date '2026-10-02', 0, 31, false),
      ('Daniela', 'Sofía', 'Pineda', 'Ocampo', 29, 'F', 'CC', '1144092211', 'Clínica Vitalys Cali Norte', 'hospitalizacion', date '2026-07-15', 4, 18, false)
    ) as t(n1, n2, a1, a2, edad, sexo, tipo_doc, numero, sede, tipo_atencion,
           alta, dias, riesgo, de_camila)
  loop
    insert into public.paciente
      (primer_nombre, segundo_nombre, primer_apellido, segundo_apellido,
       fecha_nacimiento, sexo)
    values
      (fila.n1, fila.n2, fila.a1, fila.a2,
       hoy_simulado - (fila.edad * 365 + fila.edad / 4 + 30), fila.sexo)
    returning id_paciente into v_paciente;

    insert into public.identificador_paciente
      (id_paciente, id_sistema, tipo_documento, numero_identificacion, es_principal)
    values (v_paciente, sistema, fila.tipo_doc, fila.numero, true);

    v_medico := case when fila.de_camila then medico_camila else medico_tomas end;
    insert into public.atencion
      (id_paciente, id_sede, id_usuario, tipo_atencion, fecha_inicio,
       fecha_fin, destino_alta, proposito)
    select v_paciente, s.id_sede, v_medico, fila.tipo_atencion,
      ((fila.alta - fila.dias + time '08:00') at time zone 'America/Bogota'),
      ((fila.alta + time '12:00') at time zone 'America/Bogota'),
      'Domicilio',
      case when fila.de_camila then 'atencion_paciente' else 'seguimiento_reingreso' end
    from public.sede s where s.nombre = fila.sede
    returning id_atencion into v_atencion;

    insert into public.prediccion_reingreso
      (id_atencion, score_riesgo, fecha_prediccion)
    values (v_atencion, fila.riesgo, fila.alta)
    returning id_prediccion into v_prediccion;

    escala := fila.riesgo / 91.0;
    if fila.de_camila then
      insert into public.factor_riesgo (id_prediccion, variable, contribucion)
      values
        (v_prediccion, 'Estancia de esta hospitalización', 20),
        (v_prediccion, 'Consultas a urgencias en los últimos 12 meses', 16),
        (v_prediccion, 'Edad', 14),
        (v_prediccion, 'Condiciones crónicas registradas', 7),
        (v_prediccion, 'Destino al alta', 5),
        (v_prediccion, 'Seguimiento ambulatorio programado', -8);
    else
      insert into public.factor_riesgo (id_prediccion, variable, contribucion)
      values
        (v_prediccion, 'Estancia de esta hospitalización', greatest(1, round(20 * escala))),
        (v_prediccion, 'Consultas a urgencias en los últimos 12 meses', greatest(1, round(16 * escala))),
        (v_prediccion, 'Edad', greatest(1, round(14 * escala))),
        (v_prediccion, 'Condiciones crónicas registradas', greatest(1, round(7 * escala))),
        (v_prediccion, 'Seguimiento ambulatorio programado', -greatest(1, round(8 * escala)));
    end if;
  end loop;
end $$;

-- Debe devolver 13 pacientes, 13 atenciones, 13 predicciones y 66 factores.
select
  (select count(*) from public.paciente) as pacientes,
  (select count(*) from public.atencion) as atenciones,
  (select count(*) from public.prediccion_reingreso) as predicciones,
  (select count(*) from public.factor_riesgo) as factores;
