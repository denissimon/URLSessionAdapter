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
    let error: Error?
    let code: Int?
}

open class NetworkService {
       
    let urlSession: URLSession
    
    init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    /// Request API endpoint
    public func requestEndpoint(_ endpoint: EndpointType, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError(error: nil, code: nil)))
            return
        }
        
        let request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        log("\nNetworkService requestEndpoint: \(request.description)")
        
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            let response = response as? HTTPURLResponse
            let status = response?.statusCode
            
            if data != nil && error == nil {
                completion(.success(data!))
                return
            }
            if error != nil {
                completion(.failure(NetworkError(error: error!, code: status)))
            } else {
                completion(.failure(NetworkError(error: nil, code: status)))
            }
        }
        
        dataTask.resume()
    }
    
    /// Request API endpoint with decoding of results in Decodable
    public func requestEndpoint<T: Decodable>(_ endpoint: EndpointType, type: T.Type, completion: @escaping (Result<T, NetworkError>) -> Void) {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError(error: nil, code: nil)))
            return
        }
        
        let request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        log("\nNetworkService requestEndpoint<T: Decodable>: \(request.description)")
        
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            let response = response as? HTTPURLResponse
            let status = response?.statusCode
            
            if data != nil && error == nil {
                let response = ResponseDecodable(data: data!)
                guard let decoded = response.decode(type) else {
                    completion(.failure(NetworkError(error: nil, code: status)))
                    return
                }
                completion(.success(decoded))
                return
            }
            
            if error != nil {
                completion(.failure(NetworkError(error: error!, code: status)))
            } else {
                completion(.failure(NetworkError(error: nil, code: status)))
            }
        }

        dataTask.resume()
    }
    
    public func fetchFile(url: URL, completion: @escaping (Data?) -> Void) {
        let request = RequestFactory.request(url: url, method: .GET, params: nil)
        log("\nNetworkService fetchFile: \(request.description)")
     
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            if data != nil && error == nil {
                completion(data!)
                return
            }
            return completion(nil)
        }
        
        dataTask.resume()
    }
    
    private func log(_ str: String) {
        #if DEBUG
        print(str)
        #endif
    }
}

fileprivate struct ResponseDecodable {
    
    fileprivate var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    public func decode<T: Decodable>(_ type: T.Type) -> T? {
        let jsonDecoder = JSONDecoder()
        do {
            let response = try jsonDecoder.decode(T.self, from: data)
            return response
        } catch _ {
            return nil
        }
    }
}

public enum HTTPHeaderField: String {
    case authentication = "Authorization"
    case contentType = "Content-Type"
    case acceptType = "Accept"
    case acceptEncoding = "Accept-Encoding"
    case string = "String"
}

public enum ContentType: String {
    case json = "application/json"
    case formEncode = "application/x-www-form-urlencoded"
}

