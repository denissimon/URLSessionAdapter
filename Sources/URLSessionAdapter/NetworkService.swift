//
//  NetworkService.swift
//  https://github.com/denissimon/URLSessionAdapter
//
//  Created by Denis Simon on 19/12/2020.
//
//  MIT License (https://github.com/denissimon/URLSessionAdapter/blob/main/LICENSE)
//

import Foundation

public struct NetworkError: Error {
    public let error: Error?
    public let statusCode: Int?
    public let data: Data?
    
    public init(error: Error? = nil, statusCode: Int? = nil, data: Data? = nil) {
        self.error = error
        self.statusCode = statusCode
        self.data = data
    }
}

public protocol NetworkServiceAsyncAwaitType {
    var urlSession: URLSession { get }
    
    func request(_ endpoint: EndpointType, uploadTask: Bool) async throws -> Data
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool) async throws -> T
    func fetchFile(url: URL) async throws -> Data?
    func downloadFile(url: URL, to localUrl: URL) async throws -> Bool
    
    func requestWithStatusCode(_ endpoint: EndpointType, uploadTask: Bool) async throws -> (result: Data, statusCode: Int?)
    func requestWithStatusCode<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool) async throws -> (result: T, statusCode: Int?)
    func fetchFileWithStatusCode(url: URL) async throws -> (result: Data?, statusCode: Int?)
    func downloadFileWithStatusCode(url: URL, to localUrl: URL) async throws -> (result: Bool, statusCode: Int?)
}

public protocol NetworkServiceCallbacksType {
    var urlSession: URLSession { get }
    
