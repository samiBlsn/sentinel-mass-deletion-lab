# Microsoft Sentinel — Détection et réponse à une suppression massive de ressources Azure

## Présentation

Ce projet est un laboratoire de **Detection Engineering / SOC** réalisé avec Microsoft Sentinel après l'obtention de la certification :

**Microsoft Certified: Security Operations Analyst Associate — SC-200**

L'objectif est de simuler une **suppression massive de groupes de ressources Azure**, d'analyser les événements générés avec KQL, de créer une règle analytique Microsoft Sentinel, de générer un incident, de l'investiguer puis d'automatiser une partie de son traitement avec une Automation Rule et un playbook Azure Logic Apps.

Le laboratoire couvre une chaîne SOC complète :

```text
Simulation Azure
        ↓
Azure Activity Log
        ↓
Log Analytics
        ↓
Microsoft Sentinel
        ↓
Threat Hunting KQL
        ↓
Analytics Rule
        ↓
Incident High
        ↓
Investigation
        ↓
Automation Rule
        ↓
Logic Apps Playbook
        ↓
Enrichissement automatique
```

---

## Objectifs

Ce laboratoire permet de mettre en pratique :

- l'analyse des journaux `AzureActivity` ;
- le développement de requêtes KQL ;
- le threat hunting ;
- la création d'une règle analytique Microsoft Sentinel ;
- l'utilisation des Entity Mappings et Custom Details ;
- le mapping avec MITRE ATT&CK ;
- la génération et l'investigation d'incidents ;
- l'automatisation avec Azure Logic Apps ;
- l'utilisation d'Azure CLI ;
- la documentation d'un scénario de détection de bout en bout.

---

## Scénario

Le scénario simule la création puis la suppression rapide de plusieurs groupes de ressources Azure dédiés au laboratoire.

Les groupes utilisent exclusivement le préfixe :

```text
sc200-massdel-lab-
```

Six groupes de ressources sont créés :

```text
sc200-massdel-lab-1
sc200-massdel-lab-2
sc200-massdel-lab-3
sc200-massdel-lab-4
sc200-massdel-lab-5
sc200-massdel-lab-6
```

Ils sont ensuite supprimés rapidement via Azure CLI.

Aucune ressource de production n'est utilisée ou supprimée.

---

## MITRE ATT&CK

Le comportement simulé est associé à :

```text
Tactic    : Impact
Technique : T1485 — Data Destruction
```

Le mapping MITRE ATT&CK est utilisé afin d'intégrer la détection dans une logique SOC structurée.

---

## Architecture

```text
Azure CLI
        ↓
Création de groupes de ressources de test
        ↓
Suppression rapide
        ↓
Azure Resource Manager
        ↓
Azure Activity Log
        ↓
Log Analytics Workspace
        ↓
Microsoft Sentinel
        ↓
Threat Hunting KQL
        ↓
Scheduled Analytics Rule
        ↓
Alerte / Incident
        ↓
Investigation
        ↓
Automation Rule
        ↓
Azure Logic Apps Playbook
        ↓
Ajout automatique d'un commentaire
```

---

## Technologies utilisées

- Microsoft Sentinel
- Microsoft Defender portal
- Azure Activity Log
- Azure Log Analytics
- Kusto Query Language — KQL
- Microsoft Sentinel Analytics Rules
- Microsoft Sentinel Automation Rules
- Azure Logic Apps
- Azure CLI
- Microsoft Entra ID
- MITRE ATT&CK
- Git / GitHub

---

## Structure du dépôt

