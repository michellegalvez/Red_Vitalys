-- 010 · Seguridad: quién lee los usuarios y qué datos del evento pone la base.
-- Se pega completo en Supabase → SQL Editor → Run. Se puede correr otra vez.
-- Corre después de 005 (usa public.rol_actual()).

-- Una cuenta sin rol activo o sin sedes ya no lee los nombres ni los correos
-- de los demás. Cada uno sigue leyendo su propio perfil y sus sedes con
-- usuario_leer_propio y usuario_sede_leer_propio, así que la cuenta sin sedes
-- sigue viendo el aviso de F-13 A3.
drop policy if exists usuario_leer on public.usuario;
create policy usuario_leer on public.usuario
  for select to authenticated using (public.rol_actual() is not null);

drop policy if exists usuario_sede_leer on public.usuario_sede;
create policy usuario_sede_leer on public.usuario_sede
  for select to authenticated using (public.rol_actual() is not null);

drop policy if exists usuario_leer_propio on public.usuario;
create policy usuario_leer_propio on public.usuario
  for select to authenticated using (id_usuario = auth.uid());

drop policy if exists usuario_sede_leer_propio on public.usuario_sede;
create policy usuario_sede_leer_propio on public.usuario_sede
  for select to authenticated using (id_usuario = auth.uid());

-- La hora del evento y la IP las pone la base, no la app (AD-15). La IP solo
-- se guarda en un inicio de sesión fallido (F-20, F-21).
create or replace function public.evento_datos_del_servidor()
returns trigger language plpgsql as $$
begin
  new.fecha_hora_evento := now();
  if new.accion = 'ingresar' and new.resultado = 'denegado' then
    new.ip := nullif(
      trim(split_part(
        coalesce(current_setting('request.headers', true)::json ->> 'x-forwarded-for', ''),
        ',', 1)),
      '')::inet;
  else
    new.ip := null;
  end if;
  return new;
end;
$$;

drop trigger if exists evento_datos_del_servidor on public.evento_auditoria;
create trigger evento_datos_del_servidor
  before insert on public.evento_auditoria
  for each row execute function public.evento_datos_del_servidor();
