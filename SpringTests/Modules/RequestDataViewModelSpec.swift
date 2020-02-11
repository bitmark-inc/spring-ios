//
//  RequestDataViewModelSpec.swift
//  SpringTests
//
//  Created by Thuyen Truong on 2/3/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Quick
import Nimble
import Moya
import RxSwift
import RxTest
import RxBlocking
import Mockit

@testable import Spring

class RequestDataViewModelSpec: QuickSpec {

    /**
     .signUpAndSubmitFBArchive
        1: currentUser is nil
            1.1 UserDefaults.standard.FBArchiveCreatedAt = nil
                -> creates Bitmark account; setup intercom & data
                -> creates FBM Spring; submits Facebook archive
                -> updates completed result into signUpAndSubmitArchiveResultSubject
            1.2: value in UserDefaults.standard.FBArchiveCreatedAt
                -> submits Facebook archive; updates completed result into signUpAndSubmitArchiveResultSubject
            1.3: call create Spring account returns error
                -> updates error result into signUpAndSubmitArchiveResultSubject
        2: currentUser is not nil
            2.1: Spring account is available
            2.2: Spring account has been taken
                -> doesn't call create Bitmark acccount; setup intecom & data
                -> submits Facebook archive
                -> updates completed result into signUpAndSubmitArchiveResultSubject
     */
    override func spec() {
        var viewModel: RequestDataViewModel!
        var accountServiceMock: AccountServiceMock!
        var fbArchiveServiceMock: FBArchiveServiceMock!
        var signUpAndSubmitArchiveResultObserver: TestableObserver<Event<Swift.Never>>!

        var scheduler: TestScheduler!
        var disposeBag: DisposeBag!

        AuthService.shared.provider = MoyaProvider<AuthAPI>(
            stubClosure: MoyaProvider.immediatelyStub,
            plugins: Global.default.networkLoggerPlugin)

        FbmAccountService.provider = MoyaProvider<FbmAccountAPI>(
            stubClosure: MoyaProvider.immediatelyStub,
            plugins: Global.default.networkLoggerPlugin)

        describe(".signUpAndSubmitFBArchive") {
            let headers = [faker.lorem.word(): faker.lorem.sentence()]
            let archiveURL = URL(string: "https://bitmark.com")!
            let rawCookie = faker.lorem.sentence(wordsAmount: 10)

            let testFunction = {
                signUpAndSubmitArchiveResultObserver = scheduler.createObserver(Event<Swift.Never>.self)

                viewModel.signUpAndSubmitArchiveResultSubject
                    .bind(to: signUpAndSubmitArchiveResultObserver)
                    .disposed(by: disposeBag)

                viewModel.signUpAndSubmitFBArchive(headers: headers, archiveURL: archiveURL, rawCookie: rawCookie)
            }

            beforeEach {
                testcaseCallHandler = CallHandlerImpl(withTestCase: self)
                RequestDataViewModel.AccountServiceBase = AccountServiceMock.self
                RequestDataViewModel.FBArchiveServiceBase = FBArchiveServiceMock.self
                RequestDataViewModel.FbmAccountDataEngineBase = FbmAccountDataEngineMock.self
                viewModel = RequestDataViewModel(missions: [])

                accountServiceMock = AccountServiceMock(callHandler: testcaseCallHandler)
                fbArchiveServiceMock = FBArchiveServiceMock(callHandler: testcaseCallHandler)

                scheduler = TestScheduler(initialClock: 0)
                disposeBag = DisposeBag()
            }

            afterEach {
                Global.current =  Global()
                try? KeychainStore.removeSeedCoreFromKeychain()
            }

            // 1
            context("currentUser is nil") {
                beforeEach {
                    _ = accountServiceMock.when()
                        .call(withReturnValue: AccountServiceMock.rxCreateNewAccount())
                        .thenReturn(Single.just(TestGlobal.account))
                }

                // 1.1
                context("UserDefaults.standard.FBArchiveCreatedAt = nil") {
                    beforeEach {
                        UserDefaults.standard.FBArchiveCreatedAt = nil
                        testFunction()
                    }

                    it("creates Bitmark account; setup intercom & data") {
                        expect(Global.current.account != nil).to(beTrue())
                        accountServiceMock.verify(verificationMode: Once())
                            .receive("registerIntercom(for:metadata:)") { (args) in
                                expect(args).notTo(beNil())

                                if let args = args {
                                    expect(args[0] as? String).to(equal("fHBAusHYNtMfKS2bJa7247z2DUtXY8CBpE5GY4TRQvE3bFSNi2"))
                                    expect(args[1] as? [String: String]).to(equal([:]))
                                }
                            }
                    }

                    it("creates FBM Spring; submits Facebook archive") {
                        fbArchiveServiceMock.verify(verificationMode: Once())
                            .receive("submit(headers:fileURL:rawCookie:startedAt:endedAt:)") { (args) in
                                expect(args).notTo(beNil())

                                if let args = args {
                                    expect(args[0] as? [String: String]).to(equal(headers))
                                    expect(args[1] as? String).to(equal(archiveURL.absoluteString))
                                    expect(args[2] as? String).to(equal(rawCookie))
                                    expect(args[3] as? Date).to(beNil())
                                }
                        }
                    }

                    it("updates completed result into signUpAndSubmitArchiveResultSubject") {
                        expect(signUpAndSubmitArchiveResultObserver.events).to(equal([.next(0, .completed)]))
                    }
                }

                // 1.2
                context("value in UserDefaults.standard.FBArchiveCreatedAt") {
                    beforeEach {
                        UserDefaults.standard.FBArchiveCreatedAt = Date()
                        testFunction()
                    }

                    it("submits Facebook archive; updates completed result into signUpAndSubmitArchiveResultSubject") {
                        fbArchiveServiceMock.verify(verificationMode: Once())
                            .receive("submit(headers:fileURL:rawCookie:startedAt:endedAt:)") { (args) in
                                expect(args).notTo(beNil())

                                if let args = args {
                                    expect(args[0] as? [String: String]).to(equal(headers))
                                    expect(args[1] as? String).to(equal(archiveURL.absoluteString))
                                    expect(args[2] as? String).to(equal(rawCookie))
                                    expect(args[3] as? Date).to(beNil())
                                }
                        }
                        expect(signUpAndSubmitArchiveResultObserver.events).to(equal([.next(0, .completed)]))
                    }
                }

                // 1.3
                context("call create Spring account returns error") {
                    beforeEach {
                        FbmAccountService.provider = MoyaProvider<FbmAccountAPI>(endpointClosure: TestGlobal.serverErrorClosure,
                                                                                 stubClosure: MoyaProvider.immediatelyStub,
                                                                                 plugins: Global.default.networkLoggerPlugin)
                        testFunction()
                    }

                    afterEach {
                        FbmAccountService.provider = MoyaProvider<FbmAccountAPI>(
                            stubClosure: MoyaProvider.immediatelyStub,
                            plugins: Global.default.networkLoggerPlugin)
                    }

                    it("updates error result into signUpAndSubmitArchiveResultSubject") {
                        let actual = signUpAndSubmitArchiveResultObserver.events.first
                        expect({
                            switch actual?.value.element {
                            case .error: return .succeeded
                            default: return .failed(reason: "should emit Event.error")
                            }
                        }).to(succeed())
                    }
                }
            }

            // 2
            context("currentUser is not nil") {
                beforeEach {
                    Global.current.account = TestGlobal.account
                }

                // 2.1
                context("Spring account is available") {
                    beforeEach {
                        FbmAccountService.provider = MoyaProvider<FbmAccountAPI>(endpointClosure: TestGlobal.accountHasTakenErrorClosure,
                                                                                 stubClosure: MoyaProvider.immediatelyStub,
                                                                                 plugins: Global.default.networkLoggerPlugin)
                        testFunction()
                    }

                    afterEach {
                        FbmAccountService.provider = MoyaProvider<FbmAccountAPI>(
                            stubClosure: MoyaProvider.immediatelyStub,
                            plugins: Global.default.networkLoggerPlugin)
                    }

                    it("doesn't call create Bitmark acccount; setup intecom & data") {
                        expect(Global.current.account != nil).to(beTrue())
                        accountServiceMock.verify(verificationMode: Never()).receive("registerIntercom(for:metadata:)")
                    }

                    it("submits Facebook archive") {
                        fbArchiveServiceMock.verify(verificationMode: Once())
                            .receive("submit(headers:fileURL:rawCookie:startedAt:endedAt:)") { (args) in
                                expect(args).notTo(beNil())

                                if let args = args {
                                    expect(args[0] as? [String: String]).to(equal(headers))
                                    expect(args[1] as? String).to(equal(archiveURL.absoluteString))
                                    expect(args[2] as? String).to(equal(rawCookie))
                                    expect(args[3] as? Date).to(beNil())
                                }
                        }
                    }

                    it("updates result into signUpAndSubmitArchiveResultSubject") {
                        expect(signUpAndSubmitArchiveResultObserver.events).to(equal([.next(0, .completed)]))
                    }
                }

                // 2.2
                context("Spring account has been taken") {
                    beforeEach {
                        UserDefaults.standard.FBArchiveCreatedAt = Date()
                        testFunction()
                    }

                    it("doesn't call create Bitmark acccount; setup intecom & data") {
                        expect(Global.current.account != nil).to(beTrue())
                        accountServiceMock.verify(verificationMode: Never()).receive("registerIntercom(for:metadata:)")
                    }

                    it("submits Facebook archive") {
                        fbArchiveServiceMock.verify(verificationMode: Once())
                            .receive("submit(headers:fileURL:rawCookie:startedAt:endedAt:)") { (args) in
                                expect(args).notTo(beNil())

                                if let args = args {
                                    expect(args[0] as? [String: String]).to(equal(headers))
                                    expect(args[1] as? String).to(equal(archiveURL.absoluteString))
                                    expect(args[2] as? String).to(equal(rawCookie))
                                    expect(args[3] as? Date).to(beNil())
                                }
                        }
                    }

                    it("updates result into signUpAndSubmitArchiveResultSubject") {
                        expect(signUpAndSubmitArchiveResultObserver.events).to(equal([.next(0, .completed)]))
                    }
                }
            }
        }
    }
}