```text
sentinel-mass-deletion-lab/
│
├── README.md
├── .gitignore
│
├── docs/
│   ├── 01-simulation.md
│   ├── 02-threat-hunting.md
│   ├── 03-regle-detection.md
│   ├── 04-automatisation.md
│   ├── 05-investigation.md
│   └── 06-cleanup-couts.md
│
├── queries/
│   ├── 01-deletions-by-identity.kql
│   ├── 02-deletion-timeline.kql
│   └── 03-deletion-baseline-comparison.kql
│
├── rules/
│   └── mass-deletion-rule.json
│
├── scripts/
│   ├── simulate-mass-deletion.sh
│   └── cleanup.sh
│
└── screenshots/
    ├── 01-azureactivity-operation-summary.png
    ├── 02-hunting-deletions-by-identity.png
    ├── 03-hunting-baseline-comparison.png
    ├── 04-analytics-rule-configuration.png
    ├── 05-incident-mass-deletion.png
    ├── 06-incident-entities-details.png
    ├── 07-automation-rule-playbook.png
    └── 08-playbook-automated-comment.png
```

---

# 1. Simulation

Le script :

```text
scripts/simulate-mass-deletion.sh
```

crée six groupes de ressources Azure vides dédiés au laboratoire.

Une confirmation manuelle est demandée avant la suppression.

Le script ne cible que les groupes utilisant le préfixe :

```text
sc200-massdel-lab
```

Cette convention limite le risque de supprimer accidentellement d'autres ressources Azure.

Les groupes sont ensuite supprimés rapidement afin de générer une activité inhabituelle dans Azure Activity Log.

Documentation détaillée :

```text
docs/01-simulation.md
```

---

# 2. Source de données

Les événements générés sont collectés dans la table :

```kusto
AzureActivity
```

Les principaux champs utilisés sont :

```text
TimeGenerated
OperationNameValue
ActivityStatusValue
Caller
CallerIpAddress
ResourceGroup
ResourceId
CorrelationId
```

Les opérations observées pendant le laboratoire sont notamment :

```text
MICROSOFT.RESOURCES/SUBSCRIPTIONS/RESOURCEGROUPS/WRITE
MICROSOFT.RESOURCES/SUBSCRIPTIONS/RESOURCEGROUPS/DELETE
```

Une suppression peut générer plusieurs états :

```text
Start
Accept
Success
```

Pour éviter le double comptage dans la détection, seules les opérations :

```kusto
ActivityStatusValue =~ "Success"
```

sont utilisées pour le comptage.

---

# 3. Threat Hunting

Trois requêtes KQL sont utilisées pour analyser l'activité.

## Suppressions par identité

```text
queries/01-deletions-by-identity.kql
```

Cette requête permet d'identifier :

- l'identité à l'origine des suppressions ;
- l'adresse IP source ;
- le nombre de suppressions ;
- les groupes concernés ;
- la première et la dernière suppression observées.

Résultat :

```text
DeletionCount = 6
```

---

## Reconstruction de la timeline

```text
queries/02-deletion-timeline.kql
```

Cette requête conserve les états :

```text
Start
Accept
Success
```

afin de reconstruire la chronologie complète des opérations.

Le champ :

```text
CorrelationId
```

permet de relier les différents événements appartenant à une même opération Azure.

---

## Comparaison avec l'historique

```text
queries/03-deletion-baseline-comparison.kql
```

La requête compare l'activité récente avec les suppressions historiquement observées pour la même identité.

Résultat du laboratoire :

```text
CurrentDeletionCount    = 6
HistoricalDeletionCount = 0
HistoricalActiveDays    = 0
```

Évaluation :

```text
Aucune suppression observée dans l'historique
```

Documentation détaillée :

```text
docs/02-threat-hunting.md
```

---

# 4. Règle analytique Microsoft Sentinel

Une Scheduled Analytics Rule a été créée :

```text
Mass Azure Resource Group Deletion
```

Sévérité :

```text
High
```

MITRE ATT&CK :

```text
Impact
T1485 — Data Destruction
```

La logique principale est :

