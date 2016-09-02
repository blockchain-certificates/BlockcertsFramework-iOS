//
//  MockURLSession.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/1/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

class MockURLSession : URLSessionProtocol {
    private var responseData = [URL : (data: Data?, response: URLResponse?, error: Error?)]()
    private var responseCallbacks = [URL : () -> (data: Data?, response: URLResponse?, error: Error?)]()
    
    func respond(to url: URL, with data: Data?, response: URLResponse?, error: Error?) {
        responseData[url] = (
            data: data,
            response: response,
            error: error
        )
    }
    
    func respond(to url: URL, callback: @escaping () -> (data: Data?, response: URLResponse?, error: Error?)) {
        responseCallbacks[url] = callback
    }
    
    
    // Conform to URLSessionProtocol
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        let callback = responseCallbacks[url]
        let data = responseData[url]
        let task : MockURLSessionDataTask!
        
        if let callback = callback {
            task = MockURLSessionDataTask(serverCallback: callback, callback: completionHandler)
        } else if let data = data {
            task = MockURLSessionDataTask(send: data.data,
                                          response: data.response,
                                          error: data.error,
                                          to: completionHandler)
        } else {
            fatalError("MockURLSession saw request for \(url), but doesn't know how to respond to it.")
        }
        
        return task
    }
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        guard
            let url = request.url,
            let responseData = responseData[url] else {
            fatalError("MockURLSession saw request for \(request.url), but doesn't know how to respond to it.")
        }
        
        return MockURLSessionDataTask(send: responseData.data,
                                      response: responseData.response,
                                      error: responseData.error,
                                      to: completionHandler)

    }
    

}

class MockURLSessionDataTask : URLSessionDataTaskProtocol {
    let completionHandler : (Data?, URLResponse?, Error?) -> Void
    let serverCallback : (() -> (Data?, URLResponse?, Error?))?
    let data : Data?
    let response: URLResponse?
    let error: Error?
    
    init(send data: Data?, response: URLResponse?, error: Error?, to callback: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.data = data
        self.response = response
        self.error = error
        serverCallback = nil
        completionHandler = callback
    }
    
    init(serverCallback: @escaping () -> (Data?, URLResponse?, Error?), callback: @escaping (Data?, URLResponse?, Error?) -> Void) {
        data = nil
        response = nil
        error = nil
        self.serverCallback = serverCallback
        completionHandler = callback
    }
    
    
    func resume() {
        // TODO: Maybe delay a bit?
        if let serverCallback = serverCallback {
            let (data, response, error) = serverCallback()
            completionHandler(data, response, error)
        } else {
            completionHandler(data, response, error)
        }
    }
    
    func cancel() {}
}
