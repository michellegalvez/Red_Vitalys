#!/usr/bin/env bash
# Comprueba que el PRD, los requisitos, la spine y las specs sean coherentes entre sí.
#
# Uso:    bash docs/verificar.sh
# Salida: código 0 si todo pasa, 1 si algo falla. No modifica ningún archivo.
#
# Qué revisa: versiones e índice, dependencias, requisitos citados, criterios,
# estructura y formato de cada spec, palabras vagas, tecnología y posiciones en
# pantalla, que una misma regla diga lo mismo en todos los documentos donde
# aparece, que las tablas de permisos coincidan y que el reporte esté al día.
# Lo que NO puede revisar (si una regla nueva contradice a otra) se revisa
# leyendo; cuando aparezca una regla compartida nueva, agrégala a la sección
# "Reglas compartidas" de este archivo.

cd "$(dirname "$0")" || exit 2
fallos=0
fallo() { echo "  FALLA: $*"; fallos=$((fallos + 1)); }
titulo() { echo "== $*"; }

specs=(specs/F-[0-9]*.md)
docs3=(prd.md requisitos.md architectural_spine.md)
todos=("${specs[@]}" "${docs3[@]}" specs/README.md specs/reporte.md)

vers() { grep -m1 '^version:' "$1" | cut -d' ' -f2; }
ultimo_hist() { grep -E '^- [0-9]+\.[0-9]+\.[0-9]+ ·' "$1" | tail -1 | sed -E 's/^- ([0-9.]+) ·.*/\1/'; }
sin_historial() { awk '/^## Historial/{exit} {print}' "$1"; }
id_de() { basename "$1" | sed -E 's/^(F-[0-9]+)-.*/\1/'; }

# ---------------------------------------------------------------- versiones
titulo "Versiones"
for f in "${specs[@]}" "${docs3[@]}"; do
  v=$(vers "$f"); u=$(ultimo_hist "$f")
  [ "$v" = "$u" ] || fallo "$f: la versión es $v pero el historial termina en $u"
  while read -r malo; do
    fallo "$f: en el historial $malo"
  done < <(awk '/^- [0-9]+\.[0-9]+\.[0-9]+ ·/ {v=$2; split(v,p,"."); k=p[1]*1000000+p[2]*1000+p[3]; if (k<=pk) print "la versión " v " se repite o retrocede"; pk=k}' "$f")
done
for f in "${specs[@]}"; do
  b=$(basename "$f"); v=$(vers "$f")
  iv=$(grep -F "($b)" specs/README.md | sed -E 's/.*\) · v([0-9.]+) ·.*/\1/')
  [ -n "$iv" ] || { fallo "$b no está en el índice"; continue; }
  [ "$v" = "$iv" ] || fallo "$b: el archivo dice $v y el índice $iv"
done
while read -r l; do
  [ -f "specs/$l" ] || fallo "el índice enlaza a specs/$l, que no existe"
done < <(grep -oE '\(F-[0-9]+[^)]*\.md\)' specs/README.md | tr -d '()')
pv=$(vers prd.md); rv=$(vers requisitos.md); sv=$(vers architectural_spine.md)
grep -q "^basado_en: prd $pv\$" requisitos.md || fallo "requisitos.md no está basado en el prd $pv"
grep -q "^basado_en: \[prd $pv, requisitos $rv\]\$" architectural_spine.md \
  || fallo "architectural_spine.md no está basada en prd $pv y requisitos $rv"

# ------------------------------------------------- dependencias y requisitos
titulo "Dependencias y requisitos citados"
aristas=""
for f in "${specs[@]}"; do
  id=$(id_de "$f")
  for d in $(grep -m1 '^depende_de:' "$f" | grep -oE 'F-[0-9]+'); do
    ls specs/$d-*.md >/dev/null 2>&1 || fallo "$id depende de $d, que no existe"
    [ "$d" = "$id" ] && fallo "$id depende de sí misma"
    aristas="$aristas$d $id"$'\n'
  done
  citados=$(grep -m1 '^requisitos:' "$f" | grep -oE 'RN?F-[0-9]+')
  [ -n "$citados" ] || fallo "$id no cita ningún requisito"
  for r in $citados; do
    grep -qE "^- \*\*$r\*\*" requisitos.md || fallo "$id cita $r, que no existe en requisitos.md"
  done
done
if command -v tsort >/dev/null 2>&1 && [ -n "$aristas" ]; then
  printf '%s' "$aristas" | tsort 2>&1 >/dev/null | grep -qi loop && fallo "las dependencias entre specs tienen un ciclo"
