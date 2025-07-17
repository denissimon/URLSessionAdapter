//
//  Endpoint.swift
//  https://github.com/denissimon/URLSessionAdapter
//
//  Created by Denis Simon on 19/12/2020.
//
//  MIT License (https://github.com/denissimon/URLSessionAdapter/blob/main/LICENSE)
//

import Foundation

public protocol EndpointType: Sendable {
    var method: HTTPMethod { get }
    var baseURL: String { get }
    var path: String { get set }
    var params: HTTPParams? { get set }
}

public final class Endpoint: EndpointType {
    
    private let lock = NSLock()
    
    public let method: HTTPMethod
    public let baseURL: String
    
    public var path: String {
        get { lock.withLock { _path } }
        set { lock.withLock { _path = newValue } }
    }
    nonisolated(unsafe) private var _path: String
    
    public var params: HTTPParams? {
        get { lock.withLock { _params } }
        set { lock.withLock { _params = newValue } }
    }
    nonisolated(unsafe) private var _params: HTTPParams?
    
    public init(method: HTTPMethod, baseURL: String, path: String, params: HTTPParams?) {
        self.method = method
        self.baseURL = baseURL
        self._path = path
        self._params = params
    }
}
