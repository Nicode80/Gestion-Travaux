// Log.swift
// Gestion Travaux
//
// Centralized os.Logger instances, one per subsystem area.
// Logs are retrievable from Console.app when the device is connected —
// the only way to diagnose field issues on TestFlight builds.
//
// Convention: log messages in English (developer-facing), .error for
// failures that are swallowed or converted to a French user message.

import os

enum Log {
    private nonisolated static let subsystem = "com.gestiontravaux"

    // nonisolated: Logger is Sendable and loggers are called from Task.detached
    // (audio setup, photo sweep) — default MainActor isolation would forbid that.

    /// Audio session, recording, speech recognition.
    nonisolated static let audio = Logger(subsystem: subsystem, category: "audio")
    /// SwiftData saves and fetches.
    nonisolated static let persistence = Logger(subsystem: subsystem, category: "persistence")
    /// Photo files: save, cleanup of orphaned files.
    nonisolated static let photos = Logger(subsystem: subsystem, category: "photos")
    /// Classification, reclassification, checkout.
    nonisolated static let classification = Logger(subsystem: subsystem, category: "classification")
    /// App lifecycle: container setup, launch tasks.
    nonisolated static let app = Logger(subsystem: subsystem, category: "app")
}
