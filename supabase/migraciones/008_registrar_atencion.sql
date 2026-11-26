-- 008 · El médico registra atenciones (F-04). Requiere los scripts 004 y 005.
-- Se pega completo en Supabase → SQL Editor → Run. Se puede correr otra vez.
-- Solo el médico, a su nombre y con *Atención del paciente* o *Urgencia*.
-- Una atención guardada no se edita ni se borra desde la app.

grant insert on public.atencion to authenticated;

drop policy if exists atencion_registrar_medico on public.atencion;
create policy atencion_registrar_medico on public.atencion
  for insert to authenticated
  with check (
    public.rol_actual() = 'medico'
    and id_usuario = auth.uid()
    and proposito in ('atencion_paciente', 'urgencia')
  );

select policyname, cmd from pg_policies
where schemaname = 'public' and tablename = 'atencion'
order by policyname;
