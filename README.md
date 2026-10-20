# Microsoft Sentinel — Détection et réponse à une suppression massive de ressources Azure

## Présentation

Ce projet est un laboratoire de **detection engineering** réalisé avec Microsoft Sentinel après l'obtention de la certification **Microsoft SC-200 — Security Operations Analyst Associate**.

L'objectif est de simuler une activité de suppression inhabituelle de ressources Azure, de détecter ce comportement avec KQL, de générer un incident dans Microsoft Sentinel et d'automatiser une partie de son traitement avec une Automation Rule et un playbook Azure Logic Apps.

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
Détection KQL
      ↓
Analytics Rule
      ↓
Incident
      ↓
Automation Rule
      ↓
Logic Apps Playbook
      ↓
Enrichissement automatique
```

## Objectifs

Ce laboratoire permet de mettre en pratique :

- l'analyse des journaux `AzureActivity` ;
- le développement de requêtes KQL ;
- le threat hunting ;
- la création d'une règle analytique Microsoft Sentinel ;
- le mapping avec MITRE ATT&CK ;
- la génération et l'investigation d'incidents ;
- l'automatisation avec Azure Logic Apps ;
- l'utilisation des identités managées et du RBAC Azure ;
- la documentation d'un scénario de détection de bout en bout.

## Scénario

Le scénario simule la création puis la suppression rapide de plusieurs groupes de ressources Azure dédiés au laboratoire.

Les groupes de ressources utilisent exclusivement le préfixe :

```text
sc200-massdel-lab-
```

Aucune ressource de production n'est utilisée ou supprimée.

L'activité générée est ensuite analysée dans Microsoft Sentinel via la table :

```kusto
AzureActivity
```

Le comportement recherché est une série de suppressions de groupes de ressources effectuées sur une courte période.

## MITRE ATT&CK

Le comportement simulé est associé à la technique suivante :

**T1485 — Data Destruction**

Le mapping MITRE ATT&CK est utilisé ici afin d'illustrer le processus de développement et de documentation d'une règle de détection dans Microsoft Sentinel.

## Architecture

```text
Azure CLI
   ↓
Création de groupes de ressources de test
   ↓
Suppression rapide des groupes de ressources
   ↓
Azure Activity Log
   ↓
Log Analytics Workspace
   ↓
Microsoft Sentinel
   ↓
Requêtes KQL de hunting
   ↓
Analytics Rule
   ↓
Alerte / Incident
   ↓
Automation Rule
   ↓
Azure Logic Apps Playbook
   ↓
