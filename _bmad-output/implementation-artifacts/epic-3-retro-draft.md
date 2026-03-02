# Rétrospective — Épic 3 : Mode Bureau — Classification et Check-out
**Statut :** En cours (draft — à compléter après stories 3.2 et 3.3)
**Dernière mise à jour :** 2026-03-02

---

## Stories livrées à ce jour

- 3.1 — Liste chronologique des captures non classées ✅ *(+ 3 itérations de debug audio post-livraison)*
- 3.2 — Swipe Game — Classification par direction ⏳
- 3.3 — Récapitulatif, validation et check-out ⏳

---

## Dette technique identifiée

### DT-1 — Affichage non-entrelacé texte/photo dans CaptureCard
**Découverte lors de :** Story 3.1 — tests sur device réel
**Description :** L'architecture actuelle stocke **un seul bloc texte** par capture (tout le speech concaténé), séparé des blocs photo. Pour un workflow "texte → 📷 → texte → 📷", le CaptureCard affiche tout le texte en continu, puis la miniature du premier photo en bas — les photos ne sont pas intercalées dans le flux narratif.

**Architecture actuelle :**
```
Block {type: .text, text: "texte avant photo texte après photo", order: 0}
Block {type: .photo, photoPath: "...", order: 1}
```

**Architecture idéale pour entrelacement :**
```
Block {type: .text, text: "texte avant photo", order: 0}
Block {type: .photo, photoPath: "...", order: 1}
Block {type: .text, text: "texte après photo", order: 2}
```

**Ce qu'il faudrait changer :**
- `mettreAJourCaptureEnCours` : quand une photo est prise, "geler" le bloc texte courant et en créer un nouveau pour le speech suivant (au lieu de toujours mettre à jour le même bloc en place)
- `CaptureCard` : itérer sur tous les blocs dans l'ordre (`.sorted(by: \.order)`) et afficher chaque bloc — `Text` pour `.text`, `PhotoThumbnailView` pour `.photo`
- `CaptureEntity.transcription` : doit concaténer tous les blocs `.text` dans l'ordre pour la rétrocompatibilité

**Impact actuel :** Cosmétique pour Story 3.1 et 3.2 (le texte complet est bien capturé, la classification reste possible). Devient plus visible si l'on ajoute un jour une vue de détail de capture.

**Décision :** Acceptable pour le MVP. À traiter dans une story dédiée (ex: "4.x — Vue détail capture") si le besoin se confirme à l'usage.

---

## Debug audio — Story 3.1 post-livraison (3 itérations)

Le bug "texte avant photo perdu" a requis 3 itérations de correctif après validation sur device :

| Tentative | Problème identifié | Correctif | Résultat |
|-----------|-------------------|-----------|----------|
| Fix 1 | `transcription` (= texteCommis + partial) utilisé comme source pour texteCommis → double-counting | Ajout `dernierePartielle` pour tracker le partial brut séparément | Pas suffisant |
| Fix 2 | `dernierePartielle` géré dans le callback — ne couvre pas le reset intra-session | Commit `dernierePartielle` dans `startEnregistrement` avant redémarrage | Pas suffisant |
| Fix 3 ✅ | SFSpeechRecognizer on-device reset son hypothèse silencieusement après silence (photo) sans déclencher `isFinal` | Détection `texte.count < dernierePartielle.count` dans `mettreAJourCaptureEnCours` — commit automatique avant le nouveau partial | ✅ Résolu |

**Leçon :** Le moteur SFSpeechRecognizer on-device (`requiresOnDeviceRecognition = true`) peut réinitialiser son hypothèse après ~3-5s de silence SANS déclencher `isFinal`. Le signal fiable est la longueur du premier partial après reset, toujours plus courte que le dernier partial de la session précédente.

**Code de référence :** `ModeChantierViewModel.mettreAJourCaptureEnCours()` — commit `c1dfab0`

---

## À compléter après Story 3.3

- Métriques (tests, build fails, issues review)
- Ce qui a bien marché / ce qui était difficile
- Actions pour Épic 4
