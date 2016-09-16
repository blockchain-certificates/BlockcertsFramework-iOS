//
//  ActionRequestHandler.swift
//  DownloadToCertWallet
//
//  Created by Chris Downie on 9/16/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import UIKit
import MobileCoreServices

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    var extensionContext: NSExtensionContext?
    
    func beginRequest(with context: NSExtensionContext) {
        // Do not call super in an Action extension with no user interface
        self.extensionContext = context
        
        var found = false
        
        // Find the item containing the results from the JavaScript preprocessing.
        outer:
            for item in context.inputItems as! [NSExtensionItem] {
                if let attachments = item.attachments {
                    for itemProvider in attachments as! [NSItemProvider] {
                        // TODO: There's probably a better type identifier for this.
                        let typeIdentifier = String(kUTTypeText)
                        
                        if itemProvider.hasItemConformingToTypeIdentifier(typeIdentifier) {
                            itemProvider.loadItem(forTypeIdentifier: typeIdentifier, options: nil, completionHandler: { (item, error) in
                                print(item)
                                if let url = URL(string:item as! String) {
                                    self.saveCertificate(at: url)
//                                    OperationQueue.main.addOperation {
//                                        self.saveCertificate(at: url)
//                                    }
                                }
                            })
                            found = true
                            break outer
                        }
                    }
                }
        }
        
        if !found {
            self.done()
        }
    }
    
    func done() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        self.extensionContext = nil
    }
    
    func saveCertificate(at url: URL) {
        print("TODO: Save to \(url)")
//        let tempDirectory = URL(string: NSTemporaryDirectory())
//        let tempDestination = URL(fileURLWithPath: "certificate.json", relativeTo: tempDirectory)
//        
//        let downloadTask = URLSession.shared.downloadTask(with: url)
//        downloadTask.
//
//        FileManager.default.creat
//
//        let fileCoordinator = NSFileCoordinator()
//        fileCoordinator.

    }
}
