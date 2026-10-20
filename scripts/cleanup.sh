#!/usr/bin/env bash

PREFIX="sc200-massdel-lab"

echo "[+] Recherche des groupes de ressources du laboratoire..."

RESOURCE_GROUPS=$(az group list \
  --query "[?starts_with(name, '${PREFIX}')].name" \
  --output tsv)

if [ -z "$RESOURCE_GROUPS" ]; then
    echo "[+] Aucun groupe de ressources temporaire trouvé."
    exit 0
fi

echo
echo "Les groupes suivants seront supprimés :"
echo "$RESOURCE_GROUPS"
echo

read -p "Confirmer la suppression ? [y/N] " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Suppression annulée."
    exit 0
fi

for RG in $RESOURCE_GROUPS; do
    echo "[+] Suppression de $RG"

    az group delete \
      --name "$RG" \
      --yes \
      --no-wait
done

echo
echo "[+] Suppressions demandées."
