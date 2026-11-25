-- 004 · Trigger para registro automático de usuarios y sincronización con Auth (plan P-03).
-- Se corre en Supabase → SQL Editor → Run. Es idempotente y seguro de re-ejecutar.

-- Función ejecutada cada vez que se crea un usuario en auth.users
create or replace function public.manejar_nuevo_usuario()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  id_rol_medico bigint;
  nombre_defecto text;
begin
  -- Obtener el id del rol 'medico'
  select id_rol into id_rol_medico from public.rol where nombre = 'medico' limit 1;

  -- Determinar el nombre a partir de metadatos o prefijo del correo
  nombre_defecto := coalesce(
    nullif(trim(new.raw_user_meta_data->>'nombre_completo'), ''),
    nullif(trim(new.raw_user_meta_data->>'name'), ''),
    split_part(new.email, '@', 1)
  );

  -- Insertar en public.usuario como medico y sin sedes asignadas (F-13 A3)
  insert into public.usuario (
    id_usuario,
    id_rol,
    nombre_completo,
    correo,
    activo
  ) values (
    new.id,
    id_rol_medico,
    nombre_defecto,
    new.email,
    true
  )
  on conflict (id_usuario) do update
    set correo = excluded.correo,
        nombre_completo = coalesce(public.usuario.nombre_completo, excluded.nombre_completo);

  return new;
end;
$$;

-- Trigger sobre auth.users al registrar un nuevo usuario
drop trigger if exists tr_crear_usuario_nuevo on auth.users;
create trigger tr_crear_usuario_nuevo
  after insert on auth.users
  for each row execute function public.manejar_nuevo_usuario();

-- Asegurar que las políticas de lectura permitan al usuario autenticado leer su propio perfil y sus sedes
drop policy if exists usuario_leer_propio on public.usuario;
create policy usuario_leer_propio on public.usuario
  for select to authenticated
  using (id_usuario = auth.uid());

drop policy if exists usuario_sede_leer_propio on public.usuario_sede;
create policy usuario_sede_leer_propio on public.usuario_sede
  for select to authenticated
  using (id_usuario = auth.uid());
