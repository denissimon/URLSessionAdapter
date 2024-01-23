//
//  Endpoint.swift
//  https://github.com/denissimon/URLSessionAdapter
//
//  Created by Denis Simon on 19/12/2020.
//
//  MIT License (https://github.com/denissimon/URLSessionAdapter/blob/main/LICENSE)
//

import Foundation

protocol EndpointType {
    var method: Method { get }
    var path: String { get }
    var baseURL: String { get }
    var params: HTTPParams? { get set }
}

class Endpoint: EndpointType {
    var method: Method
    var baseURL: String
    var path: String
    var params: HTTPParams?
    init(method: Method, baseURL: String, path: String, params: HTTPParams?) {
        self.method = method
        self.baseURL = baseURL
        self.path = path
        self.params = params
    }
}