    func request(_ endpoint: EndpointType, uploadTask: Bool, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable?
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable?
    func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable?
    func downloadFile(url: URL, to localUrl: URL, completion: @escaping (Result<Bool, NetworkError>) -> Void) -> NetworkCancellable?
    
    func requestWithStatusCode(_ endpoint: EndpointType, uploadTask: Bool, completion: @escaping (Result<(result: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
    func requestWithStatusCode<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool, completion: @escaping (Result<(result: T, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
    func fetchFileWithStatusCode(url: URL, completion: @escaping ((result: Data?, statusCode: Int?)) -> Void) -> NetworkCancellable?
    func downloadFileWithStatusCode(url: URL, to localUrl: URL, completion: @escaping (Result<(result: Bool, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
}

public typealias NetworkServiceType = NetworkServiceAsyncAwaitType & NetworkServiceCallbacksType

@available(macOS 12.0, *)
open class NetworkService: NetworkServiceType {
       
    public private(set) var urlSession: URLSession
    
    public init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    private func log(_ str: String) {
        #if DEBUG
        print(str)
        #endif
    }
    
    // MARK: - async/await API
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    public func request(_ endpoint: EndpointType, uploadTask: Bool = false) async throws -> Data {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw NetworkError()
        }
        
        var request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        var msg = "\nNetworkService request \(endpoint.method.rawValue)"
        if uploadTask { msg += ", uploadTask"}
        msg += ", url: \(url)"
        
        switch uploadTask {
        case false:
            log(msg)
            let (responseData, _) = try await urlSession.data(
                for: request
            )
            return responseData
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                throw NetworkError()
            }
            log(msg)
            request.httpBody = nil
            let (responseData, _) = try await urlSession.upload(
                for: request,
                from: httpBody
            )
            return responseData
        }
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    public func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool = false) async throws -> T {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw NetworkError()
        }
        
        var request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        var msg = "\nNetworkService request<T: Decodable> \(endpoint.method.rawValue)"
        if uploadTask { msg += ", uploadTask"}
        msg += ", url: \(url)"
        
        switch uploadTask {
        case false:
            log(msg)
            let (responseData, response) = try await urlSession.data(
                for: request
            )
            
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode
            
            guard let decoded = ResponseDecodable.decode(type, data: responseData) else {
                throw NetworkError(statusCode: statusCode, data: responseData)
            }
            
            return decoded
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                throw NetworkError()
            }
            log(msg)
            request.httpBody = nil
            let (responseData, response) = try await urlSession.upload(
                for: request,
                from: httpBody
            )
            
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode
            
            guard let decoded = ResponseDecodable.decode(type, data: responseData) else {
                throw NetworkError(statusCode: statusCode, data: responseData)
            }
            
            return decoded
        }
    }
    
    /// Fetches a file into memory
    public func fetchFile(url: URL) async throws -> Data? {
        log("\nNetworkService fetchFile: \(url)")
        
        let (responseData, _) = try await urlSession.data(from: url)
        
        guard !responseData.isEmpty else {
            return nil
        }
        return responseData
    }
    
    /// Downloads a file to disk, and supports background downloads.
    /// - Returns:.success(true), if successful
    public func downloadFile(url: URL, to localUrl: URL) async throws -> Bool {
        log("\nNetworkService downloadFile, url: \(url), to: \(localUrl)")
        
        let (tempLocalUrl, response) = try await urlSession.download(from: url)
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        
        do {
            if !FileManager().fileExists(atPath: localUrl.path) {
                try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
            }
            return true
        } catch {
            throw NetworkError(statusCode: statusCode)
        }
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    public func requestWithStatusCode(_ endpoint: EndpointType, uploadTask: Bool = false) async throws -> (result: Data, statusCode: Int?) {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw NetworkError()
        }
        
        var request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        var msg = "\nNetworkService requestWithStatusCode \(endpoint.method.rawValue)"
        if uploadTask { msg += ", uploadTask"}
        msg += ", url: \(url)"
        
        switch uploadTask {
        case false:
            log(msg)
            let (responseData, response) = try await urlSession.data(
                for: request
            )
            
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode
            
            return (responseData, statusCode)
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                throw NetworkError()
            }
            log(msg)
            request.httpBody = nil
            let (responseData, response) = try await urlSession.upload(
                for: request,
                from: httpBody
            )
            
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode
            
            return (responseData, statusCode)
        }
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    public func requestWithStatusCode<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool = false) async throws -> (result: T, statusCode: Int?) {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw NetworkError()
        }
        
        var request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        var msg = "\nNetworkService requestWithStatusCode<T: Decodable> \(endpoint.method.rawValue)"
        if uploadTask { msg += ", uploadTask"}
        msg += ", url: \(url)"
        
        switch uploadTask {
        case false:
            log(msg)
            let (responseData, response) = try await urlSession.data(
                for: request
            )
            
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode
            
            guard let decoded = ResponseDecodable.decode(type, data: responseData) else {
                throw NetworkError(statusCode: statusCode, data: responseData)
            }
            
            return (decoded, statusCode)
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                throw NetworkError()
            }
            log(msg)
            request.httpBody = nil
            let (responseData, response) = try await urlSession.upload(
                for: request,
                from: httpBody
            )
            
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode
            
            guard let decoded = ResponseDecodable.decode(type, data: responseData) else {
                throw NetworkError(statusCode: statusCode, data: responseData)
            }
            
            return (decoded, statusCode)
        }
    }
    
    /// Fetches a file into memory
    public func fetchFileWithStatusCode(url: URL) async throws -> (result: Data?, statusCode: Int?) {
        log("\nNetworkService fetchFileWithStatusCode: \(url)")
        
        let (responseData, response) = try await urlSession.data(from: url)
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        
        guard !responseData.isEmpty else {
            return (nil, statusCode)
        }
        
        return (responseData, statusCode)
    }
    
    /// Downloads a file to disk, and supports background downloads.
    /// - Returns:.success(true), if successful
    public func downloadFileWithStatusCode(url: URL, to localUrl: URL) async throws -> (result: Bool, statusCode: Int?) {
        log("\nNetworkService downloadFileWithStatusCode, url: \(url), to: \(localUrl)")
        
        let (tempLocalUrl, response) = try await urlSession.download(from: url)
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        
        do {
            if !FileManager().fileExists(atPath: localUrl.path) {
                try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
            }
            return (true, statusCode)
        } catch {
            throw NetworkError(statusCode: statusCode)
        }
    }
    
    // MARK: - callbacks API
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    public func request(_ endpoint: EndpointType, uploadTask: Bool = false, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError()))
            return nil
        }
        