fi
for r in $(grep -oE '^- \*\*RF-[0-9]+\*\*' requisitos.md | grep -oE 'RF-[0-9]+'); do
  grep -lE "^requisitos:.*\b$r\b" "${specs[@]}" >/dev/null || fallo "$r no tiene spec"
done
nrf=$(grep -cE '^- \*\*RF-[0-9]+\*\*' requisitos.md)
maxrf=$(grep -oE '^- \*\*RF-[0-9]+\*\*' requisitos.md | grep -oE '[0-9]+' | sort -n | tail -1)
grep -q "cubren los $nrf requisitos funcionales (RF-01 a RF-$maxrf)" specs/README.md \
  || fallo "el encabezado del índice no dice $nrf requisitos funcionales (RF-01 a RF-$maxrf)"

# ------------------------------------------------------------------ criterios
titulo "Criterios de aceptación"
total_ca=0
for f in "${specs[@]}"; do
  id=$(id_de "$f")
  nums=$(grep -oE '^- \*\*CA-[0-9]+\*\*' "$f" | grep -oE '[0-9]+' | sort -n)
  [ -n "$nums" ] || { fallo "$id no tiene criterios"; continue; }
  d=$(echo "$nums" | uniq -d); [ -z "$d" ] || fallo "$id tiene criterios repetidos: $d"
  max=$(echo "$nums" | tail -1); cnt=$(echo "$nums" | wc -l | tr -d ' ')
  [ "$max" = "$cnt" ] || fallo "$id: el último criterio es CA-$max pero hay $cnt"
  # Cada criterio se revisa dentro de bash, sin lanzar procesos: así el script es rápido.
  while IFS= read -r linea; do
    [[ "$linea" == *"(movido a"* ]] && continue
    total_ca=$((total_ca + 1))
    [[ "$linea" =~ ^-\ \*\*CA-([0-9]+)\*\* ]]; n="${BASH_REMATCH[1]}"
    [[ "$linea" =~ \*\*\ Dad[oa]s?\  ]] || fallo "$id CA-$n no empieza con Dado"
    [[ "$linea" =~ \ cuando\ .*\ entonces[\ ,] ]] || fallo "$id CA-$n no tiene 'cuando' antes de 'entonces'"
  done < <(grep -E '^- \*\*CA-[0-9]+\*\*' "$f")
done

# ----------------------------------------------------------------- estructura
titulo "Estructura de cada spec"
secciones=("## Objetivo" "## Flujo principal" "## Flujos alternos" "## Reglas" "## Estados" "## Datos" "## Criterios de aceptación" "## Fuera de alcance" "## Preguntas abiertas" "## Historial")
total_q=0
for f in "${specs[@]}"; do
  id=$(id_de "$f"); previo=0
  for s in "${secciones[@]}"; do
    n=$(grep -n "^$s\$" "$f" | head -1 | cut -d: -f1)
    if [ -z "$n" ]; then fallo "$id no tiene '$s'"
    elif [ "$n" -lt "$previo" ]; then fallo "$id tiene '$s' fuera de orden"
    else previo=$n; fi
  done
  q=$(awk '/^## Preguntas abiertas/{p=1;next} /^## /{p=0} p && /^- /{c++} END{print c+0}' "$f")
  hay=$(awk '/^## Preguntas abiertas/{p=1;next} /^## /{p=0} p && NF{c++} END{print c+0}' "$f")
  [ "$hay" -gt 0 ] || fallo "$id tiene la sección de preguntas abiertas vacía (escribe 'Ninguna.')"
  total_q=$((total_q + q))
  pasos=$(awk '/^## Flujo principal/{p=1;next} /^## /{p=0} p && /^[0-9]+\. /{c++} END{print c+0}' "$f")
  ultimo=$(awk '/^## Flujo principal/{p=1;next} /^## /{p=0} p && /^[0-9]+\. /{sub(/\..*/,""); l=$0} END{print l+0}' "$f")
  [ "$pasos" = "$ultimo" ] || fallo "$id: el flujo principal tiene $pasos pasos pero llega al número $ultimo"
  esperado=1
  while read -r n; do
    [ "$n" = "$esperado" ] || { fallo "$id: el flujo principal salta del paso $((esperado - 1)) al $n"; break; }
    esperado=$((esperado + 1))
  done < <(awk '/^## Flujo principal/{p=1;next} /^## /{p=0} p && /^[0-9]+\. /{sub(/\..*/,""); print}' "$f")
  grep -nE '^[0-9]+\. .*[a-záéíóú).”"][0-9]+\. [A-ZÁÉÍÓÚ]' "$f" >/dev/null && fallo "$id tiene dos pasos pegados en una línea"
