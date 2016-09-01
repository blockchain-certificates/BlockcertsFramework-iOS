//
//  URLSession.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/1/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void

protocol URLSessionProtocol {
    func dataTask(with url: URL, completionHandler: DataTaskResult) -> URLSessionDataTask
}

extension URLSession : URLSessionProtocol {}
