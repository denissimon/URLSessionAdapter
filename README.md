# URLSessionAdapter

[![Swift](https://img.shields.io/badge/Swift-6-orange.svg?style=flat)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-lightgrey.svg)](https://developer.apple.com/swift/)

A Codable wrapper around URLSession for networking. Includes both APIs: async/await and callbacks.

Supports:

* `Data`, `Upload`, and `Download` URL session tasks
* HTTP methods: GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS, CONNECT, TRACE, QUERY
* Automatic validation: global or per request based on the received status code
* Delegates to receive progress updates

Installation
------------

#### Swift Package Manager

To install URLSessionAdapter using [Swift Package Manager](https://swift.org/package-manager):

```swift
dependencies: [
    .package(url: "https://github.com/denissimon/URLSessionAdapter.git", from: "2.2.5")
]
```

Or through Xcode:

```txt
Xcode: File -> Add Packages
Enter Package URL: https://github.com/denissimon/URLSessionAdapter
```

#### CocoaPods

To install URLSessionAdapter using [CocoaPods](https://cocoapods.org), add this line to your `Podfile`:

```ruby
pod 'URLSessionAdapter', '~> 2.2'
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

#### Defining a Decodable/Codable instance

```swift
struct Activity: Decodable {
    let id: Int?
    let name: String
    let description: String
}
```

#### Defining API endpoints

```swift
import URLSessionAdapter

struct APIEndpoints {
    
    static let baseURL = "https://api.example.com/rest"
    
    static func getActivity(id: Int) -> EndpointType {
        let path = "/activities/\(id)/?key=\(Secrets.apiKey)"        
        return Endpoint(
            method: .GET,
            baseURL: APIEndpoints.baseURL,
            path: path,
            params: nil)
    }
    
    static func createActivity(_ activity: Activity) -> EndpointType {
        let path = "/activities/?key=\(Secrets.apiKey)"

        let params = HTTPParams(httpBody: activity.encode(), headerValues: [(
            value: "application/json",
            forHTTPHeaderField: "Content-Type")
        ])
        
        return Endpoint(
            method: .POST,
            baseURL: APIEndpoints.baseURL,
            path: path,
            params: params)
    }
}
```

#### Defining API methods

```swift
import URLSessionAdapter

class ActivityRepository {
    
    let networkService: NetworkService
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func getActivity(id: Int) async -> Result<Activity, CustomError> {
        let endpoint = APIEndpoints.getActivity(id: id)
        guard let request = RequestFactory.request(endpoint) else { ... }
        do {
            let (activity, _) = try await networkService.request(request, type: Activity.self)
            return .success(activity)
        } catch {
            ...
        }
    }
    
    func createActivity(_ activity: Activity) async -> Result<Data, CustomError> {
        let endpoint = APIEndpoints.createActivity(activity)
        guard let request = RequestFactory.request(endpoint) else { ... }
        do {
            let (data, _) = try await networkService.request(request)
            return .success(data)
        } catch {
            ...
        }
    }
}
```

#### API calls

```swift
let networkService = NetworkService(urlSession: URLSession.shared)
let activityRepository = ActivityRepository(networkService: networkService)

Task {
    let result = await activityRepository.getActivity(id: 1)
    switch result {
    case .success(let activity):
        ...
    case .failure(let error):
        ...
    }
}

Task {
    let result = await activityRepository.createActivity(activity) // will return the id of the created activity
    switch result {
    case .success(let data):
        guard let data = data, 
              let activityId = Int(String(data: data, encoding: .utf8) ?? "") else { ... }
        ...
    case .failure(let error):
        ...
    }
}
```

Fetch a file:

```swift
let data = try await networkService.fetchFile(url).data
guard let image = UIImage(data: data) else {
    ...
}
```

Download a file:

```swift
guard try await networkService.downloadFile(url, to: localUrl).result else {
    ...
}
```

Upload a file:

```swift
let endpoint = SomeAPI.uploadFile(file)
guard let request = RequestFactory.request(endpoint) else { return }
let config = RequestConfiguration(uploadTask: true)
let (data, response) = try await networkService.request(request, configuration: config)
```

Check the returned status code:

```swift
guard let httpResponse = response as? HTTPURLResponse else { return }
assert(httpResponse.statusCode == 200)
```

#### Validation

By default, any 300-599 status code returned by the server throws a `NetworkError`:

```swift
do {
    let response = try await networkService.request(request) // will return status code 404
    ...
} catch let networkError as NetworkError {
    let description = networkError.error?.localizedDescription
    let statusCode = networkError.statusCode // 404
    let dataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
} catch {
    // Handling other errors
}
```

Optionally, this automatic validation can be disabled globally:

```swift
networkService.autoValidation = false

do {
    let response = try await networkService.request(request) // will return status code 404
    let statusCode = (response as? HTTPURLResponse)?.statusCode // 404
    let dataStr = String(data: response.data ?? Data(), encoding: .utf8)!
} catch {
    ...
}
```

Or it can be disabled for a specific request:

```swift
do {
    let config = RequestConfiguration(validation: false)
    let response = try await networkService.request(request, configuration: config) // will return status code 404
    let statusCode = (response as? HTTPURLResponse)?.statusCode // 404
    let dataStr = String(data: response.data ?? Data(), encoding: .utf8)!
} catch {
    ...
}
```

#### Receive progress updates

```swift
let progressObserver = ProgressObserver {
    print($0.fractionCompleted) // Outputs: 0.05 0.0595 1.0
}
    
do {
    let (result, response) = try await networkService.downloadFile(
        url,
        to: destinationUrl,
        delegate: progressObserver
    )
    ...
} catch {
    ...
}
```

More usage examples can be found in [tests](https://github.com/denissimon/URLSessionAdapter/tree/main/Tests/URLSessionAdapterTests) and [iOS-MVVM-Clean-Architecture](https://github.com/denissimon/iOS-MVVM-Clean-Architecture) where this adapter was used.

Public methods
--------------

**async/await API**

```swift
func request(_ request: URLRequest, configuration: RequestConfiguration?, delegate: URLSessionDataDelegate?) async throws -> (data: Data, response: URLResponse)
func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration?, delegate: URLSessionDataDelegate?) async throws -> (decoded: T, response: URLResponse)
func fetchFile(_ url: URL, configuration: RequestConfiguration?, delegate: URLSessionDataDelegate?) async throws -> (data: Data?, response: URLResponse)
func downloadFile(_ url: URL, to localUrl: URL, configuration: RequestConfiguration?, delegate: URLSessionDataDelegate?) async throws -> (result: Bool, response: URLResponse)
```

**callbacks API**

```swift
func request(_ request: URLRequest, configuration: RequestConfiguration?, completion: @escaping @Sendable (Result<(data: Data?, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable?
func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration?, completion: @escaping @Sendable (Result<(decoded: T, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable?
func fetchFile(_ url: URL, configuration: RequestConfiguration?, completion: @escaping @Sendable (Result<(data: Data?, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable?
func downloadFile(_ url: URL, to localUrl: URL, configuration: RequestConfiguration?, completion: @escaping @Sendable (Result<(result: Bool, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable?
```

License
-------

Licensed under the [MIT license](https://github.com/denissimon/URLSessionAdapter/blob/main/LICENSE)
