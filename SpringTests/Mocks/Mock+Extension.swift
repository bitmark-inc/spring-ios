//
//  Mock+Extension.swift
//  SpringTests
//
//  Created by Thuyen Truong on 2/4/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import Mockit

extension Mock {
    func receive(_ functionName: String, callOrder order: Int = 1, completionHandler: @escaping (_ args: [Any?]?) -> Void) {
        callHandler.accept(nil, ofFunction: functionName, atFile: #file, inLine: #line, withArgs: [])
        _ = getArgs(callOrder: order)
        callHandler.accept(nil, ofFunction: functionName, atFile: #file, inLine: #line, withArgs: [])
        completionHandler(callHandler.argumentsOfSpecificCall)
    }
}