```kusto
AzureActivity
| where OperationNameValue =~ "MICROSOFT.RESOURCES/SUBSCRIPTIONS/RESOURCEGROUPS/DELETE"
| where ActivityStatusValue =~ "Success"
| summarize
    DeletedResourceGroupCount = dcount(ResourceGroup),
    DeletedResourceGroups = make_set(ResourceGroup, 100),
    FirstDeletion = min(TimeGenerated),
    LastDeletion = max(TimeGenerated),
    CallerIpAddress = take_any(CallerIpAddress)
    by Caller
| where DeletedResourceGroupCount >= 5
```

La règle recherche donc :

```text
au moins 5 groupes de ressources distincts supprimés par la même identité
```

---

## Planification

Configuration utilisée pendant le laboratoire :

```text
Run query every : 5 minutes
Lookup data from the last : 5 heures
```

Cette fenêtre volontairement large permettait d'inclure les événements déjà générés pendant le scénario.

Dans un environnement de production, elle pourrait être réduite selon le besoin opérationnel.

---

## Entity Mapping

### Account

```text
Entity type : Account
Identifier  : FullName
Column      : Caller
```

### IP

```text
Entity type : IP
Identifier  : Address
Column      : CallerIpAddress
```

---

## Custom Details

Deux détails sont ajoutés à l'alerte :

```text
DeletedRGCount
→ DeletedResourceGroupCount
```

```text
DeletedRGs
→ DeletedResourceGroups
```

Ils permettent à l'analyste de voir immédiatement :

- le nombre de groupes supprimés ;
- la liste des groupes concernés.

---

## Export

La règle déployée a été exportée directement depuis Microsoft Sentinel.

Le fichier est disponible ici :

```text
rules/mass-deletion-rule.json
```

Documentation détaillée :

```text
docs/03-regle-detection.md
```

---

# 5. Incident généré

La simulation a généré :

```text
6 suppressions réussies
```

La règle analytique a ensuite généré :

```text
1 alerte High
        ↓
1 incident Microsoft Sentinel
```

L'incident expose notamment :

```text
Account
IP Address
DeletedRGCount = 6
DeletedRGs
```

Les six groupes supprimés sont visibles directement dans les Custom Details.

---

# 6. Investigation SOC

L'investigation consiste à :

1. identifier le compte ayant effectué les suppressions ;
2. vérifier l'adresse IP source ;
3. valider le nombre de suppressions réussies ;
4. reconstruire la timeline ;
5. analyser les `CorrelationId` ;
6. comparer l'activité avec l'historique ;
7. examiner le contexte ;
8. classifier l'incident.

Les éléments observés sont :

```text
6 suppressions réussies
        ↓
même identité
        ↓
fenêtre temporelle très courte
        ↓
activité inhabituelle
        ↓
aucune suppression observée dans l'historique disponible
```

Dans le contexte du laboratoire, les suppressions ont été volontairement générées par le script de simulation.

La classification finale est donc :

```text
Benign Positive / Security Testing
```

La détection est correcte, mais l'activité est autorisée dans le contexte du laboratoire.

Documentation détaillée :

```text
docs/05-investigation.md
```

---

# 7. Automatisation SOAR

Une Automation Rule a été configurée :

```text
ar-mass-deletion-triage
```

Déclencheur :

```text
When incident is created
```

Condition :

```text
Analytic rule name
Contains
Mass Azure Resource Group Deletion
```

Action :

```text
Run Logic App playbook
```

Playbook utilisé :

```text
PB-SC200-Incident
```

Le playbook ajoute automatiquement un commentaire dans l'activité de l'incident.

Exemple observé :

```text
[SC-200 LAB] Traitement automatique déclenché par PB-SC200-Incident :
Mass Azure Resource Group Deletion
```

La chaîne devient donc :

```text
Incident
        ↓
Automation Rule
        ↓
PB-SC200-Incident
        ↓
Ajout automatique d'un commentaire
        ↓
Incident enrichi
```

Documentation détaillée :

```text
docs/04-automatisation.md
```

---

# 8. Résultats obtenus

Le laboratoire a permis de valider :

