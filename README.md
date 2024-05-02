# URLSessionAdapter

[![Swift](https://img.shields.io/badge/Swift-5-orange.svg?style=flat)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-lightgrey.svg)](https://developer.apple.com/swift/)

A Codable wrapper around URLSession for networking.

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
pod 'URLSessionAdapter', '~> 1.4'
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
    var requiredByDate: Date?
    var completedDate: Date?
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
        
        let params = HTTPParams(timeoutInterval: 10.0, headerValues:[
        (value: "application/json", forHTTPHeaderField: "Accept"),
        (value: "application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")])
        
        return Endpoint(
            method: .GET,
            baseURL: APIEndpoints.baseURL,
            path: path,
            params: params)
    }
    
    static func createActivity(_ activity: Activity) -> EndpointType {
        let path = "/activities/?api_key=\(APIEndpoints.apiKey)"
        
        let activityData = activity.encode()
        let params = HTTPParams(httpBody: activityData, headerValues:[
        (value: "text/plain", forHTTPHeaderField: "Accept"),
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
    
    // Using completion handler
    func getActivity(id: Int, completionHandler: @escaping (Result<Activity, NetworkError>) -> Void) {
        let endpoint = APIEndpoints.getActivity(id: id)
        networkService.request(endpoint, type: Activity.self) { result in
            completionHandler(result)
        }
    }
    
    func createActivity(_ activity: Activity, completionHandler: @escaping (Result<Data?, NetworkError>) -> Void) {
        let endpoint = APIEndpoints.createActivity(activity)
        networkService.request(endpoint) { result in
            completionHandler(result)
        }
    }
    
    // Using async/await
    func getActivity(id: Int) async -> Result<Activity, NetworkError> {
        await withCheckedContinuation { continuation in
            getActivity(id: id) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    func createActivity(_ activity: Activity) async -> Result<Data?, NetworkError> {
        await withCheckedContinuation { continuation in
            createActivity(activity) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
```

**API calls:**

```swift
let activityRepository = ActivityRepository(networkService: NetworkService())

Task.detached {
    let result = await activityRepository.getActivity(id: 1) // -> Result<Activity, NetworkError>
    ...
}

Task.detached {
    // The server returns the id of the created activity
    let result = await activityRepository.createActivity(activity) // -> Result<Data?, NetworkError>
    if let resultData = try? result.get() {
        if let createdActivityId = Int(String(data: resultData, encoding: .utf8) ?? "") {
            ...
        }
    }
}
```

More usage examples can be found in [URLSessionAdapterTests.swift](https://github.com/denissimon/URLSessionAdapter/blob/main/Tests/URLSessionAdapterTests/URLSessionAdapterTests.swift), as well as in [iOS-MVVM-Clean-Architecture](https://github.com/denissimon/iOS-MVVM-Clean-Architecture) and [Cryptocurrency-Info](https://github.com/denissimon/Cryptocurrency-Info) where this adapter was used.

### Public methods

```swift
func request(_ endpoint: EndpointType, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable?
func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable?
func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable?

func requestWithStatusCode(_ endpoint: EndpointType, completion: @escaping (Result<(result: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
func requestWithStatusCode<T: Decodable>(_ endpoint: EndpointType, type: T.Type, completion: @escaping (Result<(result: T, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
func fetchFileWithStatusCode(url: URL, completion: @escaping ((result: Data?, statusCode: Int?)) -> Void) -> NetworkCancellable?
```

License
-------

Licensed under the [MIT license](https://github.com/denissimon/URLSessionAdapter/blob/main/LICENSE)
