-- 013 · Rol Director: aprueba y gestiona las cuentas (F-24, RF-39, RF-40).
-- Requiere 001 a 012. Se pega completo en Supabase → SQL Editor → Run. Se
-- puede correr otra vez.

alter table public.rol drop constraint if exists rol_nombre_check;
alter table public.rol add constraint rol_nombre_check
  check (nombre in ('medico', 'administrativo', 'auditor', 'director'));

insert into public.rol (nombre) values ('director')
on conflict (nombre) do nothing;

-- Los cambios de una cuenta quedan en la auditoría como recurso *Usuario*,
-- con la cuenta que cambió. Sin llave foránea a propósito: una segunda
-- relación con usuario volvería ambigua la consulta de la auditoría.
alter table public.evento_auditoria
  add column if not exists id_usuario_afectado uuid;

do $$
declare
  restriccion text;
begin
  select conname into restriccion from pg_constraint
  where conrelid = 'public.evento_auditoria'::regclass
    and pg_get_constraintdef(oid) like '%tipo_recurso%';
  if restriccion is not null then
    execute format('alter table public.evento_auditoria drop constraint %I', restriccion);
  end if;
end $$;
alter table public.evento_auditoria
  add constraint evento_auditoria_tipo_recurso_check check (tipo_recurso in (
    'sesion', 'datos_basicos', 'historia_clinica', 'riesgo_reingreso',
    'atencion', 'medicion_indicador', 'pacientes_alta_reciente',
    'auditoria_accesos', 'usuario'
  ));

-- Guarda el rol, las sedes y si la cuenta está activa, y crea su evento en la
-- misma operación: si el evento no se puede crear, no se guarda nada (F-20).
-- Solo el director; no puede quitarse su rol ni desactivarse, y una cuenta
-- activa necesita al menos una sede.
create or replace function public.guardar_cuenta(
  p_id_usuario uuid,
  p_rol text,
  p_sedes bigint[],
  p_activo boolean,
  p_id_sede_sesion bigint
)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_rol bigint;
begin
  if coalesce(public.rol_actual(), '') <> 'director' then
    raise exception 'rol' using errcode = 'P0001';
  end if;
  if p_id_usuario = auth.uid() and (p_rol <> 'director' or not p_activo) then
    raise exception 'propia' using errcode = 'P0001';
  end if;
  if p_activo is null or p_rol is null
     or array_position(coalesce(p_sedes, '{}'), null) is not null then
    raise exception 'datos' using errcode = 'P0001';
  end if;
  if p_activo and coalesce(array_length(p_sedes, 1), 0) = 0 then
    raise exception 'sin_sedes' using errcode = 'P0001';
  end if;
  -- La sede del evento tiene que ser una de las del director (AD-05).
  if not exists (
    select 1 from public.usuario_sede
    where id_usuario = auth.uid() and id_sede = p_id_sede_sesion
  ) then
    raise exception 'sede' using errcode = 'P0001';
  end if;
  select id_rol into v_rol from public.rol where nombre = p_rol;
  if v_rol is null then
    raise exception 'rol_desconocido' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.usuario where id_usuario = p_id_usuario) then
    raise exception 'cuenta_desconocida' using errcode = 'P0001';
  end if;

  insert into public.evento_auditoria
    (id_usuario, accion, tipo_recurso, resultado, id_sede, id_usuario_afectado)
  values
    (auth.uid(), 'registrar', 'usuario', 'permitido', p_id_sede_sesion, p_id_usuario);

  update public.usuario set id_rol = v_rol, activo = p_activo
  where id_usuario = p_id_usuario;
  delete from public.usuario_sede
  where id_usuario = p_id_usuario and not (id_sede = any (coalesce(p_sedes, '{}')));
  insert into public.usuario_sede (id_usuario, id_sede)
  select p_id_usuario, s from unnest(coalesce(p_sedes, '{}')) as s
  on conflict do nothing;
end;
$$;

revoke all on function public.guardar_cuenta(uuid, text, bigint[], boolean, bigint)
  from public, anon;
grant execute on function public.guardar_cuenta(uuid, text, bigint[], boolean, bigint)
  to authenticated;

-- La cuenta de prueba del director (RNF-04): direccion@vitalys.co, con la
-- contraseña de las demás cuentas de prueba y la sede Cali Norte. La crea el
-- dueño del proyecto con este script, porque desde la app las cuentas nuevas
-- quedan pendientes.
do $$
declare
  v_id uuid;
begin
  select id into v_id from auth.users where email = 'direccion@vitalys.co';
  if v_id is null then
    v_id := gen_random_uuid();
    insert into auth.users
      (instance_id, id, aud, role, email, encrypted_password,
       email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
       created_at, updated_at, confirmation_token, recovery_token,
       email_change_token_new, email_change)
    values
      ('00000000-0000-0000-0000-000000000000', v_id, 'authenticated',
       'authenticated', 'direccion@vitalys.co',
       extensions.crypt('vitalys2026', extensions.gen_salt('bf')), now(),
       '{"provider": "email", "providers": ["email"]}',
       '{"nombre_completo": "Patricia Londoño Vélez"}', now(), now(), '', '',
       '', '');
    insert into auth.identities
      (provider_id, user_id, identity_data, provider, created_at, updated_at)
    values
      (v_id::text, v_id,
       jsonb_build_object('sub', v_id::text, 'email', 'direccion@vitalys.co',
                          'email_verified', true),
       'email', now(), now());
  end if;

  update public.usuario
  set id_rol = (select id_rol from public.rol where nombre = 'director'),
      nombre_completo = 'Patricia Londoño Vélez', activo = true
  where id_usuario = v_id;
  insert into public.usuario_sede (id_usuario, id_sede)
  select v_id, id_sede from public.sede where nombre = 'Clínica Vitalys Cali Norte'
  on conflict do nothing;
end $$;

-- El director no ve el tablero (F-24): los indicadores son de los otros tres
-- roles.
drop policy if exists indicador_leer on public.indicador;
create policy indicador_leer on public.indicador
  for select to authenticated
  using (public.rol_actual() in ('medico', 'administrativo', 'auditor'));
drop policy if exists indicador_tipo_sede_leer on public.indicador_tipo_sede;
create policy indicador_tipo_sede_leer on public.indicador_tipo_sede
  for select to authenticated
  using (public.rol_actual() in ('medico', 'administrativo', 'auditor'));
drop policy if exists medicion_leer on public.medicion_indicador;
create policy medicion_leer on public.medicion_indicador
  for select to authenticated
  using (public.rol_actual() in ('medico', 'administrativo', 'auditor'));

-- Un cambio de cuenta permitido solo lo crea guardar_cuenta: nadie lo inserta
-- a mano con la API. El rechazo de otro rol que intenta gestionar usuarios sí
-- lo inserta la app, sin cuenta afectada (F-18, F-20, F-24).
drop policy if exists auditoria_insertar_usuario on public.evento_auditoria;
create policy auditoria_insertar_usuario on public.evento_auditoria
  for insert to authenticated
  with check (
    id_usuario = auth.uid()
    and (tipo_recurso <> 'usuario' or resultado = 'denegado')
    and id_usuario_afectado is null
  );
