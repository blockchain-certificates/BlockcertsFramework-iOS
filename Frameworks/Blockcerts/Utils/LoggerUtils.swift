//
// Created by Javier Moreno on 2019-02-13.
// Copyright (c) 2019 Digital Certificates Project. All rights reserved.
//

import Foundation

public protocol LoggerProtocol {
    func tag(_ tag : String?) -> LoggerProtocol
    func info(_ message: String)
    func debug(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)
}

public class DefaultLogger : LoggerProtocol {
    var tag = ""

    public func tag(_ tag: String?) -> LoggerProtocol {
        self.tag = tag ?? ""
        return self
    }

    public func info(_ message : String) {
        log("info", message)
    }

    public func debug(_ message : String) {
        log("debug", message)
    }

    public func warning(_ message : String) {
        log("warning", message)
    }

    public func error(_ message : String) {
        log("error", message)
    }

    private func log(_ level : String, _ message : String) {
        let date = Date()
        print("[\(date)] \(level)/\(tag): \(message)")
        tag = ""
    }
}
