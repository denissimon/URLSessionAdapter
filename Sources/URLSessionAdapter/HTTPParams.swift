//
//  HTTPParams.swift
//  https://github.com/denissimon/URLSessionAdapter
//
//  Created by Denis Simon on 19/12/2020.
//
//  MIT License (https://github.com/denissimon/URLSessionAdapter/blob/main/LICENSE)
//

import Foundation

/// httpBody can be accepted as Data or Encodable
public struct HTTPParams {
    let httpBody: Any?
    let cachePolicy: URLRequest.CachePolicy?
    let timeoutInterval: TimeInterval?
    let headerValues: [(value: String, forHTTPHeaderField: String)]?
}
