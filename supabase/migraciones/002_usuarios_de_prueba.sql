-- 002 · Usuarios de prueba (plan P-01).
-- Antes hay que crear los 4 correos en Authentication → Users.
-- Después se pega completo en SQL Editor → Run. Se puede correr otra vez.

insert into public.usuario (id_usuario, id_rol, nombre_completo, correo)
select au.id, r.id_rol, v.nombre, v.correo
from (values
  ('camila.martinez@vitalys.co', 'Dra. Camila Martínez', 'medico'),
  ('andres.ruiz@vitalys.co', 'Andrés Felipe Ruiz', 'administrativo'),
  ('marcela.ospina@vitalys.co', 'Marcela Ospina', 'auditor'),
  ('tomas.herrera@vitalys.co', 'Dr. Tomás Herrera', 'medico')
) as v(correo, nombre, rol)
join auth.users au on au.email = v.correo
join public.rol r on r.nombre = v.rol
on conflict (id_usuario) do nothing;

-- Tomás no tiene sedes: es el caso de prueba "cuenta sin sedes asignadas".
insert into public.usuario_sede (id_usuario, id_sede)
select u.id_usuario, s.id_sede
from (values
  ('camila.martinez@vitalys.co', 'Clínica Vitalys Cali Norte'),
  ('camila.martinez@vitalys.co', 'Centro Ambulatorio Cali Sur'),
  ('andres.ruiz@vitalys.co', 'Clínica Vitalys Bogotá Usaquén'),
  ('marcela.ospina@vitalys.co', 'Clínica Vitalys Cali Norte')
) as v(correo, sede)
join public.usuario u on u.correo = v.correo
join public.sede s on s.nombre = v.sede
on conflict do nothing;

-- Debe devolver 4 usuarios y 4 asignaciones de sede.
select
  (select count(*) from public.usuario) as usuarios,
  (select count(*) from public.usuario_sede) as sedes_asignadas;
