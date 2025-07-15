# URLSessionAdapter

[![Swift](https://img.shields.io/badge/Swift-5-orange.svg?style=flat)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-lightgrey.svg)](https://developer.apple.com/swift/)

A Codable wrapper around URLSession for networking. Includes both APIs: async/await and callbacks. 

Supports:
* _Data_, _Upload_, and _Download_ URL session tasks
* HTTP methods: GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS, CONNECT, TRACE, QUERY
* Automatic validation: global or per request based on the received status code
* Delegates to receive progress updates

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

**Defining a Decodable/Codable instance**

```swift
struct Activity: Decodable {
    let id: Int?
    let name: String
    let description: String
}
```

**Defining API endpoints**

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

**Defining API methods**

```swift
import URLSessionAdapter

class ActivityRepository {
    
    let networkService: NetworkServiceType
    
    init(networkService: NetworkServiceType) {
        self.networkService = networkService
    }
    
    func getActivity(id: Int) async -> Result<Activity, CustomError> {
        let endpoint = APIEndpoints.getActivity(id: id)
        guard let request = RequestFactory.request(endpoint) else { return .failure(customError()) }
        do {
            let (activity, _) = try await networkService.request(request, type: Activity.self)
            return .success(activity)
        } catch {
            return .failure(error as! CustomError)
        }
    }
    
    func createActivity(_ activity: Activity) async -> Result<Data, CustomError> {
        let endpoint = APIEndpoints.createActivity(activity)
        guard let request = RequestFactory.request(endpoint) else { return .failure(customError()) }
        do {
            let (data, _) = try await networkService.request(request)
            return .success(data)
        } catch {
            return .failure(error as! CustomError)
        }
    }
}
```

**API calls**

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
    // The server returns the id of the created activity
    let result = await activityRepository.createActivity(activity)
    switch result {
    case .success(let data):
        guard let data = data, 
              let createdActivityId = Int(String(data: data, encoding: .utf8) ?? "") else {
            ...
        }
        ...
    case .failure(let error):
        ...
    }
}
```

```swift
// To fetch a file:
let data = try await networkService.fetchFile(url).data
guard let image = UIImage(data: data) else {
    ...
}

// To download a file:
guard try await networkService.downloadFile(url, to: localUrl).result else {
    ...
}

// To upload a file:
let endpoint = JSONPlaceholderAPI.uploadFile(file)
guard let request = RequestFactory.request(endpoint) else { return }
let config = RequestConfiguration(uploadTask: true)
let (data, response) = try await networkService.request(request, configuration: config)

// Check the returned status code:
guard let httpResponse = response as? HTTPURLResponse else { return }
assert(httpResponse.statusCode == 200)
```

**Validation**

```swift
// By default, any 300-599 status code returned by the server throws a NetworkError:
do {
    // The server will return status code 404
    let response = try await networkService.request(request)
    ...
} catch {
    if error is NetworkError {
        let networkError = error as! NetworkError
        let errorDescription = networkError.error?.localizedDescription
        let errorStatusCode = networkError.statusCode // 404
        let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
        ...
    } else {
        // Handling other errors
        ...
    }
}

// Optionally, this automatic validation can be disabled globally:

networkService.autoValidation = false

do {
    // The server will return status code 404
    let response = try await networkService.request(request)
    let statusCode = (response as? HTTPURLResponse)?.statusCode // 404
    let resultStr = String(data: response.value ?? Data(), encoding: .utf8)!
} catch {
    ...
}

// Or it can be disabled for a specific request:
do {
    // The server will return status code 404
    let config = RequestConfiguration(validation: false)
    let response = try await networkService.request(request, configuration: config)
    let statusCode = (response as? HTTPURLResponse)?.statusCode // 404
    let resultStr = String(data: response.value ?? Data(), encoding: .utf8)!
} catch {
    ...
}
```

**Receive progress updates**

```swift
let progressObserver = ProgressObserver {
    print($0.fractionCompleted) // Outputs: 0.05 0.0595 1.0
}
    
do {
    let (result, response) = try await networkService.downloadFile(url, to: destinationUrl, delegate: progressObserver)
    ...
} catch {
    ...
}
```

More usage examples can be found in [tests](https://github.com/denissimon/URLSessionAdapter/tree/main/Tests/URLSessionAdapterTests) and [iOS-MVVM-Clean-Architecture](https://github.com/denissimon/iOS-MVVM-Clean-Architecture) where this adapter was used.

### Public methods

```swift
// async/await API

func request(_ request: URLRequest, configuration: RequestConfiguration?, delegate: URLSessionDataDelegate?) async throws -> (data: Data, response: URLResponse)
func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration?, delegate: URLSessionDataDelegate?) async throws -> (decoded: T, response: URLResponse)
func fetchFile(_ url: URL, configuration: RequestConfiguration?, delegate: URLSessionDataDelegate?) async throws -> (data: Data?, response: URLResponse)
func downloadFile(_ url: URL, to localUrl: URL, configuration: RequestConfiguration?, delegate: URLSessionDataDelegate?) async throws -> (result: Bool, response: URLResponse)

// callbacks API

func request(_ request: URLRequest, configuration: RequestConfiguration?, completion: @escaping (Result<(data: Data?, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable?
func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration?, completion: @escaping (Result<(decoded: T, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable?
func fetchFile(_ url: URL, configuration: RequestConfiguration?, completion: @escaping (Result<(data: Data?, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable?
func downloadFile(_ url: URL, to localUrl: URL, configuration: RequestConfiguration?, completion: @escaping (Result<(result: Bool, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable?
```

Requirements
------------

iOS 15.0+, macOS 12.0+, tvOS 15.0+, watchOS 8.0+

License
-------

Licensed under the [MIT license](https://github.com/denissimon/URLSessionAdapter/blob/main/LICENSE)
