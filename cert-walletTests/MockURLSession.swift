//
//  MockURLSession.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/1/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation
import Blockcerts

public class MockURLSession : URLSessionProtocol {
    private var responseData = [URL : (data: Data?, response: URLResponse?, error: Error?)]()
    private var responseCallbacks = [URL : (request: URLRequest) -> (data: Data?, response: URLResponse?, error: Error?)]()
    
    func respond(to url: URL, with data: Data?, response: URLResponse?, error: Error?) {
        responseData[url] = (
            data: data,
            response: response,
            error: error
        )
    }
    
    func respond(to url: URL, callback: @escaping (URLRequest) -> (data: Data?, response: URLResponse?, error: Error?)) {
        responseCallbacks[url] = callback
    }
    
    
    // Conform to URLSessionProtocol
    public func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        let callback = responseCallbacks[url]
        let data = responseData[url]
        let task : MockURLSessionDataTask!
        
        if let callback = callback {
            let request = URLRequest(url: url)
            task = MockURLSessionDataTask(request: request, serverCallback: callback, callback: completionHandler)
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
    
    public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        guard let url = request.url else {
            fatalError("MockURLSession saw request that had no URL.")
        }
        
        let callback = responseCallbacks[url]
        let data = responseData[url]
        let task : MockURLSessionDataTask!
        
        if let callback = callback {
            task = MockURLSessionDataTask(request: request, serverCallback: callback, callback: completionHandler)
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
}

class MockURLSessionDataTask : URLSessionDataTaskProtocol {
    let completionHandler : (Data?, URLResponse?, Error?) -> Void
    let serverCallback : ((URLRequest) -> (Data?, URLResponse?, Error?))?
    let request : URLRequest?
    let data : Data?
    let response: URLResponse?
    let error: Error?
    
    init(send data: Data?, response: URLResponse?, error: Error?, to callback: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.data = data
        self.response = response
        self.error = error
        request = nil
        serverCallback = nil
        completionHandler = callback
    }
    
    init(request: URLRequest, serverCallback: @escaping (URLRequest) -> (Data?, URLResponse?, Error?), callback: @escaping (Data?, URLResponse?, Error?) -> Void) {
        data = nil
        response = nil
        error = nil
        self.request = request
        self.serverCallback = serverCallback
        completionHandler = callback
    }
    
    public func resume() {
        // TODO: Maybe delay a bit?
        if let serverCallback = serverCallback,
            let request = request {
            let (data, response, error) = serverCallback(request)
            completionHandler(data, response, error)
        } else {
            completionHandler(data, response, error)
        }
    }
    
    public func cancel() {}
}
