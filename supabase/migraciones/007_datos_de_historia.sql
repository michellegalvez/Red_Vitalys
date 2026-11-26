-- 007 · Datos de la historia clínica (F-02, F-03): contacto, identificadores
-- por sistema y atenciones anteriores. Requiere el script 004.
-- Se pega completo en Supabase → SQL Editor → Run. Se puede correr otra vez.
-- Las atenciones anteriores van con *Seguimiento de reingreso*, que no da
-- relación; solo las de la Dra. Camila con Jorge son *Atención del paciente*.

do $$
declare
  medico_camila uuid;
  medico_tomas uuid;
  fila record;
  v_paciente bigint;
  v_sede text;
  v_alta timestamptz;
  v_inicio timestamptz;
  v_control text;
  v_sistema bigint;
begin
  select id_usuario into medico_camila from public.usuario
    where correo = 'camila.martinez@vitalys.co';
  select id_usuario into medico_tomas from public.usuario
    where correo = 'tomas.herrera@vitalys.co';

  insert into public.sistema_origen (nombre, tipo)
    values ('Laboratorio central', 'laboratorio')
    on conflict (nombre) do nothing;

  for fila in
    select * from (values
      ('79457654', 'Cra 24 # 5-60, Cali', '310 555 0101', 1, 78, 'Domicilio'),
      ('31285876', 'Cl 70 # 11-25, Bogotá', '311 555 0102', 2, 75, 'Domicilio'),
      ('72105531', 'Cra 43A # 1-50, Medellín', '312 555 0103', 3, 71, 'Traslado a otra institución'),
      ('80234310', 'Cl 84 # 52-10, Barranquilla', '313 555 0104', 4, 63, 'Domicilio'),
      ('43518902', 'Cra 33 # 48-12, Bucaramanga', '314 555 0105', 5, 67, 'Atención domiciliaria'),
      ('63451204', 'Cl 5 # 38-40, Cali', '315 555 0106', 6, 58, 'Domicilio'),
      ('1023456778', 'Cra 15 # 93-20, Bogotá', '316 555 0107', 7, 14, 'Traslado a otra institución'),
      ('1107052145', 'Cl 10 # 42-18, Cali', '317 555 0108', 8, 3, 'Domicilio'),
      ('29874512', 'Cra 7 # 60-35, Bogotá', '318 555 0109', 9, 81, 'Atención domiciliaria'),
      ('70589234', 'Cl 9 Sur # 43-15, Envigado', '319 555 0110', 10, 69, 'Domicilio'),
      ('43217655', 'Cra 52 # 76-30, Barranquilla', '320 555 0111', 11, 72, 'Traslado a otra institución'),
      ('1098765432', 'Cl 36 # 27-44, Bucaramanga', '321 555 0112', 12, 45, 'Domicilio'),
      ('1144092211', 'Cra 80 # 33-12, Medellín', '322 555 0113', 13, 29, 'Atención domiciliaria')
    ) as t(documento, direccion, telefono, numero, edad, destino)
  loop
    select i.id_paciente into v_paciente from public.identificador_paciente i
      where i.numero_identificacion = fila.documento and i.es_principal;
    continue when v_paciente is null;

    update public.paciente
      set direccion = fila.direccion, telefono = fila.telefono,
        fecha_nacimiento = make_date(2026 - fila.edad, 6, 2)
      where id_paciente = v_paciente;

    -- La atención del alta es la que tiene la predicción.
    select s.nombre_corto, a.fecha_inicio, a.fecha_fin
      into v_sede, v_inicio, v_alta
      from public.atencion a
      join public.sede s using (id_sede)
      join public.prediccion_reingreso p using (id_atencion)
      where a.id_paciente = v_paciente
      order by a.fecha_fin desc limit 1;

    update public.atencion set destino_alta = fila.destino
      where id_paciente = v_paciente and fecha_fin = v_alta;
    update public.prediccion_reingreso p
      set fecha_prediccion = (v_alta at time zone 'America/Bogota')::date + 7
      from public.atencion a
      where a.id_atencion = p.id_atencion and a.id_paciente = v_paciente;

    -- Identificadores en otros sistemas.
    insert into public.sistema_origen (nombre, tipo)
      values ('HCE ' || v_sede, 'historia_clinica')
      on conflict (nombre) do nothing;
    for v_sistema in
      select id_sistema from public.sistema_origen
      where nombre in ('HCE ' || v_sede, 'Laboratorio central')
      order by nombre
    loop
      if not exists (
        select 1 from public.identificador_paciente
        where id_paciente = v_paciente and id_sistema = v_sistema
          and not es_principal
      ) then
        insert into public.identificador_paciente
          (id_paciente, id_sistema, tipo_documento, numero_identificacion)
        select v_paciente, v_sistema, i.tipo_documento,
          case when so.nombre = 'Laboratorio central'
            then 'LAB-' || lpad(fila.numero::text, 4, '0') || fila.edad
            else 'HCE-' || right(fila.documento, 6) end
        from public.identificador_paciente i, public.sistema_origen so
        where i.id_paciente = v_paciente and i.es_principal
          and so.id_sistema = v_sistema;
      end if;
    end loop;

    -- Atenciones anteriores, en otra sede de la red.
    continue when (
      select count(*) from public.atencion where id_paciente = v_paciente
    ) > 1;

    if fila.numero = 1 then
      insert into public.atencion
        (id_paciente, id_sede, id_usuario, tipo_atencion, fecha_inicio,
         fecha_fin, destino_alta, proposito)
      select v_paciente, s.id_sede, medico_camila, 'urgencias',
        ((v.dia + time '08:00') at time zone 'America/Bogota'),
        ((v.dia + time '12:00') at time zone 'America/Bogota'),
        'Domicilio', 'atencion_paciente'
      from (values
        (date '2026-05-02', 'Bogotá Usaquén'),
        (date '2026-01-18', 'Amb. Cali Sur')
      ) as v(dia, sede)
      join public.sede s on s.nombre_corto = v.sede;
    else
      v_control := case when v_sede = 'Amb. Cali Sur'
        then 'Amb. Envigado' else 'Amb. Cali Sur' end;
      insert into public.atencion
        (id_paciente, id_sede, id_usuario, tipo_atencion, fecha_inicio,
         fecha_fin, destino_alta, proposito)
      select v_paciente, s.id_sede,
        case when fila.numero % 3 = 0 then medico_camila else medico_tomas end,
        'consulta_externa', v_inicio - interval '75 days',
        v_inicio - interval '75 days' + interval '1 hour',
        'Domicilio', 'seguimiento_reingreso'
      from public.sede s where s.nombre_corto = v_control;
    end if;
  end loop;
end $$;

-- Debe devolver 13 con contacto, 39 identificadores y 27 atenciones.
select
  (select count(*) from public.paciente where telefono is not null) as con_contacto,
  (select count(*) from public.identificador_paciente) as identificadores,
  (select count(*) from public.atencion) as atenciones;
