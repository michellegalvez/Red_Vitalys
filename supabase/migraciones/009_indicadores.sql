-- 009 · Indicadores de calidad y sus mediciones (F-08 a F-12).
-- Se pega completo en Supabase → SQL Editor → Run. Se puede correr otra vez.
-- Las mediciones de prueba son las de lib/datos/indicadores_simulados.dart
-- (los 6 meses cerrados antes del 6 nov 2026). Una medición no se edita ni
-- se borra, y no se repite para el mismo indicador, sede y mes.

create table if not exists public.indicador (
  id_indicador bigint generated always as identity primary key,
  codigo text not null unique
    check (codigo in ('reingreso', 'espera', 'adherencia', 'eventos')),
  nombre text not null,
  categoria text not null check (categoria in ('Resultado', 'Estructura', 'Proceso')),
  unidad_medida text not null,
  descripcion text not null,
  unidad_cambio text not null,
  valor_minimo numeric not null,
  valor_maximo numeric not null,
  direccion text not null
    check (direccion in ('mas_bajo_es_mejor', 'mas_alto_es_mejor'))
);

create table if not exists public.indicador_tipo_sede (
  id_indicador bigint not null references public.indicador (id_indicador),
  tipo_sede text not null
    check (tipo_sede in ('clinica', 'centro_ambulatorio', 'laboratorio')),
  primary key (id_indicador, tipo_sede)
);

create table if not exists public.medicion_indicador (
  id_medicion bigint generated always as identity primary key,
  id_indicador bigint not null references public.indicador (id_indicador),
  id_sede bigint not null references public.sede (id_sede),
  periodo_inicio date not null,
  periodo_fin date not null,
  valor numeric(12, 4) not null check (valor = round(valor, 1)),
  registrada_por uuid references public.usuario (id_usuario),
  registrada_en timestamptz not null default now(),
  constraint medicion_un_mes check (
    periodo_inicio = date_trunc('month', periodo_inicio)::date
    and periodo_fin = (periodo_inicio + interval '1 month - 1 day')::date
  ),
  unique (id_indicador, id_sede, periodo_inicio)
);

-- Solo se agrega: nadie edita ni borra una medición (F-12).
create or replace function public.bloquear_cambios_medicion()
returns trigger language plpgsql as $$
begin
  raise exception 'Una medición registrada no se edita ni se borra';
end;
$$;

drop trigger if exists medicion_solo_agregar on public.medicion_indicador;
create trigger medicion_solo_agregar
  before update or delete on public.medicion_indicador
  for each row execute function public.bloquear_cambios_medicion();

alter table public.indicador enable row level security;
alter table public.indicador_tipo_sede enable row level security;
alter table public.medicion_indicador enable row level security;

revoke insert, update, delete, truncate on
  public.indicador, public.indicador_tipo_sede from anon, authenticated;
revoke update, delete, truncate on public.medicion_indicador
  from anon, authenticated;
grant insert on public.medicion_indicador to authenticated;

-- Los tres roles ven el tablero (F-18); solo el administrativo registra.
drop policy if exists indicador_leer on public.indicador;
create policy indicador_leer on public.indicador
  for select to authenticated using (public.rol_actual() is not null);
drop policy if exists indicador_tipo_sede_leer on public.indicador_tipo_sede;
create policy indicador_tipo_sede_leer on public.indicador_tipo_sede
  for select to authenticated using (public.rol_actual() is not null);
drop policy if exists medicion_leer on public.medicion_indicador;
create policy medicion_leer on public.medicion_indicador
  for select to authenticated using (public.rol_actual() is not null);
drop policy if exists medicion_registrar on public.medicion_indicador;
create policy medicion_registrar on public.medicion_indicador
  for insert to authenticated
  with check (
    public.rol_actual() = 'administrativo'
    and registrada_por = auth.uid()
    and periodo_fin < current_date
  );

-- La tabla de indicadores de los requisitos.
insert into public.indicador
  (codigo, nombre, categoria, unidad_medida, descripcion, unidad_cambio,
   valor_minimo, valor_maximo, direccion)
