// Array+TacheSort.swift
// Gestion Travaux
//
// Sort helper for TacheEntity arrays used by DashboardViewModel and TacheListView.
// Priority: tasks with a lastSessionDate come first (most recent first),
// then tasks without any session date sorted by createdAt descending.

import SwiftData

extension Array where Element == TacheEntity {
    func trieeParSession() -> [TacheEntity] {
        sorted {
            switch ($0.lastSessionDate, $1.lastSessionDate) {
            case let (l?, r?): return l > r
            case (.some, nil): return true
            case (nil, .some): return false
            case (nil, nil):   return $0.createdAt > $1.createdAt
            }
        }
    }
}
