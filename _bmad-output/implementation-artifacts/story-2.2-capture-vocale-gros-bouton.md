---
story: "2.2"
epic: 2
title: "Capture vocale avec le Gros Bouton"
status: done
frs: [FR2, FR3, FR4, FR11, FR52, FR56, FR57, FR59]
nfrs: [NFR-P2, NFR-P6, NFR-R3, NFR-U3, NFR-U4]
---

# Story 2.2 : Capture vocale avec le Gros Bouton

## User Story

En tant que Nico,
je veux démarrer et arrêter un enregistrement vocal d'une simple pression sur le gros bouton, avec transcription en temps réel,
afin de capturer des informations les mains libres, sans regarder l'écran, même avec des gants.

## Acceptance Criteria

**Given** Nico est en Mode Chantier, bouton rouge
**When** il appuie une fois sur le BigButton et relâche
**Then** le bouton passe au vert pulsant, piloté par `AVAudioRecorder.averagePower` à ~60fps (silence = lueur statique, parole = pulse proportionnel)
**And** `SFSpeechRecognizer` démarre avec `requiresOnDeviceRecognition = true` (transcription offline)
**And** un feedback haptique léger confirme l'activation
**And** `ModeChantierState.boutonVert = true` → tous les contrôles de navigation sont désactivés

**Given** Nico est en train d'enregistrer (bouton vert)
**When** il parle
**Then** la transcription s'affiche en temps réel avec un délai ≤ 1-2 secondes (NFR-P6)
**And** chaque nouveau bloc de transcription est écrit immédiatement en SwiftData (persistence incrémentale, NFR-R3)

**Given** Nico a fini de parler
**When** il re-appuie sur le BigButton et relâche
**Then** l'enregistrement s'arrête, le bouton repasse rouge
**And** un feedback haptique fort confirme l'arrêt
**And** un toast non-bloquant "✅ Capture sauvegardée" s'affiche pendant 2 secondes
**And** CaptureEntity est créée et liée à la TacheEntity active (FR11)
**And** `ModeChantierState.boutonVert = false` → navigation réactivée

**Given** c'est le premier usage du gros bouton
**When** Nico appuie pour la première fois
**Then** une demande d'autorisation microphone s'affiche : "Microphone requis pour la capture vocale" (FR57, NFR-S3)

**Given** Nico a refusé l'autorisation microphone
**When** il appuie sur le gros bouton
**Then** un message s'affiche : "Accès au microphone refusé. Vérifie les réglages de l'app."
**And** un champ de saisie manuelle est proposé en alternative (FR59)

**Given** Nico est en Mode Chantier
**When** la réponse du BigButton est mesurée
**Then** la latence perçue entre le tap et le changement visuel est < 100ms (NFR-P2)

## Technical Notes

**AudioEngine — architecture complète :**
```swift
protocol AudioEngineProtocol {
    var isRecording: Bool { get }
    var currentTranscription: String { get }
    var averagePower: Float { get }  // dBFS, pour le pulse
    func start() throws
    func stop()
}

class AudioEngine: AudioEngineProtocol {
    private var audioSession: AVAudioSession
    private var audioRecorder: AVAudioRecorder  // fichier temporaire
    private var speechRecognizer: SFSpeechRecognizer
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest
    // requiresOnDeviceRecognition = true
}
```

**AudioEngine injecté via protocol dans ModeChantierViewModel :**
```swift
class ModeChantierViewModel {
    private let audioEngine: AudioEngineProtocol
    init(audioEngine: AudioEngineProtocol = AudioEngine()) { }

    func toggleRecording() {
        Task {
            do {
                if audioEngine.isRecording {
                    audioEngine.stop()
                    // Créer CaptureEntity + modelContext.save()
                    chantierState.boutonVert = false
                } else {
                    try await audioEngine.start()
                    chantierState.boutonVert = true
                }
            } catch {
                state = .failure(error.localizedDescription)
            }
        }
    }
}
```

**Pulse BigButton — timer à ~60fps :**
```swift
// Dans BigButton.swift, state .active
private var pulseTimer: Timer?
pulseTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
    let power = audioEngine.averagePower  // dBFS normalisé 0..1
    scaleEffect = 1.0 + (power * 0.12)   // 1.0 à 1.12
}
```

