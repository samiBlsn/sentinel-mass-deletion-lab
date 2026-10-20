#!/usr/bin/env bash
set -euo pipefail

LOCATION="francecentral"
PREFIX="sc200-massdel-lab"
COUNT=6

echo "=== Microsoft Sentinel - Mass Deletion Simulation ==="

echo "[+] Création de ${COUNT} groupes de ressources..."

for i in $(seq 1 "$COUNT"); do
    RG="${PREFIX}-${i}"

    echo "[+] Création : $RG"

    az group create \
        --name "$RG" \
        --location "$LOCATION" \
        --tags Purpose="SC200-MassDeletion-Lab" Environment="Lab" \
        --output none
done

echo
echo "[+] Groupes créés :"

az group list \
    --query "[?starts_with(name, '${PREFIX}')].{Name:name,Location:location}" \
    --output table

echo
echo "[!] Seuls les groupes '${PREFIX}-*' seront supprimés."
read -r -p "Appuie sur Entrée pour lancer la suppression..."

for i in $(seq 1 "$COUNT"); do
    RG="${PREFIX}-${i}"

    if [ "$(az group exists --name "$RG")" = "true" ]; then
        echo "[-] Suppression : $RG"

        az group delete \
            --name "$RG" \
            --yes \
            --no-wait
    fi
done

echo
echo "[+] Requêtes de suppression envoyées."
echo "[+] Attends quelques minutes puis vérifie AzureActivity."
