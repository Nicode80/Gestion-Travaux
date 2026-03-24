# Backlog V2+ — Gestion Travaux

Idées et fonctionnalités validées comme pertinentes mais hors scope MVP (V1).
Mise à jour au fil des retours terrain et sessions d'analyse.

---

## Apple Watch — Mode Chantier (priorité : Nice to Have)

**Validé le :** 2026-03-08
**Source :** Test terrain réel — retour de Nico

### Concept

Permettre de créer des captures (Alertes, ToDos, Astuces, Achats) directement depuis l'Apple Watch en Mode Chantier, sans sortir le téléphone de la poche.

### Valeur terrain

Situation typique : mains occupées (outil dans une main, matériau dans l'autre), besoin de noter quelque chose immédiatement. La Watch est accessible d'un simple lever de poignet.

### Flux envisagé

1. Appuyer sur un grand bouton sur la Watch (équivalent BigButton)
2. Dicter vocalement (micro Watch)
3. Choisir la direction (swipe ou boutons : ALERTE / ASTUCE / TO DO / ACHAT)
4. La capture est créée et synchronisée vers l'iPhone

### Considérations techniques

- **Target séparé** : nécessite un target watchOS dans Xcode — deuxième mini-app à maintenir
- **WatchConnectivity** : framework de sync Watch ↔ iPhone, avec logique d'état propre (reachable/background)
- **SwiftData non partagé** entre les deux targets — les captures Watch sont transférées vers iPhone via WatchConnectivity puis insérées dans le ModelContainer iPhone
- **SFSpeechRecognizer** disponible sur watchOS 10+ (on-device)
- **BigButton** à repenser : 120×120pt impossible sur Watch, interface radicalement simplifiée
- **AudioEngine** sur watchOS : capacités plus limitées qu'iOS, quirks spécifiques

### Estimation complexité

Équivalent 3-4 stories de complexité moyenne. Constitue une nouvelle Epic à part entière.

---

## Activation vocale mains libres — Mode Chantier (priorité : Nice to Have)

**Validé le :** 2026-03-09
**Source :** Session brainstorming avec Nico

### Concept

Permettre de déclencher l'enregistrement vocal en Mode Chantier sans toucher l'écran, via un mot-déclencheur (style "Hey Siri"), pour les situations où les mains sont sales ou occupées sur le chantier.

### Flux envisagé

1. Mode Chantier ouvert → écoute passive en continu (mot-déclencheur)
2. Mot-déclencheur prononcé → bouton passe au VERT automatiquement → enregistrement actif
3. Silence détecté pendant 5 à 10 secondes → stop auto → capture sauvegardée → retour au ROUGE
4. L'écoute passive reprend immédiatement

### Phrase déclencheur recommandée

**"Gestion travaux"** — nom de l'app, improbable en conversation naturelle sur un chantier, phonétiquement distinctif. À valider par test terrain (bruit de fond, accent, robustesse).

### Considérations techniques

- **Écoute passive en boucle** : `AVAudioEngine` + `SFSpeechRecognizer` en streaming continu pendant tout le Mode Chantier
- **Limite 1 min SFSpeechRecognizer** : redémarrage automatique de la tâche de reconnaissance en boucle
- **Détection silence** : via `AVAudioRecorder.averagePower` ou analyse du buffer — seuil à calibrer (5-10s)
- **Drain batterie** : écoute passive permanente = impact non négligeable, à mesurer sur device réel
- **Faux positifs** : à minimiser via seuil de confiance sur la reconnaissance du mot-clé
- **Compatibilité** : s'intègre à l'`AudioEngine` existant — pas de refonte majeure de l'architecture

### Estimation complexité

1-2 stories de complexité moyenne. Peut constituer une story dédiée dans l'Epic Mode Chantier.

---

## Notes libres (si besoin validé)

**Validé le :** 2026-03-08

Si des retours terrain montrent le besoin de notes libres (pas des ToDos, pas des Alertes), envisager une `NoteLibreEntity` non liée à une pièce ou tâche spécifique. À distinguer clairement des `ToDoEntity` (prochaines choses à faire par pièce).

---

## Synchronisation iCloud (multi-device)

SwiftData CloudKit — si usage multi-device validé (ex: Nico + conjoint/conjonte sur le même chantier).

---

## XCUITests Swipe Game

Overhead justifié à partir de V2 quand la surface UI est stable.