values
  ('reingreso', 'Reingreso hospitalario a 30 días', 'Resultado', '%',
   'Pacientes que vuelven a hospitalizarse en los 30 días siguientes al alta, sobre el total de egresos.',
   'puntos', 0, 100, 'mas_bajo_es_mejor'),
  ('espera', 'Tiempo de espera promedio', 'Estructura', 'min',
   'Minutos que tarda en atenderse un paciente desde que llega a la sede.',
   'min', 0, 1440, 'mas_bajo_es_mejor'),
  ('adherencia', 'Adherencia a protocolos clínicos', 'Proceso', '%',
   'Porcentaje de atenciones que cumplen el protocolo clínico definido.',
   'puntos', 0, 100, 'mas_alto_es_mejor'),
  ('eventos', 'Eventos adversos evitables', 'Resultado', 'por 1.000',
   'Incidentes dañinos para el paciente que se pudieron prevenir, por cada 1.000 atenciones.',
   'por 1.000', 0, 1000, 'mas_bajo_es_mejor')
on conflict (codigo) do nothing;

insert into public.indicador_tipo_sede (id_indicador, tipo_sede)
select i.id_indicador, v.tipo
from public.indicador i
join (values
  ('reingreso', 'clinica'),
  ('espera', 'clinica'), ('espera', 'centro_ambulatorio'),
  ('adherencia', 'clinica'), ('adherencia', 'centro_ambulatorio'),
  ('eventos', 'clinica'), ('eventos', 'centro_ambulatorio')
) as v(codigo, tipo) on v.codigo = i.codigo
on conflict do nothing;

insert into public.medicion_indicador
  (id_indicador, id_sede, periodo_inicio, periodo_fin, valor)
select i.id_indicador, s.id_sede, v.mes,
  (v.mes + interval '1 month - 1 day')::date, v.valor
