//
//  ProgressObserver.swift
//  https://github.com/denissimon/URLSessionAdapter
//
//  Created by Denis Simon on 09/07/2025.
//
//  MIT License (https://github.com/denissimon/URLSessionAdapter/blob/main/LICENSE)
//

import Foundation

open class ProgressObserver: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    
    var observation: NSKeyValueObservation? = nil
    let onChangeHandler: (Progress) -> Void
    
    public init(onChangeHandler: @escaping (Progress) -> Void) {
        self.onChangeHandler = onChangeHandler
    }
    
    public func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        observation = task.progress.observe(\.fractionCompleted) { progress, change in
            self.onChangeHandler(progress)
        }
    }
}
