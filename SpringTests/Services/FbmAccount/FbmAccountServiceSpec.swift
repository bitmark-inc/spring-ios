//
//  FbmAccountServiceSpec.swift
//  SpringTests
//
//  Created by Thuyen Truong on 1/30/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Quick
import Nimble
import Moya
import RxSwift
import RxTest
import Mockit

@testable import Spring

class FbmAccountServiceSpec: QuickSpec {

    override func spec() {
        AuthService.shared.provider = MoyaProvider<AuthAPI>(
            stubClosure: MoyaProvider.immediatelyStub,
            plugins: Global.default.networkLoggerPlugin)

        FbmAccountService.provider = MoyaProvider<FbmAccountAPI>(
            stubClosure: MoyaProvider.immediatelyStub,
            plugins: Global.default.networkLoggerPlugin)


        var scheduler: TestScheduler!
        var xcgLogger: XCGLoggerMock!

        describe(".create") {
            var result: TestableObserver<[String: String]>!
            let testFunction = { FbmAccountService.create(metadata: [:]) }

            beforeEach {
                scheduler = TestScheduler(initialClock: 0)
                xcgLogger = XCGLoggerMock(testCase: self)
                Global.log = xcgLogger
            }

            afterEach {
                Global.current =  Global()
            }

            context("currentAccount is nil") {
                beforeEach {
                    _ = scheduler.start {
                        testFunction().asObservable()
                    }
                }

                it("throws emptyCurrentAccount") {
                    xcgLogger.verify(verificationMode: Once())
                        .receive("error(_:functionName:fileName:lineNumber:userInfo:)") { (args) in
                            expect(args).notTo(beNil())
                            if let args = args {
                                expect(args[0] as? AppError).to(equal(AppError.emptyCurrentAccount))
                            }
                    }
                }
            }

            context("currentAccount isn't nil") {
                beforeEach {
                    Global.current.account = TestGlobal.account
                    result = scheduler.start {
                        testFunction().asObservable().map { ["accountNumber": $0.accountNumber, "metadata": $0.metadata] }
                    }
                }

                context("error when calling register") {
                }

                context("success when callign register") {
                    it("returns Single with FbmAccount object") {
                        xcgLogger.verify(verificationMode: Never()).error(AnyValue.string)

                        XCTAssertEqual(result.events, Recorded.events(
                            .next(200, ["accountNumber": TestGlobal.fbmAccount.accountNumber, "metadata": TestGlobal.fbmAccount.metadata]),
                            .completed(200)))
                    }
                }
            }
        }
    }
}
