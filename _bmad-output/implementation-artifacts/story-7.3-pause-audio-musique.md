---
story: "7.3"
epic: 7
title: "Pause musique pendant la dictée — interruption audio AVAudioSession"
status: ready
frs: [FR76, FR77]
nfrs: [NFR-R3, NFR-P2]
---

# Story 7.3 : Pause musique pendant la dictée — interruption audio AVAudioSession

## Contexte — Pourquoi cette story ?

**Décision issue d'une utilisation réelle (2026-03-24)**

Nico écoute régulièrement de la musique sur le chantier (Apple Music, Spotify, YouTube Music). Quand il passe le bouton en vert pour dicter, la musique continue à jouer, ce qui nuit à la reconnaissance vocale et rend les transcriptions inexploitables.

**Cause technique identifiée :** Dans `AudioEngine.demarrer()` (ligne 122), la session AVAudio est configurée avec l'option `.mixWithOthers` :
```swift
try session.setCategory(
    .playAndRecord,
    mode: .default,
    options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothHFP]
)
```
L'option `.mixWithOthers` indique à iOS que notre session doit **coexister** avec les autres sessions audio actives (Spotify, Apple Music, etc.). Résultat : la musique continue pendant la dictée.

**Ce qui doit changer :** Retirer `.mixWithOthers` pour que iOS interrompe automatiquement les autres apps audio au démarrage de l'enregistrement, et les notifie de reprendre à l'arrêt.

**⚠️ Risque story 2.3 :** Le commentaire existant dans `AudioEngine.swift` indique que `.mixWithOthers` a été ajouté pour que la caméra n'interrompe pas l'audio. Ce commentaire doit être **vérifié** : dans iOS, la caméra d'une même app partage la même `AVAudioSession` — elle ne crée pas une session concurrente. `.mixWithOthers` ne devrait donc pas être nécessaire pour les photos intra-app. L'agent devra tester ce point sur device réel avant de merger.

---

## User Story

En tant que Nico,
je veux que la musique que j'écoute se mette en pause automatiquement quand je commence à dicter et reprenne quand j'arrête,
afin que mes transcriptions soient propres même quand j'écoute de la musique sur le chantier.

---

## Acceptance Criteria

### Interruption au démarrage de l'enregistrement

**Given** Nico écoute de la musique depuis n'importe quelle app (Apple Music, Spotify, YouTube Music, ou autre)
**When** il appuie sur le gros bouton et que le bouton passe au vert (enregistrement démarré)
**Then** la musique s'arrête dans les 500ms suivant l'activation
**And** la reconnaissance vocale fonctionne sans interférence sonore

**Given** aucune musique n'est en cours de lecture
**When** l'enregistrement démarre
**Then** le comportement reste identique à aujourd'hui (aucune régression)

### Reprise à l'arrêt de l'enregistrement

**Given** l'enregistrement est actif et la musique est en pause (interrompue par l'app)
**When** Nico appuie sur le gros bouton et que le bouton revient au rouge (enregistrement stoppé)
**Then** iOS notifie les apps tierces de reprendre leur lecture
**And** la musique reprend dans l'app tierce (comportement dépendant de l'app tierce — certaines apps comme Spotify reprennent automatiquement, d'autres non, ce n'est pas contrôlable depuis notre app)

**Given** l'enregistrement s'arrête suite à une interruption iOS (appel entrant, etc.)
**When** l'interruption est traitée par le handler existant (story 2.4)
**Then** la notification de reprise est également envoyée aux apps tierces

### Non-régression Story 2.3 — photos pendant la dictée

**Given** Nico est en cours d'enregistrement (bouton vert)
**When** il prend une photo avec le bouton photo
**Then** l'enregistrement vocal n'est PAS interrompu (NFR-P7 : interruption < 200ms)
**And** la transcription continue sans coupure

