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

            context("currentAccount is nil") {
                beforeEach {
                    _ = accountServiceMock.when()
                        .call(withReturnValue: AccountServiceMock.rxCreateNewAccount())
                        .thenReturn(Single.just(TestGlobal.account))

                    testFunction()
                }

                afterEach {
                    Global.current =  Global()
                    try? KeychainStore.removeSeedCoreFromKeychain()
                }

                it("success to sign up and submit FBArchive") {
                    // creates account, register Intercom and setupCoreData
                    expect(Global.current.account != nil).to(beTrue())
                    accountServiceMock.verify(verificationMode: Once())
                        .receive("registerIntercom(for:metadata:)") { (args) in
                            expect(args).notTo(beNil())

                            if let args = args {
                                expect(args[0] as? String).to(equal("fHBAusHYNtMfKS2bJa7247z2DUtXY8CBpE5GY4TRQvE3bFSNi2"))
                                expect(args[1] as? [String: String]).to(equal([:]))
                            }
                        }

                    // submits the FB Archive to server
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

            context("currentAccount isn't nil") {
                context("sprintAccount's existed") {

                }

                context("springAccount's not existed") {

                }
            }

        }
    }
}
