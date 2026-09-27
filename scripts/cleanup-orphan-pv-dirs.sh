#!/usr/bin/env bash
#
# Ruimt verweesde local-path directories op de k3s node op.
#
# Bij reclaimPolicy "Retain" verwijdert k3s de data directory niet wanneer een
# PersistentVolume wordt verwijderd. Dit script vergelijkt de directories in de
# storage root met de PersistentVolumes die nog in het cluster bestaan en
# verwijdert alleen de directories waarvan geen PV meer bestaat.
#
# Draai dit script op de node zelf (de directories zijn niet zichtbaar vanaf een
# externe machine).
#
# Gebruik:
#   ./cleanup-orphan-pv-dirs.sh            # dry-run, toont wat verwijderd zou worden
#   ./cleanup-orphan-pv-dirs.sh --delete   # verwijdert de verweesde directories

set -euo pipefail

STORAGE_ROOT="${STORAGE_ROOT:-/var/lib/rancher/k3s/storage}"
DELETE=false

for arg in "$@"; do
  case "$arg" in
    --delete) DELETE=true ;;
    -h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Onbekende optie: $arg" >&2; exit 2 ;;
  esac
done

if [[ ! -d "$STORAGE_ROOT" ]]; then
  echo "Storage root niet gevonden: $STORAGE_ROOT" >&2
  echo "Draai dit script op de k3s node, of zet STORAGE_ROOT." >&2
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl niet gevonden op deze machine." >&2
  exit 1
fi

# Bestaande PV-namen ophalen. Faalt de API-call, dan stoppen we: zonder
# betrouwbare lijst zouden we actieve data kunnen verwijderen.
if ! pv_list="$(kubectl get pv -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)"; then
  echo "Kan de PersistentVolumes niet opvragen. Controleer je kubeconfig." >&2
  exit 1
fi

declare -A existing_pvs=()
for pv in $pv_list; do
  existing_pvs["$pv"]=1
done

# Released PV's houden hun directory bezet zonder in gebruik te zijn. Zolang het
# PV-object bestaat ziet dit script de directory niet als verweesd.
released_pvs="$(kubectl get pv -o jsonpath='{range .items[?(@.status.phase=="Released")]}{.metadata.name}{"\n"}{end}' 2>/dev/null || true)"

echo "Storage root : $STORAGE_ROOT"
echo "Bekende PV's : ${#existing_pvs[@]}"
echo

orphans=()
for dir in "$STORAGE_ROOT"/*/; do
  [[ -d "$dir" ]] || continue
  name="$(basename "$dir")"

  # Directorynaam heeft de vorm <pv-naam>_<namespace>_<pvc-naam>
  pv_name="${name%%_*}"

  if [[ -n "${existing_pvs[$pv_name]:-}" ]]; then
    printf '  in gebruik : %s\n' "$name"
  else
    printf '  VERWEESD   : %s (%s)\n' "$name" "$(du -sh "$dir" 2>/dev/null | cut -f1)"
    orphans+=("$dir")
  fi
done

echo
if [[ -n "$released_pvs" ]]; then
  echo "Let op: de volgende PV's hebben status Released. Hun directory telt pas"
  echo "als verweesd nadat het PV-object is verwijderd:"
  while IFS= read -r pv; do
    [[ -n "$pv" ]] && printf '  kubectl delete pv %s\n' "$pv"
  done <<< "$released_pvs"
  echo
fi

if [[ ${#orphans[@]} -eq 0 ]]; then
  echo "Geen verweesde directories gevonden."
  exit 0
fi

if [[ "$DELETE" != true ]]; then
  echo "${#orphans[@]} verweesde director$([[ ${#orphans[@]} -eq 1 ]] && echo 'y' || echo 'ies') gevonden."
  echo "Dit was een dry-run. Draai met --delete om ze daadwerkelijk te verwijderen."
  exit 0
fi

echo "Let op: dit verwijdert ${#orphans[@]} director$([[ ${#orphans[@]} -eq 1 ]] && echo 'y' || echo 'ies') definitief."
read -r -p "Typ 'ja' om door te gaan: " answer
if [[ "$answer" != "ja" ]]; then
  echo "Afgebroken."
  exit 0
fi

for dir in "${orphans[@]}"; do
  rm -rf "$dir"
  echo "verwijderd: $(basename "$dir")"
done

echo "Klaar."
