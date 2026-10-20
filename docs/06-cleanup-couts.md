# Nettoyage et maîtrise des coûts

## Objectif

Cette dernière étape vise à limiter les coûts Azure après la réalisation du laboratoire et à supprimer les ressources créées uniquement pour les besoins du scénario.

Le laboratoire utilise plusieurs composants Azure susceptibles de générer des coûts :

```text
Microsoft Sentinel
Log Analytics Workspace
Azure Activity Logs
Logic Apps
Automation Rules
Resource Groups de test
```

Une attention particulière est donc portée au nettoyage après validation du scénario.

---

## Ressources temporaires du scénario

Les groupes de ressources utilisés pour simuler l'activité destructive sont :

```text
SC200-MASSDEL-LAB-1
SC200-MASSDEL-LAB-2
SC200-MASSDEL-LAB-3
SC200-MASSDEL-LAB-4
SC200-MASSDEL-LAB-5
SC200-MASSDEL-LAB-6
```

Ces groupes ont été créés uniquement pour le laboratoire.

Ils ne contiennent aucune ressource de production.

Leur suppression fait partie intégrante du scénario de détection.

---

## Vérification des groupes de ressources

Une vérification peut être réalisée avec Azure CLI :

```bash
az group list \
  --query "[?starts_with(name, 'sc200-massdel-lab')].name" \
  --output table
```

Si aucun groupe n'est retourné, les ressources temporaires utilisées pour la simulation ont bien été supprimées.

---

## Script de nettoyage

Un script dédié peut être conservé dans :

```text
scripts/cleanup.sh
```

Exemple :

```bash
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
```

Le préfixe spécifique :

```text
sc200-massdel-lab
```

limite le risque de supprimer accidentellement des groupes de ressources n'appartenant pas au laboratoire.

---

## Ressources Sentinel conservées

Certaines ressources peuvent être conservées lorsqu'elles sont utilisées pour d'autres exercices ou laboratoires.

Par exemple :

```text
Log Analytics Workspace
Microsoft Sentinel
Azure Activity connector
```

Le workspace utilisé pour ce laboratoire est également utilisé comme environnement de formation SC-200.

Il n'est donc pas nécessaire de le supprimer systématiquement après chaque scénario si d'autres exercices doivent encore être réalisés.

---

## Règle analytique

La règle :

```text
Mass Azure Resource Group Deletion
```

peut être désactivée après le laboratoire afin d'éviter la génération d'incidents inutiles.

La configuration de la règle reste versionnée dans le dépôt :

```text
rules/mass-deletion-rule.json
```

Elle peut donc être recréée ou adaptée ultérieurement.

---

## Automation Rule et playbook

L'Automation Rule utilisée pour le scénario est :

```text
ar-mass-deletion-triage
```

Le playbook associé est :

```text
PB-SC200-Incident
```

Un playbook Logic App peut générer des coûts lorsqu'il est exécuté.

Une bonne pratique consiste donc à :

```text
désactiver les automatisations inutilisées
```

ou :

```text
supprimer les ressources dédiées uniquement au laboratoire
```

une fois les tests terminés.

---

## Log Analytics et Sentinel

La majorité des coûts liés à Microsoft Sentinel proviennent de l'ingestion et de la conservation des données.

Ce laboratoire limite volontairement le volume généré.

La source principale utilisée est :

```text
AzureActivity
```

Le scénario ne nécessite que quelques dizaines d'événements.

Le volume d'ingestion généré reste donc très faible comparé à un environnement de production.

---

## Maîtrise du volume de logs

Plusieurs choix permettent de limiter la consommation :

```text
nombre limité de ressources de test
```

```text
simulation ponctuelle
```

```text
absence de génération massive d'événements
```

```text
requêtes KQL ciblées
```

```text
réutilisation d'un workspace existant
```

Le laboratoire privilégie ainsi la démonstration de la chaîne SOC plutôt qu'un volume important de données.

---

## Vérification Azure Cost Management

Après le laboratoire, les coûts peuvent être vérifiés dans :

```text
Azure Portal
→ Cost Management
→ Cost analysis
```

Les principaux éléments à surveiller sont :

```text
Log Analytics
Microsoft Sentinel
Logic Apps
```

Cette vérification permet de confirmer qu'aucune ressource inattendue ne continue à générer des coûts.

---

## Données sensibles et publication GitHub

Avant publication du dépôt, les fichiers et captures ont été vérifiés afin d'éviter l'exposition d'informations sensibles.

Les éléments suivants ne doivent pas apparaître publiquement :

```text
Tenant ID
Subscription ID
email personnel
adresse IP publique
credentials
tokens
secrets
connection strings
```

Les captures contenant des informations personnelles sont anonymisées avant publication.

Le fichier :

```text
.gitignore
```

permet également d'éviter le versionnement accidentel de fichiers contenant des secrets ou des paramètres locaux.

---

## Export des configurations

Les éléments importants du laboratoire sont conservés sous forme de code ou de configuration versionnée :

```text
queries/
    requêtes KQL

rules/
    export de la règle analytique

scripts/
    simulation et nettoyage

docs/
    documentation technique

screenshots/
    preuves de validation
```

Cette approche permet de supprimer les ressources Azure tout en conservant une reproduction complète du travail réalisé.

---

## Stratégie générale de nettoyage

La stratégie appliquée au laboratoire peut être résumée ainsi :

```text
Créer uniquement les ressources nécessaires
        ↓
Effectuer la simulation
        ↓
Valider la télémétrie
        ↓
Valider la détection
        ↓
Valider l'incident
        ↓
Valider l'automatisation
        ↓
Exporter les configurations
        ↓
Documenter les résultats
        ↓
Supprimer ou désactiver les ressources inutiles
```

---

## Conclusion

Le laboratoire a été conçu pour rester reproductible tout en limitant la consommation de ressources Azure.

Les principaux composants techniques sont conservés dans GitHub sous forme de :

```text
KQL
scripts
configuration Sentinel
documentation
captures
```

Les ressources cloud peuvent ainsi être supprimées ou désactivées après les tests sans perdre le travail réalisé.

Cette approche permet de combiner :

```text
expérimentation technique
+
maîtrise des coûts
+
sécurité des informations
+
reproductibilité
```