done

# -------------------------------------------------------------------- formato
titulo "Formato"
for f in "${todos[@]}"; do
  while read -r n; do
    fallo "$f:$n: falta una línea en blanco antes del encabezado"
  done < <(awk 'prev!="" && /^#{1,3} / {print NR} {prev=$0}' "$f")
  malos=$(awk '/^- \*\*CA-|^- [0-9]+\.[0-9]+\.[0-9]+ ·|^[0-9]+\. / {if (blank && inlist) print NR; inlist=1; blank=0; next} /^$/ {blank=1; next} {inlist=0; blank=0}' "$f")
  for n in $malos; do fallo "$f:$n: una línea en blanco parte la lista"; done
  awk '/^$/{b++; if(b==2) print "x"} !/^$/{b=0}' "$f" | grep -q x && fallo "$f tiene dos líneas en blanco seguidas"
  [ -z "$(tail -c1 "$f")" ] || fallo "$f no termina en un salto de línea"
  grep -q $'\r' "$f" && fallo "$f tiene saltos de línea de Windows (CRLF)"
done

# ------------------------------------------------------------------- palabras
titulo "Palabras que no van en una spec"
for f in "${specs[@]}"; do
  id=$(id_de "$f"); cuerpo=$(sin_historial "$f")
  v=$(echo "$cuerpo" | grep -niwE 'fácil|fácilmente|rápido|rápida|rápidamente|intuitivo|intuitiva|amigable|moderno|moderna|adecuado|adecuada|algunos|algunas|varios|varias|etc\.' | head -3)
  [ -z "$v" ] || fallo "$id usa palabras vagas: $(echo "$v" | tr '\n' ' ' | cut -c1-120)"
  t=$(echo "$cuerpo" | grep -niE 'Supabase|Flutter|widget|setState|\bSQL\b|PostgREST|servidor|servicio de' | head -3)
  [ -z "$t" ] || fallo "$id nombra tecnología: $(echo "$t" | tr '\n' ' ' | cut -c1-120)"
  p=$(echo "$cuerpo" | grep -niwE 'debajo|encima|arriba|abajo|a la derecha|a la izquierda|junto a|al lado' | head -3)
  [ -z "$p" ] || fallo "$id nombra una posición en la pantalla: $(echo "$p" | tr '\n' ' ' | cut -c1-120)"
done

# ---------------------------------------------------------- reglas compartidas
# regla "descripción" "archivo::patrón" ...   El patrón debe aparecer en cada archivo.
titulo "Reglas compartidas entre documentos"
regla() {
  local desc="$1"; shift
  local par archivo patron f
  for par in "$@"; do
    archivo="${par%%::*}"; patron="${par#*::}"
    for f in $archivo; do
      [ -f "$f" ] || { fallo "[$desc] no existe $archivo"; continue; }
      grep -qE "$patron" "$f" || fallo "[$desc] no aparece en $f"
    done
  done
}
regla "una atención con Urgencia no da relación" \
  'prd.md::\*Urgencia\* no (le )?(se la )?da' 'requisitos.md::\*Urgencia\* no (le )?(se la )?da' \
  'specs/F-04-*.md::\*Urgencia\* no (le )?(se la )?da' 'specs/F-05-*.md::\*Urgencia\* no (le )?(se la )?da' \
  'specs/F-17-*.md::\*Urgencia\* no (le )?(se la )?da'
regla "el propósito se declara al abrir la lista de pacientes con alta reciente" \
  'prd.md::al abrir la lista de pacientes con alta reciente' 'requisitos.md::abrir la lista de pacientes con alta reciente' \
  'architectural_spine.md::al abrir la lista de pacientes con alta reciente' \
  'specs/F-06-*.md::declarar el propósito' 'specs/F-16-*.md::También se declara al abrir la lista'
regla "el propósito se declara al registrar una atención" \
  'prd.md::al registrar una atención' 'requisitos.md::Atención del paciente\* si tiene relación' \
  'architectural_spine.md::al registrar una atención' 'specs/F-04-*.md::declara el propósito' \
  'specs/F-16-*.md::También se declara al registrar una atención' 'specs/F-17-*.md::registro de una atención'
regla "el inicio de sesión se bloquea 15 minutos por dispositivo" \
  'prd.md::en ese dispositivo' 'requisitos.md::en un dispositivo' 'architectural_spine.md::en el dispositivo' \
  'specs/F-13-*.md::en el dispositivo' 'specs/F-14-*.md::en el mismo dispositivo' \
  'specs/F-20-*.md::bloqueo del inicio de sesión'
