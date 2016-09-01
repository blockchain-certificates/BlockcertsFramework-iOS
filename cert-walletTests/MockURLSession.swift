//
//  MockURLSession.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/1/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

class MockURLSession : URLSessionProtocol {
    private var responseMap = [URL : (data: Data?, response: URLResponse?, error: Error?)]()
    
    func respond(to url: URL, with data: Data?, response: URLResponse?, error: Error?) {
        responseMap[url] = (
            data: data,
            response: response,
            error: error
        )
    }
    
    // Conform to URLSessionProtocol
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        guard let responseData = responseMap[url] else {
            fatalError("MockURLSession saw request for \(url), but doesn't know how to respond to it.")
        }
        
        return MockURLSessionDataTask(send: responseData.data,
                                      response: responseData.response,
                                      error: responseData.error,
                                      to: completionHandler)
    }
}

class MockURLSessionDataTask : URLSessionDataTaskProtocol {
    let completionHandler : (Data?, URLResponse?, Error?) -> Void
    let data : Data?
    let response: URLResponse?
    let error: Error?
    
    init(send data: Data?, response: URLResponse?, error: Error?, to callback: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.data = data
        self.response = response
        self.error = error
        completionHandler = callback
    }
    
    func resume() {
        // TODO: Maybe delay a bit?
        completionHandler(data, response, error)
    }
    
    func cancel() {}
}
