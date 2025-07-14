//
//  MultipartRequest.swift
//  APIClient
//
//  Created by apple on 03/10/23.
//

import Foundation
import UIKit

public struct MultipartRequest {
    
    public let boundary: String
    private let separator: String = "\r\n"
    private var data: Data
    
    public init(boundary: String = UUID().uuidString, dictionary: [String: Any]) throws {
        self.boundary = boundary
        self.data = .init()
        try self.setMultipartRequest(dictionary: dictionary)
    }
    
    public var httpContentTypeHeadeValue: String {
        "multipart/form-data; boundary=\(self.boundary)"
    }
    
    public var httpBody: Data {
        var bodyData = self.data
        bodyData.append("--\(self.boundary)--".data(using: .utf8)!)
        return bodyData
    }
    
    private mutating func appendBoundarySeparator() {
        self.data.append("--\(self.boundary)\(self.separator)".data(using: .utf8)!)
    }
    
    private mutating func appendSeparator() {
        self.data.append(self.separator.data(using: .utf8)!)
    }
    
    private func disposition(_ key: String) -> String {
        "Content-Disposition: form-data; name=\"\(key)\""
    }
    
    private mutating func add(key: String, value: String) {
        self.appendBoundarySeparator()
        self.data.append((self.disposition(key) + self.separator).data(using: .utf8)!)
        self.appendSeparator()
        self.data.append((value + self.separator).data(using: .utf8)!)
    }
    
    private mutating func add(key: String, fileName: String, fileMimeType: String, fileData: Data) {
        self.appendBoundarySeparator()
        self.data.append((self.disposition(key) + "; filename=\"\(fileName)\"" + self.separator).data(using: .utf8)!)
        self.data.append(("Content-Type: \(fileMimeType)" + self.separator).data(using: .utf8)!)
        self.appendSeparator()
        self.data.append(fileData)
        self.appendSeparator()
    }
    
    private mutating func setMultipartRequest(dictionary: [String: Any]) throws {
        for (key, value) in dictionary {
           if let array = value as? Array<Any> {
                for (index, value) in array.enumerated() {
                    let key = key + "[\(index)]"
                    try self.addValue(for: key, with: value)
                }
           } else {
               try self.addValue(for: key, with: value)
           }
        }
    }
    
    private mutating func addValue(for key: String, with value: Any) throws {
        if let value = value as? String {
            if self.isValidFileURL(value), let url = URL(string: value) {
                try self.addData(for: key, with: url)
            } else {
                self.add(key: key, value: value)
            }
        } else if let value = value as? Int {
            self.add(key: key, value: "\(value)")
        } else if let value = value as? Double {
            self.add(key: key, value: "\(value)")
        } else if let value = value as? Bool {
            self.add(key: key, value: "\(value)")
        }
    }
    
    private mutating func addData(for key: String, with url: URL) throws {
        do {
            var data = try Data(contentsOf: url)
            if self.isImageURL(url), let image = UIImage(data: data) {
                if let imageData = image.jpegData(compressionQuality: 0.6) {
                    data = imageData
                }
            }
            let name = url.lastPathComponent
            let mimeType = url.mimeType ?? ""
            self.add(key: key, fileName: name, fileMimeType: mimeType, fileData: data)
        } catch let error {
            throw error
        }
    }
    
    private func isValidFileURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        guard url.scheme == "file" else { return false }
        
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: url.path)
    }
    
    private func isImageURL(_ url: URL) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp"]
        let pathExtension = url.pathExtension.lowercased()
        return imageExtensions.contains(pathExtension)
    }
    
}
