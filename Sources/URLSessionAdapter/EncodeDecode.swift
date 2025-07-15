//
//  EncodeDecode.swift
//  https://github.com/denissimon/URLSessionAdapter
//
//  Created by Denis Simon on 19/12/2020.
//
//  MIT License (https://github.com/denissimon/URLSessionAdapter/blob/main/LICENSE)
//

import Foundation

public struct RequestEncodable {
    public static func encode<T: Encodable>(_ value: T, encoder: JSONEncoder? = nil) -> Data?  {
        let jsonEncoder = encoder ?? JSONEncoder()
        do {
            return try jsonEncoder.encode(value)
        } catch {
            return nil
        }
    }
}

extension Encodable {
    func encode() -> Data? { RequestEncodable.encode(self) }
}

public struct ResponseDecodable {
    public static func decode<T: Decodable>(_ type: T.Type, from data: Data, decoder: JSONDecoder? = nil) -> T? {
        let jsonDecoder = decoder ?? JSONDecoder()
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            return nil
        }
    }
}
