-- 003 · Fotos de perfil en Storage (plan P-02).
-- Se pega completo en Supabase → SQL Editor → Run. Se puede correr otra vez.
-- Corre después de 001: usa usuario.foto_ruta.

-- Bucket privado: solo JPG y PNG de hasta 2 MB.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fotos-perfil', 'fotos-perfil', false, 2097152,
        array['image/jpeg', 'image/png'])
on conflict (id) do update
  set public = false,
      file_size_limit = 2097152,
      allowed_mime_types = array['image/jpeg', 'image/png'];

-- Cada usuario solo toca los archivos de su carpeta: <id_usuario>/foto.<ext>.
drop policy if exists fotos_perfil_leer on storage.objects;
create policy fotos_perfil_leer on storage.objects
  for select to authenticated
  using (bucket_id = 'fotos-perfil'
         and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists fotos_perfil_subir on storage.objects;
create policy fotos_perfil_subir on storage.objects
  for insert to authenticated
  with check (bucket_id = 'fotos-perfil'
              and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists fotos_perfil_reemplazar on storage.objects;
create policy fotos_perfil_reemplazar on storage.objects
  for update to authenticated
  using (bucket_id = 'fotos-perfil'
         and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'fotos-perfil'
              and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists fotos_perfil_borrar on storage.objects;
create policy fotos_perfil_borrar on storage.objects
  for delete to authenticated
  using (bucket_id = 'fotos-perfil'
         and (storage.foldername(name))[1] = auth.uid()::text);
