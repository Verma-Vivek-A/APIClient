//
//  URL.swift
//  CorrectCare
//
//  Created by User1 on 11/11/24.
//

import Foundation
import UniformTypeIdentifiers

extension URL {
    
    var mimeType: String? {
        let fileExtension = self.pathExtension
        guard let uti = UTType(filenameExtension: fileExtension) else {
            return nil
        }
        return uti.preferredMIMEType
    }
    
}