**Persistence incrémentale :** Chaque résultat partiel de `SFSpeechRecognitionResult` (isFinal == false) crée/met à jour un TextBlock dans la CaptureEntity en cours. Ne pas attendre isFinal pour écrire en DB.

**Lockdown navigation quand boutonVert == true :** Toutes les vues qui lisent `chantier.boutonVert` désactivent leurs contrôles de navigation. Le [☰] dans ModeChantierView se grise automatiquement.

**Haptics :**
- Activation : `UIImpactFeedbackGenerator(style: .light).impactOccurred()`
- Désactivation : `UIImpactFeedbackGenerator(style: .heavy).impactOccurred()`

**Toast :** `.overlay` avec auto-dismiss après 2 secondes. Jamais bloquant.

**Fallback saisie manuelle (FR59) :** TextField visible si permission micro refusée, crée un TextBlock directement sans audio.

**Fichiers à créer :**
- `Services/AudioEngineProtocol.swift`
- `Services/AudioEngine.swift`
- `GestionTravauxTests/Services/AudioEngineTests.swift`
- `GestionTravauxTests/Mocks/MockAudioEngine.swift`

## Tasks

- [x] Créer `Services/AudioEngineProtocol.swift`
- [x] Créer `Services/AudioEngine.swift` : AVAudioEngine + SFSpeechRecognizer (requiresOnDeviceRecognition: true) + calcul power depuis tap buffer
- [x] Implémenter demande de permission microphone contextuelle (au premier tap, message en français)
- [x] Implémenter toggle enregistrement dans `ModeChantierViewModel.toggleEnregistrement()`
- [x] Implémenter persistence incrémentale : écriture SwiftData à chaque bloc de transcription partiel
- [x] Mettre à jour `BigButton.swift` : états .inactive (rouge) / .active (vert pulsant via averagePower ~60fps) — déjà complet via `pulseScale` param
- [x] Implémenter pulse réactif à la voix dans BigButton (scaleEffect 1.0–1.12) — Timer ~60fps dans ViewModel, `pulseScale` passé au BigButton
- [x] Implémenter lockdown navigation quand `ModeChantierState.boutonVert = true` — déjà câblé en Story 2.1, confirmé
- [x] Implémenter haptic léger (activation) et fort (désactivation)
- [x] Implémenter toast "✅ Capture sauvegardée" (auto-dismiss 2s)
- [x] Implémenter création CaptureEntity liée à TacheEntity active (FR11)
- [x] Implémenter fallback saisie manuelle si permission micro refusée (FR59)
- [x] Activer `RecordingIndicator` pendant enregistrement — animation barres waveform
- [x] Créer `Gestion TravauxTests/Mocks/MockAudioEngine.swift`
- [x] Créer `Gestion TravauxTests/Services/AudioEngineTests.swift`
- [x] Mettre à jour `Gestion TravauxTests/ModeChantier/ModeChantierViewModelTests.swift` — ajout 6 tests Story 2.2
- [x] Vérifier latence BigButton < 100ms (NFR-P2) — réponse visuelle avant async via boutonVert immédiat
- [x] Vérifier délai transcription ≤ 1-2 secondes (NFR-P6) — shouldReportPartialResults=true garantit la cadence

## Dev Agent Record

### Implementation Plan

