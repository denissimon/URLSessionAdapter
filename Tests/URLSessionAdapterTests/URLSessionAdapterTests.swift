//
//  URLSessionAdapterTests.swift
//  https://github.com/denissimon/URLSessionAdapter
//
//  Created by Denis Simon on 31/03/2024.
//
//  MIT License (https://github.com/denissimon/URLSessionAdapter/blob/main/LICENSE)
//

import XCTest
@testable import URLSessionAdapter

final class URLSessionAdapterTests: XCTestCase {
    
    // FlickrAPI tests (from https://github.com/denissimon/iOS-MVVM-Clean-Architecture/)
    
    // https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=8ca55bca1384f45ab957b7618afc6ecc&text=%22nice%22&per_page=5&format=json&nojsoncallback=1
    static let searchResultJsonStub = """
    {"photos":{"page":1,"pages":22461,"perpage":5,"total":112301,"photo":[{"id":"53624890009","owner":"105731165@N07","secret":"5cd918efcd","server":"65535","farm":66,"title":"Andrea  Modelo  Model","ispublic":1,"isfriend":0,"isfamily":0},{"id":"53624982545","owner":"200344658@N04","secret":"27599b24dd","server":"65535","farm":66,"title":"FC Nantes - OGC Nice","ispublic":1,"isfriend":0,"isfamily":0},{"id":"53624540146","owner":"200344658@N04","secret":"861e943634","server":"65535","farm":66,"title":"FC Nantes - OGC Nice","ispublic":1,"isfriend":0,"isfamily":0},{"id":"53624982400","owner":"200344658@N04","secret":"f16ea5ebe5","server":"65535","farm":66,"title":"FC Nantes - OGC Nice","ispublic":1,"isfriend":0,"isfamily":0},{"id":"53624740978","owner":"200344658@N04","secret":"90689d079d","server":"65535","farm":66,"title":"FC Nantes - OGC Nice","ispublic":1,"isfriend":0,"isfamily":0}]},"stat":"ok"}
    """
    
    // https://api.flickr.com/services/rest/?method=flickr.tags.getHotList&api_key=8ca55bca1384f45ab957b7618afc6ecc&period=week&count=2&format=json&nojsoncallback=1
    static let getHotTagsResultJsonStub = """
    {"period":"day","count":2,"hottags":{"tag":[{"_content":"digital","thm_data":{"photos":{"photo":[{"id":"30239309451","secret":"10f9bdfddd","server":"8273","farm":9,"owner":"135037635@N03","username":null,"title":"Fire on the sky","ispublic":1,"isfriend":0,"isfamily":0}]}}},{"_content":"shine","thm_data":{"photos":{"photo":[{"id":"26695870685","secret":"0e25f93ea0","server":"1641","farm":2,"owner":"76458369@N07","username":null,"title":"#Storm","ispublic":1,"isfriend":0,"isfamily":0}]}}}]},"stat":"ok"}
    """
    
    class NetworkServiceMock: NetworkServiceType {
           
        let urlSession: URLSession
        
        let responseData: Data
        
        init(urlSession: URLSession = URLSession.shared, responseData: Data) {
            self.urlSession = urlSession
            self.responseData = responseData
        }
        
