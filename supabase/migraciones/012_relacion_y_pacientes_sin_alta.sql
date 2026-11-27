-- 012 · La base verifica la relación médico-paciente (F-05, F-18) y suma dos
-- pacientes sin alta (F-01, F-02). Requiere 001 a 011.
-- Se pega completo en Supabase → SQL Editor → Run. Se puede correr otra vez.

-- El "hoy" del prototipo, el mismo de lib/datos/datos_simulados.dart (RNF-04).
create or replace function public.hoy_app()
returns date language sql immutable as $$
  select date '2026-11-06';
$$;

-- El médico con sesión tiene relación con el paciente si registró una atención
-- suya con *Atención del paciente*, o si el paciente tuvo un alta en los
-- últimos 30 días en una de sus sedes. Una atención con *Urgencia* no da
-- relación (F-05).
create or replace function public.tiene_relacion(p_id_paciente bigint)
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.rol_actual() = 'medico', false) and (
    exists (
      select 1 from public.atencion a
      where a.id_paciente = p_id_paciente
        and a.id_usuario = auth.uid()
        and a.proposito = 'atencion_paciente'
    )
    or exists (
      select 1 from public.atencion a
      join public.usuario_sede us
        on us.id_sede = a.id_sede and us.id_usuario = auth.uid()
      where a.id_paciente = p_id_paciente
        and a.fecha_fin is not null
        and a.proposito <> 'urgencia'
        and (a.fecha_fin at time zone 'America/Bogota')::date
          between public.hoy_app() - 30 and public.hoy_app()
    )
  );
$$;

revoke all on function public.tiene_relacion(bigint) from public, anon;
grant execute on function public.tiene_relacion(bigint) to authenticated;

-- Registrar una atención con *Atención del paciente* exige relación; con
-- *Urgencia* no (F-04, F-05). Antes la base solo miraba el rol.
drop policy if exists atencion_registrar_medico on public.atencion;
create policy atencion_registrar_medico on public.atencion
  for insert to authenticated
  with check (
    public.rol_actual() = 'medico'
    and id_usuario = auth.uid()
    and (
      proposito = 'urgencia'
      or (proposito = 'atencion_paciente'
          and public.tiene_relacion(id_paciente))
    )
  );

-- Dos pacientes sin alta: una hospitalizada todavía (atención en curso) y uno
-- sin ninguna atención. Se encuentran al buscarlos, pero no entran en la lista
-- de altas recientes, y la historia del segundo dice que no tiene atenciones.
do $$
declare
  sistema bigint;
  medico_tomas uuid;
  v_paciente bigint;
begin
  select id_sistema into sistema from public.sistema_origen
    where nombre = 'Historia clínica Red Vitalys';
  select id_usuario into medico_tomas from public.usuario
    where correo = 'tomas.herrera@vitalys.co';
  if sistema is null or medico_tomas is null then
    raise exception 'Faltan el sistema de origen o el médico de prueba (001 y 002)';
  end if;

  if not exists (
    select 1 from public.identificador_paciente
    where numero_identificacion = '41567823'
  ) then
    insert into public.paciente
      (primer_nombre, segundo_nombre, primer_apellido, segundo_apellido,
       fecha_nacimiento, sexo, telefono, direccion)
    values ('Martha', 'Lucía', 'Vargas', 'Rincón', date '1960-05-12', 'F',
            '313 555 0141', 'Calle 5 # 38-20, Cali')
    returning id_paciente into v_paciente;
    insert into public.identificador_paciente
      (id_paciente, id_sistema, tipo_documento, numero_identificacion, es_principal)
    values (v_paciente, sistema, 'CC', '41567823', true);
    insert into public.atencion
      (id_paciente, id_sede, id_usuario, tipo_atencion, fecha_inicio, proposito)
    select v_paciente, s.id_sede, medico_tomas, 'hospitalizacion',
      ((date '2026-11-03' + time '09:00') at time zone 'America/Bogota'),
      'atencion_paciente'
    from public.sede s where s.nombre = 'Clínica Vitalys Cali Norte';
  end if;

  if not exists (
    select 1 from public.identificador_paciente
    where numero_identificacion = '79811234'
  ) then
    insert into public.paciente
      (primer_nombre, segundo_nombre, primer_apellido, segundo_apellido,
       fecha_nacimiento, sexo)
    values ('Julián', null, 'Ortega', 'Silva', date '1974-02-20', 'M')
    returning id_paciente into v_paciente;
    insert into public.identificador_paciente
      (id_paciente, id_sistema, tipo_documento, numero_identificacion, es_principal)
    values (v_paciente, sistema, 'CC', '79811234', true);
  end if;
end $$;
