-- 014 · Robustez y rendimiento: la atención y la medición se guardan con su
-- evento en una sola operación (F-04, F-12, F-20).
-- Requiere 001 a 013 (013_director.sql ya está aplicado en la base).
-- Se pega completo en Supabase → SQL Editor → Run. Se puede correr otra vez.

-- ---------------------------------------------------------------------------
-- 1. Guardar con su evento, todo o nada
-- ---------------------------------------------------------------------------
-- Antes la app guardaba el evento y después el dato: si el dato fallaba,
-- quedaba un evento "Registrar · Permitido" huérfano, uno más por reintento.
-- Ahora el evento y el dato van en la misma transacción: primero el evento
-- (sin evento no se guarda, F-20) y, si algo falla después, el evento se
-- deshace con el dato. Las funciones hacen las mismas comprobaciones que las
-- políticas de inserción de hoy (008, 009, 012). La hora y la IP del evento
-- las sigue poniendo el disparador evento_datos_del_servidor (010).
-- Si el evento no se puede crear, el error lleva el código RVE01 y la app
-- muestra "No se pudo completar la acción"; con cualquier otro error, el
-- mensaje de guardar ("No se pudo registrar la atención" o "...la medición").

create or replace function public.registrar_atencion(
  p_id_paciente bigint,
  p_id_sede bigint,
  p_tipo_atencion text,
  p_fecha_inicio timestamptz,
  p_fecha_fin timestamptz,
  p_destino_alta text,
  p_proposito text,
  p_id_sede_sesion bigint
)
returns bigint language plpgsql security definer set search_path = public as $$
declare
  v_id bigint;
begin
  -- Lo mismo que atencion_registrar_medico (012).
  if auth.uid() is null or coalesce(public.rol_actual(), '') <> 'medico' then
    raise exception 'Solo un médico registra atenciones' using errcode = '42501';
  end if;
  if not (
    p_proposito = 'urgencia'
    or (p_proposito = 'atencion_paciente'
        and public.tiene_relacion(p_id_paciente))
  ) then
    raise exception 'Sin relación con el paciente' using errcode = '42501';
  end if;

  begin
    insert into public.evento_auditoria
      (id_usuario, id_paciente, accion, tipo_recurso, resultado,
       proposito_uso, id_sede)
    values
      (auth.uid(), p_id_paciente, 'registrar', 'atencion', 'permitido',
       p_proposito, p_id_sede_sesion);
  exception when others then
    raise exception 'No se pudo crear el evento: %', sqlerrm
      using errcode = 'RVE01';
  end;

  insert into public.atencion
    (id_paciente, id_sede, id_usuario, tipo_atencion, fecha_inicio,
     fecha_fin, destino_alta, proposito)
  values
    (p_id_paciente, p_id_sede, auth.uid(), p_tipo_atencion, p_fecha_inicio,
     p_fecha_fin, p_destino_alta, p_proposito)
  returning id_atencion into v_id;
  return v_id;
end;
$$;

revoke all on function public.registrar_atencion(
  bigint, bigint, text, timestamptz, timestamptz, text, text, bigint
) from public, anon;
grant execute on function public.registrar_atencion(
  bigint, bigint, text, timestamptz, timestamptz, text, text, bigint
) to authenticated;

create or replace function public.registrar_medicion(
  p_id_indicador bigint,
  p_id_sede bigint,
  p_periodo_inicio date,
  p_valor numeric,
  p_id_sede_sesion bigint
)
returns bigint language plpgsql security definer set search_path = public as $$
declare
  v_fin date := (p_periodo_inicio + interval '1 month - 1 day')::date;
  v_id bigint;
begin
  -- Lo mismo que medicion_registrar (009): el administrativo, a su nombre y
  -- de un mes ya cerrado.
  if auth.uid() is null
     or coalesce(public.rol_actual(), '') <> 'administrativo' then
    raise exception 'Solo un administrativo registra mediciones'
      using errcode = '42501';
  end if;
  if v_fin >= current_date then
    raise exception 'El mes de la medición no ha terminado'
      using errcode = '42501';
  end if;

  begin
    insert into public.evento_auditoria
      (id_usuario, accion, tipo_recurso, resultado, id_sede)
    values
      (auth.uid(), 'registrar', 'medicion_indicador', 'permitido',
       p_id_sede_sesion);
  exception when others then
    raise exception 'No se pudo crear el evento: %', sqlerrm
      using errcode = 'RVE01';
  end;

  -- Una medición repetida falla con 23505 y deshace también el evento.
  insert into public.medicion_indicador
    (id_indicador, id_sede, periodo_inicio, periodo_fin, valor, registrada_por)
  values
    (p_id_indicador, p_id_sede, p_periodo_inicio, v_fin, p_valor, auth.uid())
  returning id_medicion into v_id;
  return v_id;
end;
$$;

revoke all on function public.registrar_medicion(
  bigint, bigint, date, numeric, bigint
) from public, anon;
grant execute on function public.registrar_medicion(
  bigint, bigint, date, numeric, bigint
) to authenticated;