Tag / commentaire automatique
```

## Technologies utilisées

- Microsoft Sentinel
- Microsoft Defender portal
- Azure Activity Log
- Azure Log Analytics
- Kusto Query Language — KQL
- Azure Logic Apps
- Microsoft Sentinel Analytics Rules
- Microsoft Sentinel Automation Rules
- Azure CLI
- Microsoft Entra ID
- Managed Identities
- Azure RBAC
- MITRE ATT&CK

## Structure du dépôt

```text
sentinel-mass-deletion-lab/
├── README.md
├── .gitignore
│
├── docs/
│   ├── 00-architecture.md
│   ├── 01-simulation.md
│   ├── 02-threat-hunting.md
│   ├── 03-regle-detection.md
│   ├── 04-automatisation.md
│   ├── 05-investigation.md
│   └── 06-cleanup-couts.md
│
├── queries/
│   ├── deletions-by-user.kql
│   ├── deletion-timeline.kql
│   └── mass-deletion-detection.kql
│
├── rules/
│   └── mass-deletion-rule.yaml
│
├── playbook/
│   └── README.md
│
├── scripts/
│   ├── simulate-mass-deletion.sh
│   └── cleanup.sh
│
└── screenshots/
```

## Déroulement du laboratoire

Le laboratoire est organisé en plusieurs étapes :

1. création de groupes de ressources Azure dédiés au test ;
2. suppression contrôlée de ces groupes de ressources ;
3. analyse des événements générés dans `AzureActivity` ;
4. création de requêtes KQL de threat hunting ;
5. développement d'une règle analytique Microsoft Sentinel ;
6. génération d'une alerte et d'un incident ;
7. automatisation du triage avec une Automation Rule et Azure Logic Apps ;
8. investigation de l'incident ;
9. classification de l'activité ;
10. nettoyage des ressources Azure.

## Simulation

La simulation crée plusieurs groupes de ressources Azure vides spécifiquement destinés au laboratoire.

Tous les groupes utilisent le préfixe :

```text
sc200-massdel-lab-
```

Ils sont ensuite supprimés rapidement via Azure CLI afin de générer plusieurs événements de management plane dans Azure Activity Log.

Le script de simulation est disponible dans :

```text
scripts/simulate-mass-deletion.sh
```

Cette convention de nommage permet d'éviter toute confusion avec des ressources Azure existantes.

Aucune ressource autre que celles créées spécifiquement pour ce laboratoire ne doit être supprimée.

## Source de données

Les opérations Azure générées pendant le scénario sont collectées dans la table :

```kusto
AzureActivity
```

Les principaux champs étudiés sont notamment :

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

Ces données permettent d'identifier :

- l'utilisateur à l'origine de l'opération ;
- la ressource ciblée ;
- le type d'opération exécutée ;
- le statut de l'opération ;
- la fréquence des suppressions ;
- la période pendant laquelle les opérations ont été réalisées.

## Threat Hunting

Plusieurs requêtes KQL sont utilisées afin d'investiguer l'activité générée.

Les objectifs du hunting sont notamment :

- identifier les suppressions de ressources ;
- déterminer quel utilisateur a réalisé les opérations ;
- reconstruire la chronologie de l'activité ;
- compter le nombre de suppressions réalisées sur une courte période ;
- différencier une suppression isolée d'un comportement potentiellement anormal.

Les requêtes sont stockées dans :

```text
queries/
```

## Détection

Une Analytics Rule Microsoft Sentinel est développée afin d'identifier plusieurs suppressions de ressources Azure effectuées dans une courte fenêtre temporelle.

La logique générale de détection est la suivante :

```text
AzureActivity
      ↓
Filtrage des opérations de suppression
      ↓
Regroupement par utilisateur
      ↓
Comptage des suppressions
      ↓
Application d'un seuil
      ↓
Génération d'une alerte
```

La règle est documentée et exportée dans :

```text
rules/
```

Elle inclut notamment :

- un nom explicite ;
- une description ;
- une sévérité ;
- une fréquence d'exécution ;
- une période d'analyse ;
- une requête KQL ;
- un mapping d'entités ;
- un mapping MITRE ATT&CK.

## Automatisation

Lorsqu'un incident correspondant au scénario est créé, une Automation Rule Microsoft Sentinel déclenche automatiquement un playbook Azure Logic Apps.

Le workflow attendu est :

```text
Incident Sentinel créé
        ↓
Automation Rule
        ↓
Logic Apps Playbook
        ↓
Ajout d'un commentaire
        ↓
Ajout d'un tag
        ↓
Incident enrichi automatiquement
```

L'objectif n'est pas de fermer automatiquement l'incident, mais d'illustrer une automatisation de triage de niveau SOC.

Le playbook utilise une identité managée afin d'interagir avec Microsoft Sentinel.

## Investigation

Une fois l'incident généré, l'investigation consiste à :

1. examiner la règle ayant généré l'alerte ;
2. identifier l'utilisateur concerné ;
3. vérifier les groupes de ressources supprimés ;
4. reconstruire la timeline des opérations ;
5. examiner l'adresse IP et les informations disponibles sur l'appelant ;
6. valider le nombre de suppressions ;
7. vérifier l'exécution du playbook ;
8. classifier l'incident.

Dans le cadre du laboratoire, l'activité doit finalement être classifiée comme :

```text
Benign Positive / Security Testing
```

La classification permet de démontrer le cycle complet :

```text
Detection
    ↓
Alert
    ↓
Incident
    ↓
Investigation
    ↓
Automation
    ↓
