// CameraPickerView.swift
// Gestion Travaux
//
// Story 2.3: UIViewControllerRepresentable wrapping UIImagePickerController in camera mode.
// Presented as a .sheet from ModeChantierView when the user taps [📷 Photo].
// The captured UIImage is returned via a @Binding; the sheet is then dismissed automatically.
// Audio continues during camera use because AVAudioSession uses .mixWithOthers.

import SwiftUI
import UIKit

struct CameraPickerView: UIViewControllerRepresentable {

    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        private let parent: CameraPickerView

        init(_ parent: CameraPickerView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
