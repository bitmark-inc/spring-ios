//
//  TestData.swift
//  SpringTests
//
//  Created by Thuyen Truong on 2/4/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import Fakery
import BitmarkSDK
import Mockit

@testable import Spring

let faker = Faker(locale: "nb-NO")
var testcaseCallHandler: CallHandler!

struct TestGlobal {
    static let fbmAccount: FbmAccount = {
        let fbmAccount = FbmAccount()
        fbmAccount.accountNumber = "fHBAusHYNtMfKS2bJa7247z2DUtXY8CBpE5GY4TRQvE3bFSNi2"
        fbmAccount.metadata = "{\"last_activity_timestamp\":1579161810,\"fb-identifier\":\"9cb1c1dd0c02a76d3881fd288cfc0033d162d05e915ef522b49a96f3abe6d5a1\"}"
        fbmAccount.createdAt = "2020-01-20T03:42:30.671426Z".toDate()!.date
        fbmAccount.updatedAt = "2020-01-20T03:42:30.671426Z".toDate()!.date
        return fbmAccount
    }()

    static let account: Account = {
        let seedString = "9J87BSeH4cpWiWyUodcCZddPCaWW7uxTq"
        return try! Account(fromSeed: seedString)
    }()
}