Classification
```

## Résultats attendus

À la fin du laboratoire, Microsoft Sentinel doit permettre de :

- visualiser les opérations de suppression dans `AzureActivity` ;
- identifier l'utilisateur ayant réalisé les suppressions ;
- détecter plusieurs suppressions effectuées sur une courte période ;
- générer automatiquement une alerte ;
- créer un incident Microsoft Sentinel ;
- enrichir l'incident avec les entités pertinentes ;
- déclencher automatiquement un playbook ;
- ajouter un tag ou un commentaire à l'incident ;
- investiguer l'activité avec KQL ;
- classifier correctement l'incident.

## Captures d'écran

Les captures publiées dans le dépôt servent uniquement à démontrer les différentes étapes du laboratoire.

Les captures prévues incluent notamment :

- événements de suppression visibles dans `AzureActivity` ;
- requête KQL de hunting ;
- résultats de la détection ;
- configuration de l'Analytics Rule ;
- incident Microsoft Sentinel ;
- entités associées à l'incident ;
- Automation Rule ;
- Logic Apps Playbook ;
- exécution réussie du playbook ;
- commentaire ou tag ajouté automatiquement.

Les captures sont stockées dans :

```text
screenshots/
```

## Sécurité

Ce projet est réalisé dans un environnement Azure de laboratoire.

Avant publication, les informations sensibles doivent être supprimées ou masquées, notamment :

- Subscription ID ;
- Tenant ID ;
- adresses e-mail personnelles ;
- adresses IP publiques ;
- identifiants de connexions Logic Apps ;
- URL contenant des identifiants internes ;
- tokens ;
- secrets ;
- clés d'API ;
- informations d'authentification.

Aucun secret ou identifiant sensible ne doit être stocké dans le dépôt GitHub.

## Coût

Le laboratoire est conçu pour limiter les coûts Azure.

Les groupes de ressources utilisés pour la simulation sont vides et temporaires.

Les principaux services utilisés sont :

- Microsoft Sentinel ;
- Log Analytics ;
- Azure Activity Log ;
- Azure Logic Apps.

Une attention particulière est portée à :

- la surveillance des coûts Azure ;
- la limitation du volume de données généré ;
- la suppression des ressources temporaires ;
- le nettoyage des Logic Apps et règles créées pour le laboratoire ;
- l'annulation de l'abonnement de test lorsque le projet est terminé.

## Nettoyage

À la fin du laboratoire, les ressources créées spécifiquement pour le projet sont supprimées.

Le processus de nettoyage comprend notamment :

```text
Vérification des résultats
        ↓
Export des configurations utiles
        ↓
Sauvegarde des captures d'écran
        ↓
Commit GitHub
        ↓
Suppression des ressources temporaires
        ↓
Vérification de Cost Management
        ↓
Annulation de l'abonnement de test
```

Un script de nettoyage peut être conservé dans :

```text
scripts/cleanup.sh
```

## Compétences mises en pratique

Ce laboratoire permet de démontrer des compétences en :

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
- Logic Apps ;
- Managed Identities ;
- Azure RBAC ;
- MITRE ATT&CK ;
- automatisation de la réponse à incident.

## Contexte

Ce projet a été réalisé à la suite de l'obtention de la certification :

**Microsoft Certified: Security Operations Analyst Associate — SC-200**

L'objectif est de consolider les connaissances acquises pendant la préparation de la certification et de démontrer leur mise en pratique dans un scénario de sécurité Azure de bout en bout.

Le laboratoire ne cherche pas à reproduire un environnement SOC de production complet, mais à illustrer de manière concrète les différentes étapes d'un workflow de détection et de réponse :

```text
Collecte
   ↓
Analyse
   ↓
Détection
   ↓
Alerte
   ↓
Incident
   ↓
Investigation
   ↓
Automatisation
   ↓
Classification
```

## Avertissement

Ce projet est destiné exclusivement à des fins de formation et de démonstration.

Toutes les actions de suppression sont réalisées sur des ressources Azure créées spécifiquement pour ce laboratoire.

Aucune ressource de production ou appartenant à un tiers ne doit être utilisée dans ce scénario.