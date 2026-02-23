---
story: "2.4"
epic: 2
title: "Gestion des interruptions iOS et mode économie batterie"
status: pending
frs: [FR60]
nfrs: [NFR-P10, NFR-R3, NFR-R6, NFR-U8]
---

# Story 2.4 : Gestion des interruptions iOS et mode économie batterie

## User Story

En tant que Nico,
je veux que l'app gère proprement les appels entrants et les passages en arrière-plan sans perdre de données, et consomme un minimum de batterie,
afin de pouvoir travailler des heures sur le chantier sans stress technique.

## Acceptance Criteria

**Given** Nico est en train d'enregistrer (bouton vert)
**When** un appel entrant interrompt l'audio (`AVAudioSession.interruptionNotification` `.began`)
**Then** l'enregistrement s'arrête proprement, la transcription partielle est sauvegardée en SwiftData
**And** `ModeChantierState.boutonVert = false`
**And** un toast "Enregistrement interrompu" s'affiche

**Given** l'appel est terminé
**When** Nico revient sur l'app (`AVAudioSession.interruptionNotification` `.ended`)
**Then** un toast non-bloquant propose : "Reprendre l'enregistrement ?"
**And** l'état de la session est restauré en ≤ 3 secondes (NFR-R6)

**Given** Nico appuie sur le bouton Home en cours d'enregistrement
**When** l'app passe en arrière-plan (`scenePhase == .background`)
**Then** même traitement que l'interruption audio : arrêt propre + sauvegarde + `boutonVert = false`
**And** aucune donnée n'est perdue (NFR-R3)

**Given** Nico est en Mode Chantier
**When** le mode économie batterie est actif (FR60)
**Then** l'écran est sombre (`#0C0C0E`), luminosité minimale, aucun polling réseau
**And** la consommation de batterie est ≤ 5% par heure d'usage actif (NFR-P10)
**And** le BigButton reste localisable en ≤ 2 secondes sans visibilité sur l'écran — position fixe, taille ≥ 120×120pt (NFR-U8)

## Technical Notes

**Gestion de l'interruption AVAudioSession :**
```swift
// Dans AudioEngine.swift
NotificationCenter.default.addObserver(
    forName: AVAudioSession.interruptionNotification,
    object: nil,
    queue: .main
) { [weak self] notification in
    guard let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey]
        as? AVAudioSession.InterruptionType else { return }

    switch type {
    case .began:
        self?.handleInterruptionBegan()  // arrêt propre + sauvegarde
    case .ended:
        self?.handleInterruptionEnded()  // toast "Reprendre ?"
    @unknown default: break
    }
}
```

**Gestion arrière-plan (`scenePhase`) :**
```swift
// Dans ModeChantierView
@Environment(\.scenePhase) var scenePhase

.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .background && audioEngine.isRecording {
        viewModel.stopRecordingOnBackground()
    }
}
```

**Mode économie batterie — implémentation :**
```swift
// Dans ModeChantierView
.onAppear {
    UIApplication.shared.isIdleTimerDisabled = true  // empêche la mise en veille
    // Pas de polling réseau — tout est offline
    // Luminosité minimale gérée par UIScreen.main.brightness = 0.1
    // mais uniquement si l'utilisateur active explicitement le mode éco
}
```

**Persistance sous interruption (NFR-R3) :**
Lors de `handleInterruptionBegan()`, appeler `audioEngine.stop()` puis immédiatement `modelContext.save()`. La transcription partielle doit être écrite avant que l'app perde la priorité CPU.

**Toast "Reprendre l'enregistrement ?" :**
- Overlay non-bloquant avec bouton [Reprendre] et auto-dismiss après 10 secondes
- Si l'utilisateur ne répond pas dans 10s, le toast disparaît sans reprendre l'enregistrement
- L'enregistrement NE redémarre JAMAIS automatiquement (action utilisateur requise)

**Structure du toast de reprise :**
```swift
// Toast avec action
struct ResumeToast: View {
    var onResume: () -> Void
    var body: some View {
        HStack {
            Text("Enregistrement interrompu")
            Button("Reprendre") { onResume() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
```

**Mode économie batterie (FR60) :**
Activé automatiquement dès l'entrée en Mode Chantier :
- `#0C0C0E` background déjà défini
- Pas d'animations superflues
- `UIApplication.shared.isIdleTimerDisabled = true` — l'écran reste allumé
- Aucun timer réseau, aucun fetch background
- BigButton en position fixe centrale (taille ≥ 120pt) garantit localisation sans regarder l'écran

**Fichiers à modifier :**
- `Services/AudioEngine.swift` : observer `interruptionNotification`, méthode `handleInterruptionBegan/Ended`
- `Views/ModeChantier/ModeChantierView.swift` : observer `scenePhase`, afficher toast reprise
- `ViewModels/ModeChantierViewModel.swift` : méthode `stopRecordingOnBackground()`

## Tasks

- [ ] Implémenter observer `AVAudioSession.interruptionNotification` dans `AudioEngine.swift`
- [ ] Implémenter `handleInterruptionBegan()` : arrêt propre + `modelContext.save()` + `boutonVert = false`
- [ ] Implémenter `handleInterruptionEnded()` : toast non-bloquant "Reprendre l'enregistrement ?"
- [ ] Implémenter observer `scenePhase == .background` dans `ModeChantierView`
- [ ] Appeler `stopRecordingOnBackground()` dans le ViewModel lors du passage en arrière-plan
- [ ] Implémenter `UIApplication.shared.isIdleTimerDisabled = true` à l'entrée en Mode Chantier
- [ ] Implémenter `isIdleTimerDisabled = false` à la sortie du Mode Chantier
- [ ] Vérifier qu'aucune donnée n'est perdue lors d'une interruption (NFR-R3)
- [ ] Vérifier la restauration d'état en ≤ 3 secondes après interruption (NFR-R6)
- [ ] Vérifier que le BigButton est localisable en ≤ 2s sans regarder l'écran (NFR-U8)
- [ ] Créer `GestionTravauxTests/ViewModels/ModeChantierViewModelInterruptionTests.swift`
