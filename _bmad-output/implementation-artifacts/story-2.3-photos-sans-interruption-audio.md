---
story: "2.3"
epic: 2
title: "Photos intercalées sans interruption audio"
status: pending
frs: [FR5, FR6, FR58]
nfrs: [NFR-P7, NFR-R4, NFR-U4]
---

# Story 2.3 : Photos intercalées sans interruption audio

## User Story

En tant que Nico,
je veux prendre des photos pendant un enregistrement vocal sans interrompre la capture audio,
afin de documenter visuellement ce que je décris verbalement dans un seul bloc cohérent.

## Acceptance Criteria

**Given** Nico est en train d'enregistrer (bouton vert)
**When** il appuie sur [📷 Photo]
**Then** la photo est prise sans interrompre l'enregistrement audio (interruption < 200ms, NFR-P7)
**And** un PhotoBlock est inséré dans le `ContentBlock[]` de la CaptureEntity en cours, à la position chronologique courante (FR6)
**And** la photo est stockée dans `Documents/captures/` — jamais dans la bibliothèque Photos publique (NFR-S5)

**Given** c'est le premier usage du bouton [📷 Photo]
**When** Nico appuie pour la première fois
**Then** une demande d'autorisation caméra s'affiche : "Caméra requise pour les photos de chantier" (FR58, NFR-S3)

**Given** Nico est en train d'enregistrer (bouton vert)
**When** il appuie sur [📷 Photo]
**Then** un feedback haptique moyen confirme la prise de photo (NFR-U4)
**And** le bouton [📷 Photo] est actif uniquement quand le bouton est vert — inactif si bouton rouge

**Given** Nico a pris 3 photos pendant un même enregistrement
**When** la capture est sauvegardée
**Then** les 3 photos sont correctement liées à la CaptureEntity avec leur timestamp respectif (NFR-R4)
**And** chaque photo peut être retrouvée via son chemin relatif dans `Documents/captures/`

## Technical Notes

**Capture photo sans interruption audio — architecture :**

L'AVAudioSession doit être configuré avec `.mixWithOthers` ou `.allowBluetooth` pour éviter l'interruption lors de l'activation de la caméra. Utiliser `UIImagePickerController` en mode `.camera` ou `AVCaptureSession` en parallèle.

```swift
// Dans AudioEngine.swift — configuration session
audioSession.setCategory(.playAndRecord,
    mode: .default,
    options: [.defaultToSpeaker, .mixWithOthers, .allowBluetooth])
```

**PhotoBlock dans ContentBlock[] :**
```swift
// ContentBlock est Codable (pas @Model) — stocké comme Data JSON dans CaptureEntity
enum BlockType: String, Codable {
    case text, photo
}

struct ContentBlock: Codable {
    let type: BlockType
    let text: String?       // Pour TextBlock
    let photoPath: String?  // Pour PhotoBlock (chemin relatif Documents/captures/)
    let timestamp: Date
}
```

**Stockage photo — chemins :**
```swift
// Dans PhotoService.swift (à créer)
func savePhoto(_ image: UIImage, for captureId: UUID) -> String {
    let filename = "\(captureId)_\(Date().timeIntervalSince1970).jpg"
    let path = "captures/\(filename)"
    let url = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(path)
    image.jpegData(compressionQuality: 0.85)?.write(to: url)
    return path  // Chemin relatif stocké dans PhotoBlock
}
```

**Insertion chronologique dans CaptureEntity :**
La CaptureEntity en cours possède un tableau `contentBlocks: Data` (JSON encodé). À chaque photo prise, décoder, ajouter un PhotoBlock à la position chronologique courante (index = timestamp), ré-encoder et écrire en SwiftData immédiatement.

**Permission caméra :**
```swift
import AVFoundation

func requestCameraPermission() async -> Bool {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .authorized: return true
    case .notDetermined:
        return await AVCaptureDevice.requestAccess(for: .video)
    case .denied, .restricted:
        // Afficher message : "Caméra requise pour les photos de chantier"
        return false
    @unknown default: return false
    }
}
```

**Feedback haptique photo :**
```swift
UIImpactFeedbackGenerator(style: .medium).impactOccurred()
```

**Bouton [📷 Photo] — état conditionnel :**
```swift
// Dans ModeChantierView
Button { viewModel.takePhoto() } label: {
    Label("Photo", systemImage: "camera.fill")
}
.disabled(!chantier.boutonVert)  // Actif uniquement pendant l'enregistrement
```

**Fichiers à créer/modifier :**
- `Services/PhotoService.swift` : sauvegarde photo dans Documents/captures/
- `Views/ModeChantier/ModeChantierView.swift` : activer le bouton [📷 Photo] quand boutonVert
- `ViewModels/ModeChantierViewModel.swift` : méthode `takePhoto()`, permission caméra

## Tasks

- [ ] Créer `Services/PhotoService.swift` : sauvegarde dans `Documents/captures/`, retourne chemin relatif
- [ ] Implémenter demande de permission caméra contextuelle (premier tap, message en français)
- [ ] Implémenter `ModeChantierViewModel.takePhoto()` : capture + insertion PhotoBlock dans ContentBlock[] + sauvegarde SwiftData immédiate
- [ ] Configurer AVAudioSession avec `.mixWithOthers` pour éviter interruption audio lors de la capture photo
- [ ] Activer/désactiver le bouton [📷 Photo] selon l'état `chantier.boutonVert`
- [ ] Implémenter feedback haptique moyen (`UIImpactFeedbackGenerator(style: .medium)`) sur prise de photo
- [ ] Vérifier que l'interruption audio est < 200ms lors de la prise de photo (NFR-P7)
- [ ] Vérifier que chaque photo est bien liée à la CaptureEntity avec son timestamp (NFR-R4)
- [ ] Vérifier que les photos ne sont pas dans la bibliothèque Photos publique
- [ ] Créer `GestionTravauxTests/Services/PhotoServiceTests.swift`