        var request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        var msg = "\nNetworkService request \(endpoint.method.rawValue)"
        if uploadTask { msg += ", uploadTask"}
        msg += ", url: \(url)"
        
        switch uploadTask {
        case false:
            log(msg)
            let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
                if error == nil {
                    completion(.success(data))
                    return
                }
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            dataTask.resume()
            return dataTask
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                completion(.failure(NetworkError()))
                return nil
            }
            log(msg)
            request.httpBody = nil
            
            let uploadTask = urlSession.uploadTask(with: request, from: httpBody) { (data, response, error) in
                if error == nil {
                    completion(.success(data))
                    return
                }
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            uploadTask.resume()
            return uploadTask
        }
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    public func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool = false, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError()))
            return nil
        }
        
        var request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        var msg = "\nNetworkService request<T: Decodable> \(endpoint.method.rawValue)"
        if uploadTask { msg += ", uploadTask"}
        msg += ", url: \(url)"
        
        switch uploadTask {
        case false:
            log(msg)
            let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                if error == nil {
                    guard let data = data, let decoded = ResponseDecodable.decode(type, data: data) else {
                        completion(.failure(NetworkError(statusCode: statusCode, data: data)))
                        return
                    }
                    completion(.success(decoded))
                    return
                }
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            dataTask.resume()
            return dataTask
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                completion(.failure(NetworkError()))
                return nil
            }
            log(msg)
            request.httpBody = nil
            
            let uploadTask = urlSession.uploadTask(with: request, from: httpBody) { (data, response, error) in
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                if error == nil {
                    guard let data = data, let decoded = ResponseDecodable.decode(type, data: data) else {
                        completion(.failure(NetworkError(statusCode: statusCode, data: data)))
                        return
                    }
                    completion(.success(decoded))
                    return
                }
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            uploadTask.resume()
            return uploadTask
        }
    }
    
    /// Fetches a file into memory
    public func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable? {
        let request = RequestFactory.request(url: url, method: .GET, params: nil)
        log("\nNetworkService fetchFile: \(url)")
       
        let dataTask = urlSession.dataTask(with: request) { (data, _, error) in
            guard let data = data, !data.isEmpty, error == nil else {
                completion(nil)
                return
            }
            completion(data)
        }
       
        dataTask.resume()
       
        return dataTask
    }
    
    /// Downloads a file to disk, and supports background downloads.
    /// - Returns:.success(true), if successful
    public func downloadFile(url: URL, to localUrl: URL, completion: @escaping (Result<Bool, NetworkError>) -> Void) -> NetworkCancellable? {
        let request = RequestFactory.request(url: url, method: .GET, params: nil)
        log("\nNetworkService downloadFile, url: \(url), to: \(localUrl)")
        
        let downloadTask = urlSession.downloadTask(with: request) { (tempLocalUrl, response, error) in
            let response = response as? HTTPURLResponse
            let statusCode = response?.statusCode
            guard let tempLocalUrl = tempLocalUrl, error == nil, statusCode != 404 else {
                completion(.failure(NetworkError(error: error, statusCode: statusCode)))
                return
            }
            do {
                if !FileManager().fileExists(atPath: localUrl.path) {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                }
                completion(.success(true))
            } catch {
                completion(.failure(NetworkError(error: error, statusCode: statusCode)))
            }
        }
        
        downloadTask.resume()
        
        return downloadTask
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    public func requestWithStatusCode(_ endpoint: EndpointType, uploadTask: Bool = false, completion: @escaping (Result<(result: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError()))
            return nil
        }
        
        var request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        var msg = "\nNetworkService requestWithStatusCode \(endpoint.method.rawValue)"
        if uploadTask { msg += ", uploadTask"}
        msg += ", url: \(url)"
        
        switch uploadTask {
        case false:
            log(msg)
            let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                
                if error == nil {
                    completion(.success((data, statusCode)))
                    return
                }
                
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            dataTask.resume()
            return dataTask
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                completion(.failure(NetworkError()))
                return nil
            }
            log(msg)
            request.httpBody = nil
            
            let uploadTask = urlSession.uploadTask(with: request, from: httpBody) { (data, response, error) in
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                
                if error == nil {
                    completion(.success((data, statusCode)))
                    return
                }
                
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            uploadTask.resume()
            return uploadTask
        }
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    public func requestWithStatusCode<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool = false, completion: @escaping (Result<(result: T, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError()))
            return nil
        }
        
        var request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        var msg = "\nNetworkService requestWithStatusCode<T: Decodable> \(endpoint.method.rawValue)"
        if uploadTask { msg += ", uploadTask"}
        msg += ", url: \(url)"
        
        switch uploadTask {
        case false:
            log(msg)
            let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                
                if error == nil {
                    guard let data = data, let decoded = ResponseDecodable.decode(type, data: data) else {
                        completion(.failure(NetworkError(statusCode: statusCode, data: data)))
                        return
                    }
                    completion(.success((decoded, statusCode)))
                    return
                }
                
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            dataTask.resume()
            return dataTask
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                completion(.failure(NetworkError()))
                return nil
            }
            log(msg)
            request.httpBody = nil
            
            let uploadTask = urlSession.uploadTask(with: request, from: httpBody) { (data, response, error) in
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                
                if error == nil {
                    guard let data = data, let decoded = ResponseDecodable.decode(type, data: data) else {
                        completion(.failure(NetworkError(statusCode: statusCode, data: data)))
                        return
                    }
                    completion(.success((decoded, statusCode)))
                    return
                }
                
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            uploadTask.resume()
            return uploadTask
        }
    }
    
    /// Fetches a file into memory
    public func fetchFileWithStatusCode(url: URL, completion: @escaping ((result: Data?, statusCode: Int?)) -> Void) -> NetworkCancellable? {
        let request = RequestFactory.request(url: url, method: .GET, params: nil)
        log("\nNetworkService fetchFileWithStatusCode: \(url)")
     
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            let response = response as? HTTPURLResponse
            let statusCode = response?.statusCode
            
            guard let data = data, !data.isEmpty, error == nil else {
                completion((nil, statusCode))
                return
            }
            
            completion((data, statusCode))
        }
        
        dataTask.resume()
        
        return dataTask
    }
    
    /// Downloads a file to disk, and supports background downloads.
    /// - Returns:.success(true), if successful
    public func downloadFileWithStatusCode(url: URL, to localUrl: URL, completion: @escaping (Result<(result: Bool, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        let request = RequestFactory.request(url: url, method: .GET, params: nil)
        log("\nNetworkService downloadFileWithStatusCode, url: \(url), to: \(localUrl)")
        
        let downloadTask = urlSession.downloadTask(with: request) { (tempLocalUrl, response, error) in
            let response = response as? HTTPURLResponse
            let statusCode = response?.statusCode
            guard let tempLocalUrl = tempLocalUrl, error == nil, statusCode != 404 else {
                completion(.failure(NetworkError(error: error, statusCode: statusCode)))
                return
            }
            do {
                if !FileManager().fileExists(atPath: localUrl.path) {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                }
                completion(.success((true, statusCode)))
            } catch {
                completion(.failure(NetworkError(error: error, statusCode: statusCode)))
            }
        }
        
        downloadTask.resume()
        
        return downloadTask
    }
}

public protocol NetworkCancellable {
    func cancel()
}

extension URLSessionDataTask: NetworkCancellable {}
extension URLSessionDownloadTask: NetworkCancellable {}
