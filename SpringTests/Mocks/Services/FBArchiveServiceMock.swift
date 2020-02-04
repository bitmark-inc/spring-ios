//
//  FBArchiveServiceMock.swift
//  SpringTests
//
//  Created by Thuyen Truong on 2/3/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import XCTest
import Mockit
import RxSwift

@testable import Spring

var fbArchiveServiceMockInstance: FBArchiveServiceMock?

class FBArchiveServiceMock: FBArchiveServiceDelegate, Mock {
    var callHandler: CallHandler

    func instanceType() -> FBArchiveServiceMock {
        return self
    }

    init(testCase: XCTestCase) {
      callHandler = CallHandlerImpl(withTestCase: testCase)
    }

    static func submit(headers: [String: String], fileURL: String, rawCookie: String, startedAt: Date?, endedAt: Date) -> Completable {
        return fbArchiveServiceMockInstance!.submit(headers: headers, fileURL: fileURL, rawCookie: rawCookie, startedAt: startedAt, endedAt: endedAt)
    }

    func submit(headers: [String: String], fileURL: String, rawCookie: String, startedAt: Date?, endedAt: Date) -> Completable {
        return callHandler.accept(Completable.empty(), ofFunction: #function, atFile: #file, inLine: #line, withArgs: headers, fileURL, rawCookie, startedAt, endedAt) as! Completable
    }
}
