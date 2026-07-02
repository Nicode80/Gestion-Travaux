// Color+Travaux.swift
// Gestion Travaux
//
// Story 8.5: design-system colors as static constants.
// Views used to write Color(hex: Constants.Couleurs.x) — re-parsing the hex
// string at every body evaluation (236 call sites). The hex values stay in
// Constants.Couleurs (single source of truth); these constants parse them once.
//
// Naming matches Constants.Couleurs, except `accent` → `accentPrincipal` to
// avoid colliding with the asset-catalog generated `Color.accent` symbol.

import SwiftUI

extension Color {
    static let backgroundBureau   = Color(hex: Constants.Couleurs.backgroundBureau)
    static let backgroundCard     = Color(hex: Constants.Couleurs.backgroundCard)
    static let backgroundChantier = Color(hex: Constants.Couleurs.backgroundChantier)
    static let accentPrincipal    = Color(hex: Constants.Couleurs.accent)
    static let textePrimaire      = Color(hex: Constants.Couleurs.textePrimaire)
    static let texteSecondaire    = Color(hex: Constants.Couleurs.texteSecondaire)
    static let alerte             = Color(hex: Constants.Couleurs.alerte)
    static let astuce             = Color(hex: Constants.Couleurs.astuce)
    static let astuceImportante   = Color(hex: Constants.Couleurs.astuceImportante)
    static let astuceUtile        = Color(hex: Constants.Couleurs.astuceUtile)
    static let achat              = Color(hex: Constants.Couleurs.achat)
}