        func request(_ endpoint: EndpointType, uploadTask: Bool = false, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable? {
            completion(.success(responseData))
            return nil
        }
        
        func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool = false, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable? {
            guard let decoded = ResponseDecodable.decode(type, data: responseData) else {
                completion(.failure(NetworkError(error: nil, statusCode: nil, data: nil)))
                return nil
            }
            completion(.success(decoded))
            return nil
        }
        
        func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable? {
            completion("image".data(using: .utf8))
            return nil
        }
        
        func downloadFile(url: URL, to localUrl: URL, completion: @escaping (Result<Bool, NetworkError>) -> Void) -> NetworkCancellable? {
            completion(.success(true))
            return nil
        }
        
        func requestWithStatusCode(_ endpoint: EndpointType, uploadTask: Bool = false, completion: @escaping (Result<(result: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
            completion(.success((responseData, 200)))
            return nil
        }

        func requestWithStatusCode<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool = false, completion: @escaping (Result<(result: T, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
            guard let decoded = ResponseDecodable.decode(type, data: responseData) else {
                completion(.failure(NetworkError(error: nil, statusCode: nil, data: nil)))
                return nil
            }
            completion(.success((decoded, 200)))
            return nil
        }
        
        func fetchFileWithStatusCode(url: URL, completion: @escaping ((result: Data?, statusCode: Int?)) -> Void) -> NetworkCancellable? {
            completion(("image".data(using: .utf8), 200))
            return nil
        }
        
        func downloadFileWithStatusCode(url: URL, to localUrl: URL, completion: @escaping (Result<(result: Bool, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
            completion(.success((true, 200)))
            return nil
        }
    }
    
    func testSearch() {
        let endpoint = FlickrAPI.search(ImageQuery(query: "random"))
        let expectedData = URLSessionAdapterTests.searchResultJsonStub.data(using: .utf8)!
        let networkServiceMock = NetworkServiceMock(responseData: expectedData)
        
        var resultData: Data? = Data()
        let _ = networkServiceMock.request(endpoint) { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data, expectedData)
                resultData = data
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        XCTAssertNotNil(resultData)
        let resultStr = String(data: resultData!, encoding: .utf8)!
        XCTAssertEqual(resultStr, "{\"photos\":{\"page\":1,\"pages\":22461,\"perpage\":5,\"total\":112301,\"photo\":[{\"id\":\"53624890009\",\"owner\":\"105731165@N07\",\"secret\":\"5cd918efcd\",\"server\":\"65535\",\"farm\":66,\"title\":\"Andrea  Modelo  Model\",\"ispublic\":1,\"isfriend\":0,\"isfamily\":0},{\"id\":\"53624982545\",\"owner\":\"200344658@N04\",\"secret\":\"27599b24dd\",\"server\":\"65535\",\"farm\":66,\"title\":\"FC Nantes - OGC Nice\",\"ispublic\":1,\"isfriend\":0,\"isfamily\":0},{\"id\":\"53624540146\",\"owner\":\"200344658@N04\",\"secret\":\"861e943634\",\"server\":\"65535\",\"farm\":66,\"title\":\"FC Nantes - OGC Nice\",\"ispublic\":1,\"isfriend\":0,\"isfamily\":0},{\"id\":\"53624982400\",\"owner\":\"200344658@N04\",\"secret\":\"f16ea5ebe5\",\"server\":\"65535\",\"farm\":66,\"title\":\"FC Nantes - OGC Nice\",\"ispublic\":1,\"isfriend\":0,\"isfamily\":0},{\"id\":\"53624740978\",\"owner\":\"200344658@N04\",\"secret\":\"90689d079d\",\"server\":\"65535\",\"farm\":66,\"title\":\"FC Nantes - OGC Nice\",\"ispublic\":1,\"isfriend\":0,\"isfamily\":0}]},\"stat\":\"ok\"}")
    }
    
    func testGetHotTags() {
        let endpoint = FlickrAPI.getHotTags()
        let networkServiceMock = NetworkServiceMock(responseData: URLSessionAdapterTests.getHotTagsResultJsonStub.data(using: .utf8)!)
        let _ = networkServiceMock.request(endpoint, type: Tags.self) { result in
            switch result {
            case .success(let tags):
                if tags.stat != "ok" {
                    XCTFail()
                }
                XCTAssertEqual(tags.hottags.tag.count, 2)
                XCTAssertEqual(tags.hottags.tag[0].name, "digital")
                XCTAssertEqual(tags.hottags.tag[1].name, "shine")
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func testNetworkError_whenInvalidResponse() {
        let endpoint = FlickrAPI.getHotTags()
        let networkServiceMock = NetworkServiceMock(responseData: "some_data".data(using: .utf8)!)
        let _ = networkServiceMock.request(endpoint, type: Tags.self) { result in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.contains("The operation couldn’t be completed"))
            }
        }
    }
    
    func testNetworkError_whenInvalidAPIKey() {
        let promise = expectation(description: "testNetworkError")
        
        var endpoint = FlickrAPI.getHotTags()
        endpoint.path = "?method=flickr.photos.search&api_key=12345&text=nice&per_page=20&format=json&nojsoncallback=1"
        let networkService = NetworkService()
        let _ = networkService.request(endpoint, type: Tags.self) { result in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.contains("The operation couldn’t be completed"))
                if error.data != nil {
                    let dataStr = String(data: error.data!, encoding: .utf8)
                    XCTAssertEqual(dataStr, "{\"stat\":\"fail\",\"code\":100,\"message\":\"Invalid API Key (Key has invalid format)\"}")
                }
            }
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testFetchFile() {
        let promise = expectation(description: "testFetchFile")
        
        let networkService = NetworkService()
        let _ = networkService.fetchFileWithStatusCode(url: URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!) { data in
            XCTAssertNotNil(data.result)
            XCTAssertEqual(data.statusCode, 200)
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testFetchFile_whenInvalidURL() {
        let promise = expectation(description: "testFetchFile")
        
        let networkService = NetworkService()
        let _ = networkService.fetchFileWithStatusCode(url: URL(string: "https://farm1.staticflickr.com/server/id1_secret1_m.jpg")!) { data in
            XCTAssertNil(data.result)
            XCTAssertEqual(data.statusCode, 404)
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
}

struct FlickrAPI {
    
    static let baseURL = "https://api.flickr.com/services/rest/"
    static let flickrApiKey = "8ca55bca1384f45ab957b7618afc6ecc"
    static let photosPerRequest = 5
    static let hotTagsCount = 2
    
    static let defaultParams = HTTPParams(httpBody: nil, cachePolicy: nil, timeoutInterval: 10.0, headerValues:[
        (value: ContentType.applicationJson.rawValue, forHTTPHeaderField: HTTPHeader.accept.rawValue),
        (value: ContentType.applicationFormUrlencoded.rawValue, forHTTPHeaderField: HTTPHeader.contentType.rawValue)])
    
    static func search(_ imageQuery: ImageQuery) -> EndpointType {
        let path = "?method=flickr.photos.search&api_key=\(FlickrAPI.flickrApiKey)&text=\(imageQuery.query)&per_page=\(FlickrAPI.photosPerRequest)&format=json&nojsoncallback=1"
        
        let params = FlickrAPI.defaultParams
        
        return Endpoint(
            method: .GET,
            baseURL: FlickrAPI.baseURL,
            path: path,
            params: params)
    }
    
    static func getHotTags() -> EndpointType {
        let path = "?method=flickr.tags.getHotList&api_key=\(FlickrAPI.flickrApiKey)&period=week&count=\(FlickrAPI.hotTagsCount)&format=json&nojsoncallback=1"
        
        let params = FlickrAPI.defaultParams
        
        return Endpoint(
            method: .GET,
            baseURL: FlickrAPI.baseURL,
            path: path,
            params: params)
    }
}

struct ImageQuery: Equatable {
    let query: String
}

struct Tags: Decodable {
    
    struct HotTags: Decodable {
        let tag: [Tag]
    }
    
    let hottags: HotTags
    let stat: String
    
    enum CodingKeys: String, CodingKey {
        case hottags
        case stat
    }
}

struct Tag: Decodable {
    
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case name = "_content"
    }
}
