//
//  BackgroundTaskManager.swift
//  Spring
//
//  Created by Thuyen Truong on 3/2/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Moya

enum SessionIdentifier: String {
    case upload = "com.bitmark.spring.background.upload"
    case download = "com.bitmark.spring.background.download"
}

class BackgroundTaskManager : NSObject, URLSessionDelegate, URLSessionDataDelegate {
    static var shared = BackgroundTaskManager()

    typealias ProgressHandler = (Float) -> ()
    typealias CompleteHandlerBlock = () -> ()

    var handlerQueue = [String : CompleteHandlerBlock]()

    let uploadProgressRelay = BehaviorRelay<[String: Event<ProgressInfo>?]>(value: [:])
    let uploadInfoRelay = BehaviorRelay<[String: String]>(value: [:]) // filename
    let disposeBag = DisposeBag()

    func urlSession(identifier: String) -> URLSession {
        let config = URLSessionConfiguration.background(withIdentifier: identifier)
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false

        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let identifier = session.configuration.identifier else { return }
        let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)

        let progressInfo = ProgressInfo(
            fractionCompleted: progress,
            totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)

        Global.log.debug("Progress \(identifier): \(progress)")
        uploadProgressRelay.accept([identifier: Event.next(progressInfo)])
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let identifier = session.configuration.identifier,
            let response = dataTask.response as? HTTPURLResponse else { return }

        Global.log.debug("Transfer Background Result: \(response.statusCode)")

        if 200 ... 299 ~= response.statusCode { // requests successfully
            uploadProgressRelay.accept([identifier: Event.completed])
        } else {
            let serverAPIError = data.convertServerAPIError()
            uploadProgressRelay.accept([identifier: Event.error(serverAPIError)])
        }
    }

    func addCompletionHandler(handler: @escaping CompleteHandlerBlock, identifier: String) {
        handlerQueue[identifier] = handler
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        guard let identifier = session.configuration.identifier,
            let completionHandler = handlerQueue[identifier] else {
                return
        }

        DispatchQueue.main.async {
           completionHandler()
        }
    }
}