regla "la sesión se cierra a los 15 minutos sin uso" \
  'prd.md::15 minutos' 'requisitos.md::15 minutos sin uso' 'architectural_spine.md::15 minutos de inactividad' \
  'specs/F-15-*.md::15 minutos'
regla "el inicio de sesión fallido no tiene sede y lleva correo e IP" \
  'prd.md::inicio de sesión fallido' 'requisitos.md::excepto en un inicio de sesión fallido' \
  'architectural_spine.md::inicio de sesión fallido' 'specs/F-13-*.md::correo escrito y la IP' \
  'specs/F-20-*.md::sin sede' 'specs/F-21-*.md::la sede queda vacía'
regla "el evento se crea antes de la acción y, si falla, la acción no se hace" \
  'requisitos.md::Si el evento no se puede crear, la acción no se hace' \
  'architectural_spine.md::Si el evento no se puede escribir, la acción no se ejecuta' \
  'specs/F-20-*.md::El evento se crea antes de ejecutar la acción' \
  'specs/F-02-*.md::Si no puede crearlo' 'specs/F-03-*.md::Si no puede crearlo' 'specs/F-04-*.md::Si no puede crearlo' \
  'specs/F-06-*.md::Si no puede crearlo' 'specs/F-07-*.md::Si no puede crearlo' 'specs/F-12-*.md::Si no puede crearlo' \
  'specs/F-13-*.md::Si no puede crearlo' 'specs/F-17-*.md::Si no puede crearlo' \
  'specs/F-05-*.md::crea el evento \*Permitido\* y, si pudo crearlo' 'specs/F-18-*.md::y, si pudo crearlo, la ejecuta'
regla "la búsqueda de pacientes no se registra" \
  'prd.md::La búsqueda de pacientes, que solo muestra nombre y documento, no se registra' \
  'requisitos.md::La búsqueda de pacientes, que solo muestra nombre y documento, no se registra' \
  'architectural_spine.md::La búsqueda de pacientes, que solo muestra nombre y documento, no se audita' \
  'specs/F-01-*.md::no crea un evento de acceso' 'specs/F-20-*.md::búsqueda de pacientes'
regla "la fecha de hoy de los datos simulados es el 6 de noviembre de 2026" \
  'requisitos.md::6 de noviembre de 2026' 'specs/F-08-*.md::6 de noviembre de 2026' 'specs/F-12-*.md::6 de noviembre de 2026'
regla "las plataformas son Chrome, Edge y Android 10" \
  'requisitos.md::Chrome y Edge' 'requisitos.md::Android 10' 'specs/F-19-*.md::Chrome y Edge' 'specs/F-19-*.md::Android 10'
regla "la medición admite hasta 1 decimal" \
  'requisitos.md::más de 1 decimal' 'architectural_spine.md::hasta 1 decimal' 'specs/F-12-*.md::hasta 1 decimal'
regla "los rangos de las mediciones" \
  'requisitos.md::0 a 1\.440' 'specs/F-12-*.md::0 a 1\.440'
regla "cada rol tiene una pantalla inicial" \
  'prd.md::pantalla inicial del rol' 'requisitos.md::RF-37' 'specs/F-13-*.md::pantalla inicial de su rol'
regla "el administrativo solo declara Revisión de calidad" \
  'prd.md::El administrativo solo \*Revisión de calidad\*' 'requisitos.md::solo \*Revisión de calidad\*' \
  'specs/F-16-*.md::El administrativo solo' 'specs/F-18-*.md::el administrativo solo' 'specs/F-22-*.md::el administrativo solo'
regla "la alerta de riesgo es de 70 o más" \
  'prd.md::70 o más' 'requisitos.md::70 o más' 'architectural_spine.md::umbral de alerta \(70\)' 'specs/F-06-*.md::70 o más'
regla "el médico tiene relación por una atención con Atención del paciente o por un alta reciente" \
  'prd.md::declarando \*Atención del paciente\* o lo dieron de alta' 'requisitos.md::declarando \*Atención del paciente\* o si el paciente fue dado de alta' \
  'specs/F-05-*.md::Registró al menos una atención suya declarando'
regla "AGENTS.md describe lo que el usuario puede hacer" \
  '../AGENTS.md::Iniciar sesión' '../AGENTS.md::Registrar una atención' '../AGENTS.md::Registrar las mediciones'
