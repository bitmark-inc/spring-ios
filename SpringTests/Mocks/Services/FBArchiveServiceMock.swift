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

class FBArchiveServiceMock: FBArchiveServiceDelegate, Mock {
    var callHandler: CallHandler

    func instanceType() -> FBArchiveServiceMock {
        return self
    }

    init(callHandler: CallHandler) {
        self.callHandler = callHandler
    }

    static func submit(headers: [String: String], fileURL: String, rawCookie: String, startedAt: Date?, endedAt: Date) -> Completable {
        return testcaseCallHandler.accept(Completable.empty(), ofFunction: #function, atFile: #file, inLine: #line, withArgs: headers, fileURL, rawCookie, startedAt, endedAt) as! Completable
    }
}
