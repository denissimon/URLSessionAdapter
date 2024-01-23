//
//  HTTPParams.swift
//  https://github.com/denissimon/URLSessionAdapter
//
//  Created by Denis Simon on 19/12/2020.
//
//  MIT License (https://github.com/denissimon/URLSessionAdapter/blob/main/LICENSE)
//

import Foundation

struct HTTPParams {
    let httpBody: Data?
    let cachePolicy: URLRequest.CachePolicy?
    let timeoutInterval: TimeInterval?
    let headerValues: [(value: String, forHTTPHeaderField: String)]?
}