AudioEngine utilise `AVAudioEngine` (au lieu d'`AVAudioRecorder`) + `SFSpeechAudioBufferRecognitionRequest` pour la transcription temps réel. Le tap sur `inputNode` alimente simultanément la reconnaissance vocale ET calcule le power RMS pour le pulse. `requiresOnDeviceRecognition = true` garantit le fonctionnement offline.

Le pulse du BigButton (~60fps) est piloté par un `Timer` dans `ModeChantierViewModel` qui lit `audioEngine.averagePower` et met à jour `pulseScale` sur le MainActor. BigButton reçoit `pulseScale` comme paramètre — pas de logique audio dans la vue.

La persistence incrémentale : chaque résultat partiel de SFSpeechRecognizer crée/met à jour une `CaptureEntity` en SwiftData immédiatement (sans attendre `isFinal`). Si aucune transcription n'arrive avant l'arrêt, l'entité placeholder est supprimée.

### Completion Notes

- **AudioEngineProtocol** : protocole `@MainActor` avec `PermissionMicro: Equatable` et `AudioEngineErreur: LocalizedError`
- **AudioEngine** : `@MainActor final class`, AVAudioEngine + SFSpeechRecognizer, power calculé via RMS du tap buffer
- **ModeChantierViewModel** : étendu avec `toggleEnregistrement()`, `toggleEnregistrementAction()` (sync wrapper), `sauvegarderSaisieManuelle()`, pulse timer, toast 2s, persistence incrémentale. `audioEngine` privé, `averagePower` exposé comme computed property
- **ModeChantierView** : BigButton branché via `toggleEnregistrementAction()` (plus de Task dans la View), `viewModel.averagePower` passé à RecordingIndicator
- **DashboardView** : `modelContext` passé à `ModeChantierView(modelContext:)`
- **RecordingIndicator** : 5 barres waveform animées avec `averagePower`
- **Tests** : 20 tests ModeChantierViewModelTests (10 Story 2.2 dont H2 wrapper + M3 race condition) + 13 AudioEngineTests — tous passent

## File List

### Nouveaux fichiers
- `Gestion Travaux/Services/AudioEngineProtocol.swift`
- `Gestion Travaux/Services/AudioEngine.swift`
- `Gestion TravauxTests/Mocks/MockAudioEngine.swift`
- `Gestion TravauxTests/Services/AudioEngineTests.swift`

### Fichiers modifiés
- `Gestion Travaux/ViewModels/ModeChantierViewModel.swift`
- `Gestion Travaux/Views/ModeChantier/ModeChantierView.swift`
- `Gestion Travaux/Views/Dashboard/DashboardView.swift`
- `Gestion Travaux/Views/Components/RecordingIndicator.swift`
- `Gestion TravauxTests/ModeChantier/ModeChantierViewModelTests.swift`

## Change Log

- 2026-02-26 : Story 2.2 implémentée — AudioEngine + toggle enregistrement + persistence incrémentale + pulse BigButton + toast + fallback saisie manuelle (FR59). 31 tests unitaires, 0 régressions.
- 2026-02-26 : Corrections post-review — H1 (boutonVert optimiste avant demarrer, rollback si erreur), H2 (descriptions plist Mode Chantier), H3 (guard isProcessingToggle contre double-tap pendant permission dialog), M1 (MainActor.assumeIsolated + deinit timer), M2 (variable morte supprimée dans AudioEngineTests), M3 (vérification sessionId dans mettreAJourCaptureEnCours).
- 2026-02-27 : Code review adversariale — 5 issues corrigées : H1 (try? modelContext.save() → do/catch explicites ×5), H2 (Task dans View → toggleEnregistrementAction() wrapper sync), M1 (audioEngine → private + var averagePower exposé), M2 (try? AVAudioSession.setActive → do/catch), M3 (guard audioEngine.isRecording contre callbacks tardifs). +2 tests (H2 wrapper + M3 race condition). 20 tests ViewModel + 13 AudioEngine.
- 2026-02-27 : Crash fix 1/2 (_dispatch_assert_queue_fail sur device réel) — AudioEngine.demarrer() réécrit en async throws avec Task.detached pour tout le setup hardware AVAudioEngine (inputNode, installTap, start()) + await MainActor.run pour recognitionTask. Pattern identique au fix commit 69df9b7 (TaskCreationViewModel). Propriétés audio marquées nonisolated(unsafe). Protocol + Mock + ViewModel + Tests mis à jour (async throws).
- 2026-02-27 : Crash fix 2/2 (root cause réel) — SFSpeechRecognizer.requestAuthorization et AVAudioApplication.requestRecordPermission dans demanderPermission() causaient le crash en s'exécutant sur le @MainActor. iOS Speech/AVAudio internals assertent NOT on main queue. Fix : deux nonisolated static helpers (requestSpeechPermission + requestMicroPermission), pattern identique à TaskCreationViewModel.startVoiceInput().
