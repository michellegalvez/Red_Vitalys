-- 006 · El auditor puede saber a qué paciente se refiere cada evento (F-21).
-- Se pega completo en Supabase → SQL Editor → Run. Se puede correr otra vez.
-- El auditor no lee las tablas de pacientes (005). Esta función solo le da el
-- documento de los pacientes que aparecen en la auditoría.

create or replace function public.pacientes_de_auditoria()
returns table (id_paciente bigint, numero_identificacion text)
language sql stable security definer set search_path = public as $$
  select i.id_paciente, i.numero_identificacion
  from public.identificador_paciente i
  where i.es_principal
    and public.es_auditor()
    and exists (
      select 1 from public.evento_auditoria e
      where e.id_paciente = i.id_paciente
    );
$$;

revoke execute on function public.pacientes_de_auditoria() from public, anon;
grant execute on function public.pacientes_de_auditoria() to authenticated;

select proname from pg_proc where proname = 'pacientes_de_auditoria';
