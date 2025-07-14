//
//  APIClient.swift
//  APIClient
//
//  Created by apple on 03/10/23.
//

import Foundation

class APIClient {
    
    static func multipart<T: Codable>(url: String, queryItems: [URLQueryItem] = [], headers: [String: String] = [:], body: Encodable?, httpMethod: HTTPMethod, token: String?, structure: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        
        guard NetworkMonitor.shared.isReachable else {
            completion(.failure(APIError.noInternet))
            return
        }
        
        guard let url = URL(string: url) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        
        if queryItems.isEmpty == false {
            urlRequest.url?.append(queryItems: queryItems)
        }
        
        for header in headers {
            urlRequest.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        if let token = token, token != "" {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                let multipartRequest = try MultipartRequest(dictionary: body.dictionary)
                urlRequest.addValue(multipartRequest.httpContentTypeHeadeValue, forHTTPHeaderField: "Content-Type")
                urlRequest.addValue("\(multipartRequest.httpBody.count)", forHTTPHeaderField: "Content-Length")
                urlRequest.httpBody = multipartRequest.httpBody
            } catch let error {
                completion(.failure(error))
                return
            }
        } else {
            urlRequest.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        }
        
        urlRequest.httpMethod = httpMethod.rawValue
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300 // Wait up to 5 mins for response
        
        let task = URLSession(configuration: config).dataTask(with: urlRequest) { data, response, error in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.httpUrlResponse))
                return
            }
            
            guard 200..<300 ~= httpResponse.statusCode else {
                do {
                    if let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        completion(.failure(APIError.dictionary(httpResponse.statusCode, dictionary)))
                    } else {
                        completion(.failure(APIError.badResponse(httpResponse.statusCode)))
                    }
                } catch let error {
                    completion(.failure(error))
                }
                return
            }
            
            do {
                let result = try JSONDecoder().decode(structure, from: data)
                completion(.success(result))
            } catch let DecodingError.dataCorrupted(context) {
                completion(.failure(self.getDecodingError(context: context)))
            } catch let DecodingError.keyNotFound(key, context) {
                completion(.failure(self.getDecodingError(key: key, context: context)))
            } catch let DecodingError.valueNotFound(value, context) {
                completion(.failure(self.getDecodingError(value: value, context: context)))
            } catch let DecodingError.typeMismatch(type, context)  {
                completion(.failure(self.getDecodingError(type: type, context: context)))
            } catch {
                completion(.failure(error))
            }
            
        }
        
        task.resume()
        
    }
    
    static func multipart<T: Codable>(url: String, queryItems: [URLQueryItem] = [], headers: [String: String] = [:], body: Encodable?, httpMethod: HTTPMethod, token: String?, structure: T.Type) async throws -> T {
        
        guard NetworkMonitor.shared.isReachable else {
            throw APIError.noInternet
        }
        
        guard let url = URL(string: url) else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        
        if queryItems.isEmpty == false {
            urlRequest.url?.append(queryItems: queryItems)
        }
        
        for header in headers {
            urlRequest.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        if let token = token, token != "" {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            let multipartRequest = try MultipartRequest(dictionary: body.dictionary)
            urlRequest.addValue(multipartRequest.httpContentTypeHeadeValue, forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("\(multipartRequest.httpBody.count)", forHTTPHeaderField: "Content-Length")
            urlRequest.httpBody = multipartRequest.httpBody
        } else {
            urlRequest.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        }
        
        urlRequest.httpMethod = httpMethod.rawValue
        
        do {
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.httpUrlResponse
            }
            
            guard 200..<300 ~= httpResponse.statusCode else {
                do {
                    if let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        throw APIError.dictionary(httpResponse.statusCode, dictionary)
                    } else {
                        throw APIError.badResponse(httpResponse.statusCode)
                    }
                } catch let error {
                    throw error
                }
            }
            
            do {
                return try JSONDecoder().decode(structure, from: data)
            } catch let DecodingError.dataCorrupted(context) {
                throw self.getDecodingError(context: context)
            } catch let DecodingError.keyNotFound(key, context) {
                throw self.getDecodingError(key: key, context: context)
            } catch let DecodingError.valueNotFound(value, context) {
                throw self.getDecodingError(value: value, context: context)
            } catch let DecodingError.typeMismatch(type, context)  {
                throw self.getDecodingError(type: type, context: context)
            } catch {
                throw error
            }
            
        } catch let error {
            throw error
        }
        
    }
    
    static func json<T: Codable>(url: String, queryItems: [URLQueryItem] = [], headers: [String: String] = [:], body: Encodable?, httpMethod: HTTPMethod, token: String?, structure: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        
        guard NetworkMonitor.shared.isReachable else {
            completion(.failure(APIError.noInternet))
            return
        }
        
        guard let url = URL(string: url) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        
        if queryItems.isEmpty == false {
            urlRequest.url?.append(queryItems: queryItems)
        }
        
        for header in headers {
            urlRequest.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        urlRequest.httpMethod = httpMethod.rawValue
        
        if let token = token, token != "" {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                let httpBody = try JSONEncoder().encode(body)
                urlRequest.httpBody = httpBody
            } catch {
                completion(.failure(APIError.jsonEncoder))
                return
            }
        }
        
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.httpUrlResponse))
                return
            }
        
            
            guard 200..<300 ~= httpResponse.statusCode else {
                do {
                    if let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        completion(.failure(APIError.dictionary(httpResponse.statusCode, dictionary)))
                    } else {
                        completion(.failure(APIError.badResponse(httpResponse.statusCode)))
                    }
                } catch let error {
                    completion(.failure(error))
                }
                return
            }
            
            do {
                let result = try JSONDecoder().decode(structure, from: data)
                completion(.success(result))
            } catch let DecodingError.dataCorrupted(context) {
                completion(.failure(self.getDecodingError(context: context)))
            } catch let DecodingError.keyNotFound(key, context) {
                completion(.failure(self.getDecodingError(key: key, context: context)))
            } catch let DecodingError.valueNotFound(value, context) {
                completion(.failure(self.getDecodingError(value: value, context: context)))
            } catch let DecodingError.typeMismatch(type, context)  {
                completion(.failure(self.getDecodingError(type: type, context: context)))
            } catch {
                completion(.failure(error))
            }
            
        }
        
        task.resume()
        
    }
    
    static func data(url: String, queryItems: [URLQueryItem] = [], headers: [String: String] = [:], body: Encodable? = nil, httpMethod: HTTPMethod, token: String?, completion: @escaping (Result<Data, Error>) -> Void) {
        
        guard NetworkMonitor.shared.isReachable else {
            completion(.failure(APIError.noInternet))
            return
        }
        
        guard var urlComponents = URLComponents(string: url) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }
        
        guard let finalURL = urlComponents.url else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = httpMethod.rawValue
        
        headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        urlRequest.setValue("application/pdf", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = token, !token.isEmpty {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                urlRequest.httpBody = try JSONEncoder().encode(body)
            } catch {
                completion(.failure(APIError.jsonEncoder))
                return
            }
        }
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.httpUrlResponse))
                return
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                completion(.failure(APIError.badResponse(httpResponse.statusCode)))
                return
            }

            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }

            completion(.success(data))
        }
        
        task.resume()
    }
    
    static func json<T: Codable>(url: String, queryItems: [URLQueryItem] = [], headers: [String: String] = [:], body: Encodable?, httpMethod: HTTPMethod, token: String?, structure: T.Type) async throws -> T {
        
        guard NetworkMonitor.shared.isReachable else {
            throw APIError.noInternet
        }
        
        guard let url = URL(string: url) else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        
        if queryItems.isEmpty == false {
            urlRequest.url?.append(queryItems: queryItems)
        }
        
        for header in headers {
            urlRequest.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        urlRequest.httpMethod = httpMethod.rawValue
        
        if let token = token, token != "" {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                let httpBody = try JSONEncoder().encode(body)
                urlRequest.httpBody = httpBody
            } catch {
                throw APIError.jsonEncoder
            }
        }
        
        do {
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.httpUrlResponse
            }
            
            guard 200..<300 ~= httpResponse.statusCode else {
                do {
                    if let dictionary = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] {
                        throw APIError.dictionary(httpResponse.statusCode, dictionary)
                    } else {
                        throw APIError.badResponse(httpResponse.statusCode)
                    }
                } catch let error {
                    throw error
                }
            }
            
            do {
                return try JSONDecoder().decode(structure, from: data)
            } catch let DecodingError.dataCorrupted(context) {
                throw self.getDecodingError(context: context)
            } catch let DecodingError.keyNotFound(key, context) {
                throw self.getDecodingError(key: key, context: context)
            } catch let DecodingError.valueNotFound(value, context) {
                throw self.getDecodingError(value: value, context: context)
            } catch let DecodingError.typeMismatch(type, context)  {
                throw self.getDecodingError(type: type, context: context)
            } catch {
                throw error
            }
            
        } catch let error {
            throw error
        }
        
    }
    
    class private func getDecodingError(key: CodingKey? = nil, value: Any? = nil, type: Any? = nil, context: DecodingError.Context) -> Error {
        var message: String = ""
        if let key = key {
            message = "Key \(key) not found \(context.debugDescription) codingPath \(context.codingPath)"
        } else if let value = value {
            message = "Value \(value) not found \(context.debugDescription) codingPath \(context.codingPath)"
        } else if let type = type {
            message = "Type \(type) mismatch \(context.debugDescription) codingPath \(context.codingPath)"
        } else {
            message = "Data corrupted \(context)"
        }
        return APIError.jsonDecoder(message)
    }

}
