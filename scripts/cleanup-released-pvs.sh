#!/usr/bin/env bash
#
# Verwijdert PersistentVolumes met status "Released".
#
# Bij reclaimPolicy "Retain" blijft een PV na het verwijderen van zijn PVC
# achter met status Released. Zo'n PV wordt niet opnieuw gebruikt en houdt
# alleen nog de data directory op de node vast.
#
# Dit script verwijdert alleen PV's met status Released. PV's die Bound of
# Available zijn worden nooit aangeraakt.
#
# Let op: de data directory op de node blijft bestaan. Ruim die daarna op met
# cleanup-orphan-pv-dirs.sh (draai dat script op de node zelf).
#
# Gebruik:
#   ./cleanup-released-pvs.sh            # dry-run, toont wat verwijderd zou worden
#   ./cleanup-released-pvs.sh --delete   # verwijdert de Released PV's

set -euo pipefail

DELETE=false

for arg in "$@"; do
  case "$arg" in
    --delete) DELETE=true ;;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Onbekende optie: $arg" >&2; exit 2 ;;
  esac
done

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl niet gevonden op deze machine." >&2
  exit 1
fi

# Faalt de API-call, dan stoppen we in plaats van door te gaan op een lege lijst.
if ! released="$(kubectl get pv \
  -o jsonpath='{range .items[?(@.status.phase=="Released")]}{.metadata.name}{"\t"}{.spec.claimRef.namespace}{"/"}{.spec.claimRef.name}{"\t"}{.spec.capacity.storage}{"\n"}{end}' 2>/dev/null)"; then
  echo "Kan de PersistentVolumes niet opvragen. Controleer je kubeconfig." >&2
  exit 1
fi

released="$(printf '%s' "$released" | sed '/^[[:space:]]*$/d')"

if [[ -z "$released" ]]; then
  echo "Geen Released PersistentVolumes gevonden."
  exit 0
fi

echo "De volgende PersistentVolumes hebben status Released:"
echo
printf '  %-42s %-32s %s\n' "PV" "LAATSTE CLAIM" "GROOTTE"
while IFS=$'\t' read -r name claim size; do
  [[ -n "$name" ]] || continue
  printf '  %-42s %-32s %s\n' "$name" "$claim" "$size"
done <<< "$released"
echo

count="$(printf '%s\n' "$released" | wc -l | tr -d ' ')"

if [[ "$DELETE" != true ]]; then
  echo "$count Released PV$([[ "$count" -eq 1 ]] || echo "'s") gevonden."
  echo "Dit was een dry-run. Draai met --delete om ze daadwerkelijk te verwijderen."
  exit 0
fi

echo "Let op: dit verwijdert $count PV-object$([[ "$count" -eq 1 ]] || echo 'en') definitief."
echo "De data directories op de node blijven bestaan."
read -r -p "Typ 'ja' om door te gaan: " answer
if [[ "$answer" != "ja" ]]; then
  echo "Afgebroken."
  exit 0
fi

while IFS=$'\t' read -r name claim size; do
  [[ -n "$name" ]] || continue
  kubectl delete pv "$name"
done <<< "$released"

echo
echo "Klaar. Ruim de achtergebleven directories op met:"
echo "  ./scripts/cleanup-orphan-pv-dirs.sh          # op de node, dry-run"
echo "  sudo ./scripts/cleanup-orphan-pv-dirs.sh --delete"