from (values
    ('reingreso', 'Clínica Vitalys Cali Norte', date '2026-05-01', 11.2),
    ('reingreso', 'Clínica Vitalys Cali Norte', date '2026-06-01', 10.8),
    ('reingreso', 'Clínica Vitalys Cali Norte', date '2026-07-01', 10.5),
    ('reingreso', 'Clínica Vitalys Cali Norte', date '2026-08-01', 10.3),
    ('reingreso', 'Clínica Vitalys Cali Norte', date '2026-09-01', 10.1),
    ('reingreso', 'Clínica Vitalys Cali Norte', date '2026-10-01', 9.8),
    ('reingreso', 'Clínica Vitalys Bogotá Usaquén', date '2026-05-01', 8.3),
    ('reingreso', 'Clínica Vitalys Bogotá Usaquén', date '2026-06-01', 7.9),
    ('reingreso', 'Clínica Vitalys Bogotá Usaquén', date '2026-07-01', 7.6),
    ('reingreso', 'Clínica Vitalys Bogotá Usaquén', date '2026-08-01', 7.3),
    ('reingreso', 'Clínica Vitalys Bogotá Usaquén', date '2026-09-01', 7.1),
    ('reingreso', 'Clínica Vitalys Bogotá Usaquén', date '2026-10-01', 6.8),
    ('reingreso', 'Clínica Vitalys Bogotá Chapinero', date '2026-05-01', 9.1),
    ('reingreso', 'Clínica Vitalys Bogotá Chapinero', date '2026-06-01', 8.6),
    ('reingreso', 'Clínica Vitalys Bogotá Chapinero', date '2026-07-01', 8.3),
    ('reingreso', 'Clínica Vitalys Bogotá Chapinero', date '2026-08-01', 8.0),
    ('reingreso', 'Clínica Vitalys Bogotá Chapinero', date '2026-09-01', 7.7),
    ('reingreso', 'Clínica Vitalys Bogotá Chapinero', date '2026-10-01', 7.4),
    ('reingreso', 'Clínica Vitalys Medellín El Poblado', date '2026-05-01', 9.4),
    ('reingreso', 'Clínica Vitalys Medellín El Poblado', date '2026-06-01', 9.0),
    ('reingreso', 'Clínica Vitalys Medellín El Poblado', date '2026-07-01', 8.7),
    ('reingreso', 'Clínica Vitalys Medellín El Poblado', date '2026-08-01', 8.5),
    ('reingreso', 'Clínica Vitalys Medellín El Poblado', date '2026-09-01', 8.3),
    ('reingreso', 'Clínica Vitalys Medellín El Poblado', date '2026-10-01', 8.0),
    ('reingreso', 'Clínica Vitalys Barranquilla Prado', date '2026-05-01', 10.1),
    ('reingreso', 'Clínica Vitalys Barranquilla Prado', date '2026-06-01', 9.7),
    ('reingreso', 'Clínica Vitalys Barranquilla Prado', date '2026-07-01', 9.4),
    ('reingreso', 'Clínica Vitalys Barranquilla Prado', date '2026-08-01', 9.1),
    ('reingreso', 'Clínica Vitalys Barranquilla Prado', date '2026-09-01', 8.9),
    ('reingreso', 'Clínica Vitalys Barranquilla Prado', date '2026-10-01', 8.6),
    ('reingreso', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-05-01', 10.9),
    ('reingreso', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-06-01', 10.4),
    ('reingreso', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-07-01', 10.1),
    ('reingreso', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-08-01', 9.8),
    ('reingreso', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-09-01', 9.5),
    ('reingreso', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-10-01', 9.2),
    ('espera', 'Clínica Vitalys Cali Norte', date '2026-05-01', 33.8),
    ('espera', 'Clínica Vitalys Cali Norte', date '2026-06-01', 32.9),
    ('espera', 'Clínica Vitalys Cali Norte', date '2026-07-01', 32.0),
    ('espera', 'Clínica Vitalys Cali Norte', date '2026-08-01', 30.7),
    ('espera', 'Clínica Vitalys Cali Norte', date '2026-09-01', 29.8),
    ('espera', 'Clínica Vitalys Cali Norte', date '2026-10-01', 28.4),
    ('espera', 'Clínica Vitalys Bogotá Usaquén', date '2026-05-01', 37.2),
    ('espera', 'Clínica Vitalys Bogotá Usaquén', date '2026-06-01', 36.2),
    ('espera', 'Clínica Vitalys Bogotá Usaquén', date '2026-07-01', 35.2),
    ('espera', 'Clínica Vitalys Bogotá Usaquén', date '2026-08-01', 33.7),
    ('espera', 'Clínica Vitalys Bogotá Usaquén', date '2026-09-01', 32.7),
    ('espera', 'Clínica Vitalys Bogotá Usaquén', date '2026-10-01', 31.2),
    ('espera', 'Clínica Vitalys Bogotá Chapinero', date '2026-05-01', 31.2),
    ('espera', 'Clínica Vitalys Bogotá Chapinero', date '2026-06-01', 30.1),
    ('espera', 'Clínica Vitalys Bogotá Chapinero', date '2026-07-01', 29.0),
    ('espera', 'Clínica Vitalys Bogotá Chapinero', date '2026-08-01', 27.4),
    ('espera', 'Clínica Vitalys Bogotá Chapinero', date '2026-09-01', 26.3),
    ('espera', 'Clínica Vitalys Bogotá Chapinero', date '2026-10-01', 24.6),
    ('espera', 'Clínica Vitalys Medellín El Poblado', date '2026-05-01', 28.2),
    ('espera', 'Clínica Vitalys Medellín El Poblado', date '2026-06-01', 27.3),
    ('espera', 'Clínica Vitalys Medellín El Poblado', date '2026-07-01', 26.4),
    ('espera', 'Clínica Vitalys Medellín El Poblado', date '2026-08-01', 25.1),
    ('espera', 'Clínica Vitalys Medellín El Poblado', date '2026-09-01', 24.2),
    ('espera', 'Clínica Vitalys Medellín El Poblado', date '2026-10-01', 22.8),
    ('espera', 'Clínica Vitalys Barranquilla Prado', date '2026-05-01', 33.0),
    ('espera', 'Clínica Vitalys Barranquilla Prado', date '2026-06-01', 32.0),
    ('espera', 'Clínica Vitalys Barranquilla Prado', date '2026-07-01', 31.0),
    ('espera', 'Clínica Vitalys Barranquilla Prado', date '2026-08-01', 29.5),
    ('espera', 'Clínica Vitalys Barranquilla Prado', date '2026-09-01', 28.5),
    ('espera', 'Clínica Vitalys Barranquilla Prado', date '2026-10-01', 27.0),
    ('espera', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-05-01', 27.0),
    ('espera', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-06-01', 25.9),
    ('espera', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-07-01', 24.8),
    ('espera', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-08-01', 23.2),
    ('espera', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-09-01', 22.0),
    ('espera', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-10-01', 20.4),
    ('espera', 'Centro Ambulatorio Cali Sur', date '2026-05-01', 32.0),
    ('espera', 'Centro Ambulatorio Cali Sur', date '2026-06-01', 31.1),
    ('espera', 'Centro Ambulatorio Cali Sur', date '2026-07-01', 30.2),
    ('espera', 'Centro Ambulatorio Cali Sur', date '2026-08-01', 28.9),
    ('espera', 'Centro Ambulatorio Cali Sur', date '2026-09-01', 28.0),
    ('espera', 'Centro Ambulatorio Cali Sur', date '2026-10-01', 26.6),
    ('espera', 'Centro Ambulatorio Envigado', date '2026-05-01', 31.4),
    ('espera', 'Centro Ambulatorio Envigado', date '2026-06-01', 30.4),
    ('espera', 'Centro Ambulatorio Envigado', date '2026-07-01', 29.4),
    ('espera', 'Centro Ambulatorio Envigado', date '2026-08-01', 27.9),
    ('espera', 'Centro Ambulatorio Envigado', date '2026-09-01', 26.9),
    ('espera', 'Centro Ambulatorio Envigado', date '2026-10-01', 25.4),
    ('adherencia', 'Clínica Vitalys Cali Norte', date '2026-05-01', 80.2),
    ('adherencia', 'Clínica Vitalys Cali Norte', date '2026-06-01', 80.9),
    ('adherencia', 'Clínica Vitalys Cali Norte', date '2026-07-01', 81.6),
    ('adherencia', 'Clínica Vitalys Cali Norte', date '2026-08-01', 82.5),
    ('adherencia', 'Clínica Vitalys Cali Norte', date '2026-09-01', 83.2),
    ('adherencia', 'Clínica Vitalys Cali Norte', date '2026-10-01', 84.2),
    ('adherencia', 'Clínica Vitalys Bogotá Usaquén', date '2026-05-01', 78.1),
    ('adherencia', 'Clínica Vitalys Bogotá Usaquén', date '2026-06-01', 78.9),
    ('adherencia', 'Clínica Vitalys Bogotá Usaquén', date '2026-07-01', 79.7),
    ('adherencia', 'Clínica Vitalys Bogotá Usaquén', date '2026-08-01', 80.7),
    ('adherencia', 'Clínica Vitalys Bogotá Usaquén', date '2026-09-01', 81.5),
    ('adherencia', 'Clínica Vitalys Bogotá Usaquén', date '2026-10-01', 82.6),
    ('adherencia', 'Clínica Vitalys Bogotá Chapinero', date '2026-05-01', 83.1),
    ('adherencia', 'Clínica Vitalys Bogotá Chapinero', date '2026-06-01', 84.0),
    ('adherencia', 'Clínica Vitalys Bogotá Chapinero', date '2026-07-01', 84.9),
    ('adherencia', 'Clínica Vitalys Bogotá Chapinero', date '2026-08-01', 86.0),
    ('adherencia', 'Clínica Vitalys Bogotá Chapinero', date '2026-09-01', 86.9),
    ('adherencia', 'Clínica Vitalys Bogotá Chapinero', date '2026-10-01', 88.1),
    ('adherencia', 'Clínica Vitalys Medellín El Poblado', date '2026-05-01', 86.3),
    ('adherencia', 'Clínica Vitalys Medellín El Poblado', date '2026-06-01', 87.0),
    ('adherencia', 'Clínica Vitalys Medellín El Poblado', date '2026-07-01', 87.7),
    ('adherencia', 'Clínica Vitalys Medellín El Poblado', date '2026-08-01', 88.6),
    ('adherencia', 'Clínica Vitalys Medellín El Poblado', date '2026-09-01', 89.3),
    ('adherencia', 'Clínica Vitalys Medellín El Poblado', date '2026-10-01', 90.3),
    ('adherencia', 'Clínica Vitalys Barranquilla Prado', date '2026-05-01', 81.0),
    ('adherencia', 'Clínica Vitalys Barranquilla Prado', date '2026-06-01', 81.8),
    ('adherencia', 'Clínica Vitalys Barranquilla Prado', date '2026-07-01', 82.6),
    ('adherencia', 'Clínica Vitalys Barranquilla Prado', date '2026-08-01', 83.6),
    ('adherencia', 'Clínica Vitalys Barranquilla Prado', date '2026-09-01', 84.4),
    ('adherencia', 'Clínica Vitalys Barranquilla Prado', date '2026-10-01', 85.5),
    ('adherencia', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-05-01', 86.1),
    ('adherencia', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-06-01', 86.9),
    ('adherencia', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-07-01', 87.8),
    ('adherencia', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-08-01', 88.9),
    ('adherencia', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-09-01', 89.8),
    ('adherencia', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-10-01', 91.0),
    ('adherencia', 'Centro Ambulatorio Cali Sur', date '2026-05-01', 83.1),
    ('adherencia', 'Centro Ambulatorio Cali Sur', date '2026-06-01', 83.8),
    ('adherencia', 'Centro Ambulatorio Cali Sur', date '2026-07-01', 84.5),
    ('adherencia', 'Centro Ambulatorio Cali Sur', date '2026-08-01', 85.4),
    ('adherencia', 'Centro Ambulatorio Cali Sur', date '2026-09-01', 86.1),
    ('adherencia', 'Centro Ambulatorio Cali Sur', date '2026-10-01', 87.1),
    ('adherencia', 'Centro Ambulatorio Envigado', date '2026-05-01', 81.9),
    ('adherencia', 'Centro Ambulatorio Envigado', date '2026-06-01', 82.7),
    ('adherencia', 'Centro Ambulatorio Envigado', date '2026-07-01', 83.5),
    ('adherencia', 'Centro Ambulatorio Envigado', date '2026-08-01', 84.5),
    ('adherencia', 'Centro Ambulatorio Envigado', date '2026-09-01', 85.3),
    ('adherencia', 'Centro Ambulatorio Envigado', date '2026-10-01', 86.4),
    ('eventos', 'Clínica Vitalys Cali Norte', date '2026-05-01', 2.9),
    ('eventos', 'Clínica Vitalys Cali Norte', date '2026-06-01', 2.8),
    ('eventos', 'Clínica Vitalys Cali Norte', date '2026-07-01', 2.7),
    ('eventos', 'Clínica Vitalys Cali Norte', date '2026-08-01', 2.6),
    ('eventos', 'Clínica Vitalys Cali Norte', date '2026-09-01', 2.5),
    ('eventos', 'Clínica Vitalys Cali Norte', date '2026-10-01', 2.4),
    ('eventos', 'Clínica Vitalys Bogotá Usaquén', date '2026-05-01', 2.7),
    ('eventos', 'Clínica Vitalys Bogotá Usaquén', date '2026-06-01', 2.5),
    ('eventos', 'Clínica Vitalys Bogotá Usaquén', date '2026-07-01', 2.4),
    ('eventos', 'Clínica Vitalys Bogotá Usaquén', date '2026-08-01', 2.3),
    ('eventos', 'Clínica Vitalys Bogotá Usaquén', date '2026-09-01', 2.2),
    ('eventos', 'Clínica Vitalys Bogotá Usaquén', date '2026-10-01', 2.1),
    ('eventos', 'Clínica Vitalys Bogotá Chapinero', date '2026-05-01', 2.6),
    ('eventos', 'Clínica Vitalys Bogotá Chapinero', date '2026-06-01', 2.3),
    ('eventos', 'Clínica Vitalys Bogotá Chapinero', date '2026-07-01', 2.2),
    ('eventos', 'Clínica Vitalys Bogotá Chapinero', date '2026-08-01', 2.1),
    ('eventos', 'Clínica Vitalys Bogotá Chapinero', date '2026-09-01', 2.0),
    ('eventos', 'Clínica Vitalys Bogotá Chapinero', date '2026-10-01', 1.9),
    ('eventos', 'Clínica Vitalys Medellín El Poblado', date '2026-05-01', 1.9),
    ('eventos', 'Clínica Vitalys Medellín El Poblado', date '2026-06-01', 1.8),
    ('eventos', 'Clínica Vitalys Medellín El Poblado', date '2026-07-01', 1.7),
    ('eventos', 'Clínica Vitalys Medellín El Poblado', date '2026-08-01', 1.6),
    ('eventos', 'Clínica Vitalys Medellín El Poblado', date '2026-09-01', 1.5),
    ('eventos', 'Clínica Vitalys Medellín El Poblado', date '2026-10-01', 1.4),
    ('eventos', 'Clínica Vitalys Barranquilla Prado', date '2026-05-01', 2.3),
    ('eventos', 'Clínica Vitalys Barranquilla Prado', date '2026-06-01', 2.1),
    ('eventos', 'Clínica Vitalys Barranquilla Prado', date '2026-07-01', 2.0),
    ('eventos', 'Clínica Vitalys Barranquilla Prado', date '2026-08-01', 1.9),
    ('eventos', 'Clínica Vitalys Barranquilla Prado', date '2026-09-01', 1.8),
    ('eventos', 'Clínica Vitalys Barranquilla Prado', date '2026-10-01', 1.7),
    ('eventos', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-05-01', 1.9),
    ('eventos', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-06-01', 1.6),
    ('eventos', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-07-01', 1.5),
    ('eventos', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-08-01', 1.4),
    ('eventos', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-09-01', 1.3),
    ('eventos', 'Clínica Vitalys Bucaramanga Cabecera', date '2026-10-01', 1.2),
    ('eventos', 'Centro Ambulatorio Cali Sur', date '2026-05-01', 2.5),
    ('eventos', 'Centro Ambulatorio Cali Sur', date '2026-06-01', 2.4),
    ('eventos', 'Centro Ambulatorio Cali Sur', date '2026-07-01', 2.3),
    ('eventos', 'Centro Ambulatorio Cali Sur', date '2026-08-01', 2.2),
    ('eventos', 'Centro Ambulatorio Cali Sur', date '2026-09-01', 2.1),
    ('eventos', 'Centro Ambulatorio Cali Sur', date '2026-10-01', 2.0),
    ('eventos', 'Centro Ambulatorio Envigado', date '2026-05-01', 2.3),
    ('eventos', 'Centro Ambulatorio Envigado', date '2026-06-01', 2.1),
    ('eventos', 'Centro Ambulatorio Envigado', date '2026-07-01', 2.0),
    ('eventos', 'Centro Ambulatorio Envigado', date '2026-08-01', 1.9),
    ('eventos', 'Centro Ambulatorio Envigado', date '2026-09-01', 1.8)
) as v(codigo, sede, mes, valor)
join public.indicador i on i.codigo = v.codigo
join public.sede s on s.nombre = v.sede
on conflict (id_indicador, id_sede, periodo_inicio) do nothing;

-- Debe devolver 4 indicadores, 7 tipos de sede y al menos 179 mediciones.
select
  (select count(*) from public.indicador) as indicadores,
  (select count(*) from public.indicador_tipo_sede) as tipos_de_sede,
  (select count(*) from public.medicion_indicador) as mediciones;
