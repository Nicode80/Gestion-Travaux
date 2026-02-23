// ViewState.swift
// Gestion Travaux
//
// Generic state enum for async ViewModel operations.
// NEVER use isLoading: Bool + errorMessage: String? — use ViewState<T> instead.

import Foundation

enum ViewState<T> {
    case idle
    case loading
    case success(T)
    /// Human-readable error message in French.
    case failure(String)
}
