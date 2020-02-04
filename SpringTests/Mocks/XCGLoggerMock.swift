//
//  XCGLoggerMock.swift
//  SpringTests
//
//  Created by Thuyen Truong on 1/31/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import XCTest
import Mockit
import XCGLogger
import Nimble

@testable import Spring

class XCGLoggerMock: XCGLogger, Mock {
    var callHandler: CallHandler

    func instanceType() -> XCGLoggerMock {
        return self
    }

    init(testCase: XCTestCase) {
      callHandler = CallHandlerImpl(withTestCase: testCase)
    }

    override func error(_ closure: @autoclosure () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {

        callHandler.accept(nil, ofFunction: #function, atFile: #file, inLine: #line, withArgs: closure())
    }
}

extension AppError: Equatable {
    public static func ==(lhs: AppError, rhs: AppError) -> Bool {
        return lhs.localizedDescription == rhs.localizedDescription
    }
}
