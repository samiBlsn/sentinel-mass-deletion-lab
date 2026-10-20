# Investigation SOC — Incident de suppression massive Azure

## Objectif

Cette étape documente l'investigation d'un incident Microsoft Sentinel généré par la règle :

```text
Mass Azure Resource Group Deletion
```

L'objectif est de montrer comment un analyste SOC peut exploiter :

- les entités associées à l'incident ;
- les Custom Details ;
- les événements `AzureActivity` ;
- les requêtes KQL de hunting ;
- la chronologie des opérations ;
- le contexte d'automatisation ;

afin de déterminer si l'activité observée est légitime ou potentiellement malveillante.

---

## Incident analysé

La règle analytique a généré un incident de sévérité :

```text
High
```

Le scénario détecté correspond à :

```text
6 suppressions réussies de groupes de ressources Azure
```

réalisées par la même identité dans une fenêtre temporelle très courte.

L'incident est associé à la technique MITRE ATT&CK :

```text
T1485 — Data Destruction
```

avec la tactique :

```text
Impact
```

---

## Informations disponibles dans l'incident

L'incident contient plusieurs éléments utiles à l'investigation.

### Entité compte

La règle analytique associe le champ :

```text
Caller
```

à une entité Sentinel de type :

```text
Account
```

Cette information permet d'identifier le compte ayant effectué les suppressions.

### Entité adresse IP

Le champ :

```text
CallerIpAddress
```

est associé à une entité Sentinel de type :

```text
IP
```

Cette donnée peut être utilisée pour déterminer l'origine réseau de l'activité.

### Custom Details

Deux informations sont directement exposées dans l'incident :

```text
DeletedRGCount
```

et :

```text
DeletedRGs
```

Le résultat observé est :

```text
DeletedRGCount = 6
```

avec les groupes :

```text
SC200-MASSDEL-LAB-1
SC200-MASSDEL-LAB-2
SC200-MASSDEL-LAB-3
SC200-MASSDEL-LAB-4
SC200-MASSDEL-LAB-5
SC200-MASSDEL-LAB-6
```

Ces données permettent de comprendre immédiatement l'étendue de l'activité sans devoir commencer par une recherche manuelle dans les journaux.

---

## Première hypothèse

Une suppression rapide de plusieurs groupes de ressources par une même identité peut correspondre à plusieurs situations :

```text
activité administrative légitime
```

ou :

```text
compte compromis
```

ou :

```text
action destructive volontaire
```

ou :

```text
script ou automatisation exécuté de manière incorrecte
```

La seule présence de plusieurs suppressions ne permet donc pas de conclure immédiatement à une compromission.

L'objectif de l'investigation est de replacer ces événements dans leur contexte.

---

## Requête de validation

La première étape consiste à vérifier les suppressions réellement terminées avec succès.

```kusto
AzureActivity
| where TimeGenerated > ago(24h)
| where OperationNameValue =~ "MICROSOFT.RESOURCES/SUBSCRIPTIONS/RESOURCEGROUPS/DELETE"
| where ActivityStatusValue =~ "Success"
| summarize
    DeletionCount = count(),
    FirstDeletion = min(TimeGenerated),
    LastDeletion = max(TimeGenerated),
    DeletedResourceGroups = make_set(ResourceGroup, 100)
    by Caller, CallerIpAddress
| order by DeletionCount desc
```

Cette requête confirme :

```text
DeletionCount = 6
```

pour une seule identité.

---

## Analyse temporelle

La chronologie complète est reconstruite avec :

```kusto
AzureActivity
| where TimeGenerated > ago(24h)
| where OperationNameValue =~ "MICROSOFT.RESOURCES/SUBSCRIPTIONS/RESOURCEGROUPS/DELETE"
| where ActivityStatusValue in~ ("Start", "Accept", "Success")
| project
    TimeGenerated,
    Caller,
    CallerIpAddress,
    ResourceGroup,
    ActivityStatusValue,
    CorrelationId
| order by TimeGenerated asc
```

Cette requête permet d'observer les différentes phases des opérations :

```text
Start
Accept
Success
```

Les suppressions ont été exécutées dans une fenêtre temporelle très courte.

Ce comportement est cohérent avec l'exécution d'un script ou d'une automatisation plutôt qu'avec des suppressions manuelles réalisées une par une depuis le portail Azure.

---

## Importance du CorrelationId

Le champ :

```text
CorrelationId
```

permet de rapprocher les différents événements appartenant à une même opération Azure.

Par exemple :

```text
DELETE
├── Start
├── Accept
└── Success
```

peuvent correspondre à une seule opération réelle.

Pendant une investigation, ce champ permet donc d'éviter de considérer chaque état comme une action indépendante.

---

## Comparaison avec l'historique

La requête de baseline développée précédemment est utilisée pour comparer l'activité actuelle avec les suppressions observées dans le passé.

