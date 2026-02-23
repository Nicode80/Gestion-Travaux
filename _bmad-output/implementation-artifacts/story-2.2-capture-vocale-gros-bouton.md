---
story: "2.2"
epic: 2
title: "Capture vocale avec le Gros Bouton"
status: pending
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

- [ ] Créer `Services/AudioEngineProtocol.swift`
- [ ] Créer `Services/AudioEngine.swift` : AVAudioSession + AVAudioRecorder + SFSpeechRecognizer (requiresOnDeviceRecognition: true)
- [ ] Implémenter demande de permission microphone contextuelle (au premier tap, message en français)
- [ ] Implémenter toggle enregistrement dans `ModeChantierViewModel.toggleRecording()`
- [ ] Implémenter persistence incrémentale : écriture SwiftData à chaque bloc de transcription partiel
- [ ] Mettre à jour `BigButton.swift` : états .inactive (rouge) / .active (vert pulsant via averagePower ~60fps)
- [ ] Implémenter pulse réactif à la voix dans BigButton (scaleEffect 1.0–1.12)
- [ ] Implémenter lockdown navigation quand `ModeChantierState.boutonVert = true`
- [ ] Implémenter haptic léger (activation) et fort (désactivation)
- [ ] Implémenter toast "✅ Capture sauvegardée" (auto-dismiss 2s)
- [ ] Implémenter création CaptureEntity liée à TacheEntity active (FR11)
- [ ] Implémenter fallback saisie manuelle si permission micro refusée (FR59)
- [ ] Activer `RecordingIndicator` pendant enregistrement
- [ ] Créer `GestionTravauxTests/Mocks/MockAudioEngine.swift`
- [ ] Créer `GestionTravauxTests/Services/AudioEngineTests.swift`
- [ ] Créer `GestionTravauxTests/ViewModels/ModeChantierViewModelTests.swift`
- [ ] Vérifier latence BigButton < 100ms (NFR-P2)
- [ ] Vérifier délai transcription ≤ 1-2 secondes (NFR-P6)
