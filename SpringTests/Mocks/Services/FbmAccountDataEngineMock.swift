//
//  FbmAccountDataEngineMock.swift
//  SpringTests
//
//  Created by thuyentruong on 2/9/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import XCTest
import Mockit
import RxSwift
import BitmarkSDK

@testable import Spring

class FbmAccountDataEngineMock: FbmAccountDataEngineDelegate, Mock {
    var callHandler: CallHandler

    func instanceType() -> FbmAccountDataEngineMock {
        return self
    }

    init(callHandler: CallHandler) {
        self.callHandler = callHandler
    }

    static func fetchCurrentFbmAccount() -> Single<FbmAccount> {
        return testcaseCallHandler.accept(
            Single<FbmAccount>.just(TestGlobal.fbmAccount),
            ofFunction: #function, atFile: #file, inLine: #line, withArgs: nil) as! Single
    }

    static func fetchLocalFbmAccount() -> Single<FbmAccount?> {
        return testcaseCallHandler.accept(
            Single<FbmAccount>.just(TestGlobal.fbmAccount),
            ofFunction: #function, atFile: #file, inLine: #line, withArgs: nil) as! Single
    }

    static func fetchLatestFbmAccount() -> Single<FbmAccount> {
        return testcaseCallHandler.accept(
            Single<FbmAccount>.just(TestGlobal.fbmAccount),
            ofFunction: #function, atFile: #file, inLine: #line, withArgs: nil) as! Single
    }

    static func create() -> Single<FbmAccount> {
        return testcaseCallHandler.accept(
            Single<FbmAccount>.just(TestGlobal.fbmAccount),
            ofFunction: #function, atFile: #file, inLine: #line, withArgs: nil) as! Single
    }

    static func fetchOverallArchiveStatus() -> Single<ArchiveStatus?> {
        return testcaseCallHandler.accept(
            Single<ArchiveStatus?>.just(nil),
            ofFunction: #function, atFile: #file, inLine: #line, withArgs: nil) as! Single
    }
}