- la génération contrôlée de télémétrie Azure ;
- l'ingestion des événements dans `AzureActivity` ;
- le threat hunting avec KQL ;
- l'identification de suppressions multiples ;
- la reconstruction d'une timeline ;
- la comparaison avec une baseline historique ;
- la création d'une Analytics Rule ;
- l'association MITRE ATT&CK `T1485` ;
- l'utilisation des Entity Mappings ;
- l'utilisation des Custom Details ;
- la génération d'un incident High ;
- l'investigation de l'activité ;
- la classification en `Benign Positive` ;
- l'association d'une Automation Rule ;
- l'enrichissement automatique de l'incident avec un playbook.

---

# 9. Captures

## Azure Activity

![Azure Activity operations](screenshots/01-azureactivity-operation-summary.png)

## Threat Hunting

![Deletion hunting](screenshots/02-hunting-deletions-by-identity.png)

![Baseline comparison](screenshots/03-hunting-baseline-comparison.png)

## Règle analytique

![Analytics rule](screenshots/04-analytics-rule-configuration.png)

## Incident

![Generated incident](screenshots/05-incident-mass-deletion.png)

![Incident entities and custom details](screenshots/06-incident-entities-details.png)

## Automatisation

![Automation rule](screenshots/07-automation-rule-playbook.png)

![Automated playbook comment](screenshots/08-playbook-automated-comment.png)

---

# 10. Nettoyage et coûts

Un script de nettoyage est disponible :

```text
scripts/cleanup.sh
```

Il recherche uniquement les groupes dont le nom commence par :

```text
sc200-massdel-lab
```

avant de demander une confirmation manuelle.

Cette approche permet de limiter le risque de suppression accidentelle.

Le laboratoire a également été conçu pour limiter les coûts :

- groupes de ressources vides ;
- faible volume de logs ;
- simulation ponctuelle ;
- réutilisation d'un workspace existant ;
- requêtes KQL ciblées ;
- suppression ou désactivation des ressources inutiles après les tests.

Documentation détaillée :

```text
docs/06-cleanup-couts.md
```

---

# 11. Sécurité

Avant publication du dépôt, les informations sensibles doivent être supprimées ou masquées.

Notamment :

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

Les captures du dépôt sont anonymisées lorsque nécessaire.

Aucun secret ne doit être stocké dans GitHub.

---

# 12. Compétences mises en pratique

Ce laboratoire démontre des compétences en :

- Security Operations ;
- Microsoft Sentinel ;
- Detection Engineering ;
- Threat Hunting ;
- Kusto Query Language ;
- SIEM ;
- SOAR ;
- Incident Response ;
- Azure Security ;
- Azure Activity Log ;
- Analytics Rules ;
- Entity Mapping ;
- Custom Details ;
- Logic Apps ;
- Azure CLI ;
- MITRE ATT&CK ;
- Git / GitHub ;
- documentation technique.

---

# Conclusion

Ce projet démontre la construction d'un scénario Microsoft Sentinel de bout en bout :

```text
Collecte
    ↓
Threat Hunting
    ↓
Détection
    ↓
Alerte
    ↓
Incident
    ↓
Investigation
    ↓
Classification
    ↓
Automatisation
```

L'objectif n'était pas uniquement de créer une requête KQL, mais de reproduire un workflow SOC cohérent autour d'un comportement potentiellement destructif dans Azure.

Le laboratoire complète la certification :

**Microsoft Certified: Security Operations Analyst Associate — SC-200**

en mettant en pratique les concepts Sentinel, KQL, investigation, MITRE ATT&CK et SOAR dans un environnement Azure réel.

---

## Avertissement

Ce projet est destiné exclusivement à des fins de formation et de démonstration.

Toutes les actions de suppression sont réalisées sur des ressources Azure créées spécifiquement pour ce laboratoire.

Aucune ressource de production ou appartenant à un tiers ne doit être utilisée dans ce scénario.