Résultat observé :

```text
CurrentDeletionCount = 6
HistoricalDeletionCount = 0
HistoricalActiveDays = 0
```

L'évaluation associée est :

```text
Aucune suppression observée dans l'historique
```

L'activité actuelle est donc inhabituelle par rapport aux données disponibles dans le workspace.

---

## Interprétation de la baseline

Cette observation augmente l'intérêt de l'incident mais ne constitue pas, à elle seule, une preuve de compromission.

L'historique du laboratoire est limité.

Dans un environnement de production, l'analyse pourrait être complétée avec :

- les habitudes du compte concerné ;
- les horaires habituels d'administration ;
- les connexions récentes de l'identité ;
- les changements de rôles Azure ;
- les autres opérations effectuées depuis la même adresse IP ;
- les événements Microsoft Entra ID associés ;
- les alertes de Threat Intelligence ;
- les modifications réalisées avant les suppressions.

---

## Recherche d'activité associée

Une investigation peut être étendue en recherchant toutes les opérations effectuées par la même identité autour de l'heure de l'incident.

Exemple :

```kusto
AzureActivity
| where TimeGenerated > ago(24h)
| where Caller == "<identité observée>"
| project
    TimeGenerated,
    OperationNameValue,
    ActivityStatusValue,
    ResourceGroup,
    Resource,
    CallerIpAddress,
    CorrelationId
| order by TimeGenerated asc
```

Cette recherche permet notamment de déterminer si le compte a effectué d'autres actions sensibles avant ou après les suppressions.

---

## Évaluation de l'incident

Les éléments observés sont :

```text
6 suppressions réussies
        ↓
même identité
        ↓
même contexte temporel
        ↓
activité très rapide
        ↓
aucune suppression observée dans l'historique disponible
```

Ces caractéristiques justifient la création d'un incident de sévérité élevée et une investigation.

---

## Contexte du laboratoire

Dans le contexte de ce laboratoire, les suppressions ont été volontairement générées via le script :

```text
scripts/simulate-mass-deletion.sh
```

Les groupes de ressources concernés avaient été créés spécifiquement pour le test.

L'activité est donc connue comme :

```text
Authorized / Benign simulation
```

Il s'agit d'un scénario de test volontaire destiné à valider la chaîne de détection.

---

## Classification

Après investigation, l'incident peut être classifié comme :

```text
Benign Positive
```

La détection est correcte :

```text
la règle a identifié l'activité attendue
```

mais l'activité n'est pas malveillante dans le contexte du laboratoire.

Cette distinction est importante :

```text
False Positive
```

signifierait que la règle a détecté à tort un comportement ne correspondant pas au scénario recherché.

Ici, la détection est techniquement correcte.

L'activité est simplement autorisée.

---

## Réponse de l'analyste

Dans un environnement réel, si l'activité était non autorisée, les actions suivantes pourraient être envisagées :

```text
1. Vérifier immédiatement la légitimité du compte.
2. Contacter le propriétaire ou l'équipe responsable.
3. Examiner les authentifications récentes.
4. Vérifier les changements de privilèges.
5. Rechercher d'autres opérations Azure sensibles.
6. Identifier les ressources détruites.
7. Évaluer les possibilités de restauration.
8. Révoquer les sessions ou désactiver le compte si nécessaire.
9. Escalader l'incident vers l'équipe de réponse à incident.
```

Les mesures de confinement doivent toutefois dépendre du contexte afin d'éviter une interruption supplémentaire des services.

---

## Automatisation associée

L'incident peut également être enrichi automatiquement via :

```text
ar-mass-deletion-triage
```

et le playbook :

```text
PB-SC200-Incident
```

Le playbook ajoute un commentaire dans l'activité de l'incident afin de signaler qu'un traitement automatique a été effectué.

Cela permet de combiner :

```text
Détection
+
Investigation
+
Automatisation SOAR
```

dans une même chaîne SOC.

---

## Synthèse de l'investigation

L'investigation permet d'établir la séquence suivante :

```text
Détection de suppressions multiples
        ↓
Identification du compte et de l'IP
        ↓
Validation des suppressions réussies
        ↓
Reconstruction de la chronologie
        ↓
Comparaison avec l'historique
        ↓
Analyse du contexte
        ↓
Classification
```

Résultat final du laboratoire :

```text
Détection valide
Incident valide
Activité autorisée
Classification : Benign Positive
```

---

## Conclusion

Cette étape démontre qu'une règle de détection ne constitue que le début du processus SOC.

Une alerte doit être replacée dans son contexte afin de distinguer :

```text
activité malveillante
```

de :

```text
activité administrative légitime
```

Le scénario permet ainsi de couvrir plusieurs étapes du cycle SOC :

```text
Collecte
→ Hunting
→ Détection
→ Incident
→ Investigation
→ Classification
→ Automatisation
```
