-- 005 · Lectura de pacientes según el rol (TS-18, AD-06).
-- Se pega completo en Supabase → SQL Editor → Run. Se puede correr otra vez.
-- Repite en la base la tabla de permisos de la app:
--   médico: pacientes, documentos, atenciones, riesgo y factores;
--   administrativo: pacientes, documentos y atenciones (datos básicos), sin riesgo;
--   auditor: ningún dato de pacientes.

create or replace function public.rol_actual()
returns text language sql stable security definer set search_path = public as $$
  select r.nombre from public.usuario u join public.rol r using (id_rol)
  where u.id_usuario = auth.uid() and u.activo;
$$;

drop policy if exists paciente_leer on public.paciente;
create policy paciente_leer on public.paciente
  for select to authenticated
  using (public.rol_actual() in ('medico', 'administrativo'));

drop policy if exists identificador_leer on public.identificador_paciente;
create policy identificador_leer on public.identificador_paciente
  for select to authenticated
  using (public.rol_actual() in ('medico', 'administrativo'));

drop policy if exists atencion_leer on public.atencion;
create policy atencion_leer on public.atencion
  for select to authenticated
  using (public.rol_actual() in ('medico', 'administrativo'));

drop policy if exists prediccion_leer on public.prediccion_reingreso;
create policy prediccion_leer on public.prediccion_reingreso
  for select to authenticated
  using (public.rol_actual() = 'medico');

drop policy if exists factor_leer on public.factor_riesgo;
create policy factor_leer on public.factor_riesgo
  for select to authenticated
  using (public.rol_actual() = 'medico');

select tablename, policyname, qual
from pg_policies
where schemaname = 'public'
  and tablename in ('paciente', 'identificador_paciente', 'atencion',
                    'prediccion_reingreso', 'factor_riesgo')
order by tablename;
