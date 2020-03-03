//
//  FBArchiveService.swift
//  Spring
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import Moya
import Alamofire

protocol FBArchiveServiceDelegate {
    static func submit(headers: [String: String], fileURL: String, rawCookie: String, startedAt: Date?, endedAt: Date) -> Completable
    static func submitByFile(_ fileURL: URL)
    static func getAll() -> Single<[Archive]>
}

class FBArchiveService: FBArchiveServiceDelegate {

    static var provider = MoyaProvider<FBArchiveAPI>(plugins: Global.default.networkLoggerPlugin)
    static let disposeBag = DisposeBag()

    static func submit(headers: [String: String], fileURL: String, rawCookie: String, startedAt: Date?, endedAt: Date) -> Completable {
        Global.log.info("[start] submitFBArchive")

        return provider.rx
            .requestWithRefreshJwt(.submit(headers: headers, fileURL: fileURL, rawCookie: rawCookie, startedAt: startedAt, endedAt: endedAt))
            .filterSuccess()
            .asCompletable()
    }

    static func submitByFile(_ fileURL: URL) {
        Global.log.info("[start] FBArchiveService.submitByFile")

        AuthService.shared.jwtCompletable
            .do(onSubscribed: { AuthService.shared.mutexRefreshJwt() })
            .andThen(connectedToInternet())
            .subscribe(onCompleted: {
                guard let jwtToken = AuthService.shared.auth?.jwtToken,
                    let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
                        return
                }

                var urlRequest = URLRequest(url: URL(string: Constant.default.fBMServerURL + "/api/archives?type=facebook")!)
                urlRequest.method = .post
                urlRequest.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
                urlRequest.addValue("ios", forHTTPHeaderField: "Client-Type")
                urlRequest.addValue(bundleVersion, forHTTPHeaderField: "Client-Version")
                urlRequest.addValue("Bearer " + jwtToken, forHTTPHeaderField: "Authorization")

                BackgroundTaskManager.shared
                    .urlSession(identifier: SessionIdentifier.upload.rawValue)
                    .uploadTask(with: urlRequest, fromFile: fileURL)
                    .resume()

                BackgroundTaskManager.shared.uploadInfoRelay
                    .accept([SessionIdentifier.upload.rawValue: fileURL.lastPathComponent])
            }, onError: { (error) in
                guard !AppError.errorByNetworkConnection(error),
                    !Global.handleErrorIfAsAFError(error) else {
                        return
                }

                Global.log.error(error)
            })
            .disposed(by: disposeBag)
    }

    static func getAll() -> Single<[Archive]> {
        Global.log.info("[start] getAll")

        return provider.rx
            .requestWithRefreshJwt(.getAll)
            .filterSuccess()
            .map([Archive].self, atKeyPath: "result", using: Global.default.decoder)
    }
}
