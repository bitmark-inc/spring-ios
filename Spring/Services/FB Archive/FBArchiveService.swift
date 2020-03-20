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
    static func submitByFile(_ fileURL: URL, with presignedURL: String)
    static func submitByURL(_ fileURL: URL) -> Completable
    static func getPresignedURL(with fileSize: Int64) -> Single<String>
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

    static func submitByFile(_ fileURL: URL, with presignedURL: String) {
        Global.log.info("[start] FBArchiveService.submitByFile")

        guard let url = URL(string: presignedURL) else {
            Global.log.info("presignedURL: \([presignedURL])")
            Global.log.error(AppError.invalidPresignedURL)
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.method = .put

        BackgroundTaskManager.shared
            .urlSession(identifier: SessionIdentifier.upload.rawValue)
            .uploadTask(with: urlRequest, fromFile: fileURL)
            .resume()

        BackgroundTaskManager.shared.uploadInfoRelay
            .accept([SessionIdentifier.upload.rawValue: fileURL.lastPathComponent])
        AppArchiveStatus.append(.uploading)
    }

    static func submitByURL(_ fileURL: URL) -> Completable {
        Global.log.info("[start] FBArchiveService.submitByURL")

        return provider.rx
            .requestWithRefreshJwt(.submitByURL(fileURL))
            .filterSuccess()
            .asCompletable()
    }

    static func getPresignedURL(with fileSize: Int64) -> Single<String> {
        Global.log.info("[start] FBArchiveService.getPresignedURL")

        return provider.rx
            .requestWithRefreshJwt(.getPresignedURL(fileSize))
            .filterSuccess()
            .map(PresignedURLResult.self, atKeyPath: "result")
            .map { $0.url }
    }

    static func getAll() -> Single<[Archive]> {
        Global.log.info("[start] getAll")

        return provider.rx
            .requestWithRefreshJwt(.getAll)
            .filterSuccess()
            .map([Archive].self, atKeyPath: "result", using: Global.default.decoder)
    }
}

struct PresignedURLResult: Decodable {
    let url: String
    let headers: [String: [String]]
}
