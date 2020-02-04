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

var accountServiceMockInstance: AccountServiceMock?

class AccountServiceMock: AccountServiceDelegate, Mock {
    var callHandler: CallHandler

    func instanceType() -> AccountServiceMock {
        return self
    }

    init(testCase: XCTestCase) {
      callHandler = CallHandlerImpl(withTestCase: testCase)
    }

    static func registerIntercom(for accountNumber: String?, metadata: [String: String] = [:]) {
        accountServiceMockInstance?.registerIntercom(for: accountNumber, metadata: metadata)
    }

    static func rxCreateNewAccount() -> Single<Account> {
        return accountServiceMockInstance!.rxCreateNewAccount()
    }

    static func rxExistsCurrentAccount() -> Single<Account?> {
        return Single.just(TestGlobal.account)
    }

    static func rxGetAccount(phrases: [String]) -> Single<Account> {
        return Single.just(TestGlobal.account)
    }

    func registerIntercom(for accountNumber: String?, metadata: [String: String] = [:]) {
        callHandler.accept(nil, ofFunction: #function, atFile: #file, inLine: #line, withArgs: accountNumber, metadata)
    }

    func rxCreateNewAccount() -> Single<Account> {
        return callHandler.accept(Single<Account>.never(), ofFunction: #function, atFile: #file, inLine: #line, withArgs: nil) as! Single<Account>
    }

}
