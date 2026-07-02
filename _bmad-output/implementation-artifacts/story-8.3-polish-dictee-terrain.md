---
story: "8.3"
epic: 8
title: "Polish dictée terrain — suppression de captures et nettoyage prochaine action"
status: done
frs: [FR85, FR86]
nfrs: [NFR-U6]
---

# Story 8.3 : Polish dictée terrain

## Contexte — Pourquoi cette story ?

L'extraction de la base réelle du device (2026-07-02) a montré deux irritants
concrets de la dictée en conditions de chantier :

1. **Artefacts de conversation classés en articles** : la liste de courses réelle
   contenait « Qui est » et « Je lui parle Julie tiens il faut acheter des vis » —
   des fragments captés par le micro pendant une conversation. Le swipe game
   forçait à classer TOUTES les captures : impossible de jeter un déchet.
2. **Le préambule dicté pollue la prochaine action** : « La prochaine action qui
   est percé les Ipe » stocké tel quel — l'utilisateur répète la consigne en
   dictant, et le Hero card affiche la phrase entière.

## User Story

En tant que Nico,
je veux pouvoir jeter une capture parasite sans la classer, et que ma prochaine
action dictée soit débarrassée de son préambule,
afin que mes listes ne contiennent que du contenu utile.

## Acceptance Criteria

### AC1 — Suppression d'une capture (FR85)

**Given** le swipe game affiche une capture
**When** Nico tape « Supprimer cette capture »
**Then** une alerte système de confirmation s'affiche (jamais d'action destructive silencieuse)
**And** après confirmation, la CaptureEntity est supprimée sans entité créée
**And** le total de la barre de progression est décrémenté
**And** le récapitulatif (summaryItems) n'est pas affecté
**And** les fichiers photos orphelins sont nettoyés par le sweep au lancement
(période de grâce 24 h — pas de suppression fichier immédiate)

### AC2 — Nettoyage de la prochaine action (FR86)

**Given** Nico dicte « La prochaine action qui est percé les Ipe » au checkout
**When** il valide
**Then** `tache.prochaineAction` et le ToDo créé contiennent « Percé les Ipe »
**And** les variantes sont gérées : « c'est (de) », « qui est », « est », « : »
**And** un texte sans préambule est inchangé
**And** un texte réduit au préambule seul (« Prochaine action ») est conservé tel quel

## Tests

`ClassificationPolishTests` (8) : 5 cas de nettoyage (phrases réelles du terrain),
save nettoyé (tâche + ToDo), suppression avec décrément du total, récap intact.
