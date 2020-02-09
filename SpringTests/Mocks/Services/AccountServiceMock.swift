//
//  AccountServiceMock.swift
//  SpringTests
//
//  Created by Thuyen Truong on 2/3/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import XCTest
import Mockit
import RxSwift
import BitmarkSDK

@testable import Spring

class AccountServiceMock: AccountServiceDelegate, Mock {
    var callHandler: CallHandler

    func instanceType() -> AccountServiceMock {
        return self
    }

    init(callHandler: CallHandler) {
        self.callHandler = callHandler
    }

    static func registerIntercom(for accountNumber: String?, metadata: [String: String] = [:]) {
        testcaseCallHandler.accept(nil, ofFunction: #function, atFile: #file, inLine: #line, withArgs: accountNumber, metadata)
    }

    static func rxCreateNewAccount() -> Single<Account> {
        return testcaseCallHandler.accept(Single<Account>.never(), ofFunction: #function, atFile: #file, inLine: #line, withArgs: nil) as! Single<Account>
    }

    static func rxExistsCurrentAccount() -> Single<Account?> {
        return Single.just(TestGlobal.account)
    }

    static func rxGetAccount(phrases: [String]) -> Single<Account> {
        return Single.just(TestGlobal.account)
    }
}