> **Note de test obligatoire :** Ce critère doit être validé sur device réel après le retrait de `.mixWithOthers`. Si une régression est détectée, utiliser `.duckOthers` comme fallback (voir section Notes d'implémentation).

---

## Notes d'implémentation

### Changement principal dans `AudioEngine.demarrer()`

**Fichier :** `Services/AudioEngine.swift`, dans le `Task.detached`, à la configuration de `AVAudioSession`.

**Avant :**
```swift
try session.setCategory(
    .playAndRecord,
    mode: .default,
    options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothHFP]
)
try session.setActive(true, options: .notifyOthersOnDeactivation)
```

**Après (option principale) :**
```swift
try session.setCategory(
    .playAndRecord,
    mode: .default,
    options: [.defaultToSpeaker, .allowBluetoothHFP]  // .mixWithOthers retiré
)
try session.setActive(true)  // sans .notifyOthersOnDeactivation ici — les autres apps sont interrompues
```

La clé : sans `.mixWithOthers`, quand `setActive(true)` est appelé, iOS envoie une notification d'interruption aux autres sessions audio actives (Spotify, Apple Music, etc.).

### Notification de reprise dans `stopInterne()` ou `arreter()`

Pour que les apps tierces reprennent, il faut appeler `setActive(false, options: .notifyOthersOnDeactivation)` lors de l'arrêt. Vérifier si `stopInterne()` ou `arreter()` appelle déjà cette méthode — si non, l'ajouter dans le `Task.detached` correspondant.

```swift
// À ajouter dans le nettoyage hardware (Task.detached)
try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
```

Ce call est dans un `try?` car une erreur ici ne doit pas empêcher l'arrêt de l'enregistrement.

### Fallback `.duckOthers` si régression story 2.3

Si les tests sur device réel révèlent que retirer `.mixWithOthers` interrompt effectivement la prise de photo, utiliser `.duckOthers` comme option intermédiaire :

```swift
options: [.defaultToSpeaker, .duckOthers, .allowBluetoothHFP]
```

`.duckOthers` réduit le volume des autres apps (duck = -12dB) sans les interrompre complètement. C'est moins optimal pour la reconnaissance vocale mais évite la régression. Informer Nico du résultat du test pour choisir.

### Comportement de reprise selon les apps

La reprise automatique après `notifyOthersOnDeactivation` dépend du comportement de l'app tierce :
- **Apple Music** : reprend automatiquement ✅
- **Spotify** : reprend automatiquement (généralement) ✅
- **YouTube Music** : comportement variable selon la version

Ce comportement est non-contrôlable depuis notre app — c'est la responsabilité de l'app tierce de répondre à la notification de reprise.

### Concurrence Swift 6

Le changement de session AVAudio se fait dans un `Task.detached` (pattern établi dans l'app, voir commit 69df9b7). Tous les accès à `AVAudioSession.sharedInstance()` doivent rester dans ce contexte.

### Tests

- Test sur **device réel** obligatoire (les simulateurs n'ont pas de vrai hardware audio)
- Tester avec Apple Music, puis Spotify si disponible
- Tester la prise de photo pendant dictée avec et sans musique préalable

---

## Fichiers probablement impactés

| Fichier | Type de changement |
|---------|-------------------|
| `Services/AudioEngine.swift` | Retirer `.mixWithOthers` de `demarrer()`, ajouter `notifyOthersOnDeactivation` dans arrêt |
| `Services/AudioEngineProtocol.swift` | Aucun changement attendu |
| `Mocks/MockAudioEngine.swift` | Aucun changement attendu |

---

## Dépendances

- Story 2.2 (done) : `AudioEngine.demarrer()` — fichier à modifier
- Story 2.3 (done) : photos pendant la dictée — test de non-régression obligatoire
- Story 2.4 (done) : gestion des interruptions iOS — le handler existant doit aussi envoyer `notifyOthersOnDeactivation`
- Aucune migration SwiftData (pas de persistance)