regla "la red tiene una cadena de laboratorios clínicos propia" \
  '../AGENTS.md::cadena de laboratorios' 'prd.md::cadena de laboratorios clínicos propia' \
  'requisitos.md::al menos 2 laboratorios clínicos'
regla "la historia unificada muestra el riesgo de reingreso y se abre desde la búsqueda o la lista" \
  'prd.md::Abrir la historia unificada de un paciente, desde la búsqueda o desde la lista de pacientes con alta reciente' \
  'specs/F-07-*.md::lista de pacientes con alta reciente' 'specs/F-02-*.md::El riesgo de reingreso y su explicación'
regla "los laboratorios no tienen indicadores" \
  'prd.md::Los laboratorios no tienen indicadores' 'requisitos.md::Los laboratorios no tienen indicadores' \
  'specs/F-08-*.md::Los laboratorios no aparecen' 'specs/F-12-*.md::Los laboratorios no tienen indicadores'

# ------------------------------------------------------------ frases retiradas
# Redacciones que ya se corrigieron y no deben volver. Se ignoran las líneas del historial.
titulo "Frases retiradas"
retirada() {
  local patron="$1" motivo="$2" linea
  while IFS= read -r linea; do
    [[ "$linea" =~ :[0-9]+:-\ [0-9]+\.[0-9]+\.[0-9]+\ · ]] && continue
    fallo "${linea%%:*} vuelve a decir '$patron' ($motivo)"
  done < <(grep -nE "$patron" "${docs3[@]}" "${specs[@]}" ../AGENTS.md /dev/null)
}
retirada 'laboratorio central|centros ambulatorios y un laboratorio' "la red tiene una cadena de laboratorios"
retirada '[Cc]uenta bloqueada|bloquea la cuenta|bloqueo de la cuenta' "el bloqueo es del inicio de sesión en el dispositivo"
retirada 'por defecto \*Seguimiento de reingreso\*' "no hay propósito elegido por defecto"
retirada 'Registrar una atención le da al médico relación con ese paciente \(F-05\)\.$' "una atención con Urgencia no da relación"

# ----------------------------------------------------------- tablas coherentes
titulo "Tabla de permisos"
# tabla_permisos lee un texto por la entrada estándar y devuelve las filas de la
# tabla de permisos, con "Sí"/"No" escritos como "Permitido"/"No incluido".
tabla_permisos() {
  awk -F'|' '
    NF>4 { for (i=2;i<=5;i++) { gsub(/^ +| +$/, "", $i) }
           if ($2=="Acción" || $2 ~ /^-+$/) next
           c3=$3; c4=$4; c5=$5
           sub(/^Sí$/,"Permitido",c3); sub(/^No$/,"No incluido",c3)
           sub(/^Sí$/,"Permitido",c4); sub(/^No$/,"No incluido",c4)
           sub(/^Sí$/,"Permitido",c5); sub(/^No$/,"No incluido",c5)
           if (c3 ~ /^(Permitido|No incluido)$/) print $2 "|" c3 "|" c4 "|" c5 }' | sort
}
base=$(awk '/^### Tabla de permisos/{p=1;next} /^### /{p=0} p' requisitos.md | tabla_permisos)
[ -n "$base" ] || fallo "no se pudo leer la tabla de permisos de requisitos.md"
for f in specs/F-18-*.md specs/F-22-*.md; do
  [ "$(tabla_permisos < "$f")" = "$base" ] || fallo "la tabla de permisos de $f no coincide con la de requisitos.md"
done

# --------------------------------------------------------------- reporte al día
titulo "Reporte al día"
grep -q "Revisado: prd $pv · requisitos $rv · spine $sv" specs/reporte.md \
  || fallo "reporte.md dice otras versiones del PRD, los requisitos o la spine (actuales: $pv, $rv, $sv)"
for f in "${specs[@]}"; do
  id=$(id_de "$f"); v=$(vers "$f")
  grep -q "$id $v" specs/reporte.md || fallo "reporte.md no tiene la versión actual de $id ($v)"
done
grep -q "$total_ca" specs/reporte.md || fallo "reporte.md no dice que hay $total_ca criterios"
grep -qE "Preguntas abiertas:\*\* $total_q\." specs/reporte.md || fallo "reporte.md no dice que hay $total_q preguntas abiertas"

# ------------------------------------------------------------------- resumen
echo
echo "Specs: ${#specs[@]} · Requisitos funcionales: $nrf · Criterios: $total_ca · Preguntas abiertas: $total_q"
if [ "$fallos" -eq 0 ]; then
  echo "OK: sin fallas."
  exit 0
fi
echo "$fallos fallas."
exit 1
