# URLSessionAdapter

[![Swift](https://img.shields.io/badge/Swift-5-orange.svg?style=flat)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-lightgrey.svg)](https://developer.apple.com/swift/)

A Codable wrapper around URLSession for networking.

Supports _data_, _upload_, and _download_ URL session tasks.

Installation
------------

#### Swift Package Manager

To install URLSessionAdapter using [Swift Package Manager](https://swift.org/package-manager):

```txt
Xcode: File -> Add Packages
Enter Package URL: https://github.com/denissimon/URLSessionAdapter
```

#### CocoaPods

To install URLSessionAdapter using [CocoaPods](https://cocoapods.org), add this line to your `Podfile`:

```ruby
pod 'URLSessionAdapter', '~> 1.5'
```

#### Carthage

To install URLSessionAdapter using [Carthage](https://github.com/Carthage/Carthage), add this line to your `Cartfile`:

```ruby
github "denissimon/URLSessionAdapter"
```

#### Manually

Copy folder `URLSessionAdapter` into your project.

Usage
-----

**Defining a Codable instance:**

```swift
struct Activity: Codable {
    let id: Int?
    let name: String
    let description: String
}
```

**Defining API endpoints:**

```swift
import URLSessionAdapter

struct APIEndpoints {
    
    static let baseURL = "https://api.example.com/rest"
    static let apiKey = "api_key"
    
    static func getActivity(id: Int) -> EndpointType {
        let path = "/activities/\(id)/?api_key=\(APIEndpoints.apiKey)"        
        return Endpoint(
            method: .GET,
            baseURL: APIEndpoints.baseURL,
            path: path,
            params: nil)
    }
    
    static func createActivity(_ activity: Activity) -> EndpointType {
        let path = "/activities/?api_key=\(APIEndpoints.apiKey)"
        
        let activityData = activity.encode()
        let params = HTTPParams(httpBody: activityData, headerValues:[
        (value: "application/json", forHTTPHeaderField: "Content-Type")])
        
        return Endpoint(
            method: .POST,
            baseURL: APIEndpoints.baseURL,
            path: path,
            params: params)
    }
}
```

**Defining API methods:**

```swift
import URLSessionAdapter

class ActivityRepository {
    
    let networkService: NetworkServiceType
    
    init(networkService: NetworkServiceType) {
        self.networkService = networkService
    }
    
    func getActivity(id: Int, completionHandler: @escaping (Result<Activity, NetworkError>) -> Void) -> NetworkCancellable? {
        let endpoint = APIEndpoints.getActivity(id: id)
        let networkTask = networkService.request(endpoint, type: Activity.self) { result in
            completionHandler(result)
        }
        return networkTask
    }
    
    func createActivity(_ activity: Activity, completionHandler: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable? {
        let endpoint = APIEndpoints.createActivity(activity)
        let networkTask = networkService.request(endpoint) { result in
            completionHandler(result)
        }
        return networkTask
    }
    
    // Using async/await with 'continuation':
    
    func getActivity(id: Int) async -> Result<Activity, NetworkError> {
        await withCheckedContinuation { continuation in
            let _ = getActivity(id: id) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    func createActivity(_ activity: Activity) async -> Result<Data?, NetworkError> {
        await withCheckedContinuation { continuation in
            let _ = createActivity(activity) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
```

**API calls:**

```swift
let activityRepository = ActivityRepository(networkService: NetworkService())

activityRepository.getActivity(id: 1) { result in // -> Result<Activity, NetworkError>
    ...
}

// The server returns the id of the created activity
activityRepository.createActivity(activity) { result in // -> Result<Data?, NetworkError>
    if let data = try? result.get() {
        if let createdActivityId = Int(String(data: data, encoding: .utf8) ?? "") {
            ...
        }
    }
}

// Using async/await with 'continuation':

Task {
    let result = await activityRepository.getActivity(id: 1) // -> Result<Activity, NetworkError>
    ...
}

Task {
    // The server returns the id of the created activity
    let result = await activityRepository.createActivity(activity) // -> Result<Data?, NetworkError>
    if let data = try? result.get() {
        if let createdActivityId = Int(String(data: data, encoding: .utf8) ?? "") {
            ...
        }
    }
}
```

More usage examples can be found in [tests](https://github.com/denissimon/URLSessionAdapter/tree/main/Tests/URLSessionAdapterTests) and [iOS-MVVM-Clean-Architecture](https://github.com/denissimon/iOS-MVVM-Clean-Architecture) where this adapter was used.

### Public methods

```swift
func request(_ endpoint: EndpointType, uploadTask: Bool, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable?
func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable?
func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable?
func downloadFile(url: URL, to localUrl: URL, completion: @escaping (Result<Bool, NetworkError>) -> Void) -> NetworkCancellable?

func requestWithStatusCode(_ endpoint: EndpointType, uploadTask: Bool, completion: @escaping (Result<(result: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
func requestWithStatusCode<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool, completion: @escaping (Result<(result: T, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
func fetchFileWithStatusCode(url: URL, completion: @escaping ((result: Data?, statusCode: Int?)) -> Void) -> NetworkCancellable?
func downloadFileWithStatusCode(url: URL, to localUrl: URL, completion: @escaping (Result<(result: Bool, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
```

Requirements
------------

iOS 12.0+, macOS 10.13.0+, tvOS 12.0+, watchOS 4.0+

License
-------

Licensed under the [MIT license](https://github.com/denissimon/URLSessionAdapter/blob/main/LICENSE)
