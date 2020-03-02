//
//  DocumentPickerDelegate.swift
//  OurBeat
//
//  Created by thuyentruong on 11/18/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

protocol DocumentPickerDelegate: AnyObject {
    var lock: NSLock { get }

    // MARK: - Handlers
    func browseFile(fileTypes: [String])
    func didPickDocument(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL)
    func handle(selectedFileURL: URL)
}

extension DocumentPickerDelegate where Self: UIViewController {
    func browseFile(fileTypes: [String]) {
        guard let self = self as? UIDocumentPickerDelegate else { return }

        let documentPickerController = UIDocumentPickerViewController(documentTypes: fileTypes, in: .import)
        documentPickerController.delegate = self
        present(documentPickerController, animated: true, completion: nil)
    }

    func didPickDocument(_: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        guard lock.try() else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let fileCoordinator = NSFileCoordinator()
            var error: NSError?

            fileCoordinator.coordinate(readingItemAt: url, options: [], error: &error) { newURL in
                let filename = newURL.lastPathComponent

                // Fix bug "UIDocumentPickerViewController returns url to a file that does not exist"
                // Reference: https://stackoverflow.com/questions/37109130/uidocumentpickerviewcontroller-returns-url-to-a-file-that-does-not-exist/48007752
                var tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
                tempURL.appendPathComponent(filename)

                do {
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }

                    try FileManager.default.moveItem(at: newURL, to: tempURL)

                    Global.log.info("[start] documentPicker")
                    self.handle(selectedFileURL: tempURL)
                    self.lock.unlock()
                } catch {
                    loadingState.onNext(.hide)
                    Global.log.error(error)
                    self.showErrorAlertWithSupport(message: R.string.error.system())
                }
            }
        }
    }
}
