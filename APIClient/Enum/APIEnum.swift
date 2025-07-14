//
//  APIEnum.swift
//  APIClient
//
//  Created by apple on 03/10/23.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum APIError: Error {
    case noInternet
    case invalidURL
    case httpUrlResponse
    case badResponse(Int)
    case noData
    case jsonEncoder
    case jsonDecoder(String)
    case error(String)
    case dictionary(Int, [String: Any]) // Int is httpResponse statusCode just in case you need it
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .noInternet:
            return "No internet connection"
        case .invalidURL:
            return "Invalid URL"
        case .httpUrlResponse:
            return "Unable to get http response"
        case let .badResponse(code):
            return "Status code \(code)"
        case .noData:
            return "No data"
        case .jsonEncoder:
            return "Encoding error"
        case let .jsonDecoder(error):
            #if DEBUG
            return "Decoding error \(error)"
            #else
            return "Decoding error"
            #endif
        case let .error(error):
            return error
        case .dictionary(_,_):
            return self.keyValue.value ?? "Couldn't get error from dictionary"
        case .unknown:
            return "Unknown error occured"
        }
    }
    
    var keyValue: (key: [String]?, value: String?) {
        if case let .dictionary(_,dictionary) = self {
            return self.getErrorMessage(dictionary: dictionary)
        }
        return (nil, nil)
    }
    
    private func getErrorMessage(dictionary: [String: Any]) -> (key: [String]?, value: String?) {
        var errorKey: [String] = dictionary.keys.compactMap({ $0 })
        var errorValue: String = ""
        
        for value in dictionary.values  {
            if let dic = value as? [String: Any] {
                for value in dic.values {
                    if let messages = value as? [String], let message = messages.first {
                        errorValue += message
                    } else if let message = value as? String {
                        errorValue += message
                    }
                }
                errorKey.append(contentsOf: dic.keys.compactMap({ $0 }))
            } else if let messages = value as? [String], let message = messages.first {
                errorValue += message
            } else if let message = value as? String {
                errorValue += message
            }
        }
        
        let remove: Set<Character> = ["\n", "\"", "(", ")", "[", "]", "{", "}"]
        errorValue.removeAll(where: { remove.contains($0) })
        
        return (errorKey.isEmpty ? nil : errorKey, errorValue == "" ? nil : errorValue)
    }
    
}
