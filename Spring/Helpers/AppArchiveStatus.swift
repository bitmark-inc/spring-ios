//
//  AppArchiveStatus.swift
//  Spring
//
//  Created by Thuyen Truong on 3/8/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

enum AppArchiveStatus {
    case created
    case uploading
    case processing
    case processed
    case none
    case invalid([Int64], ArchiveMessageError?)

    static var localLatestArchiveStatus: AppArchiveStatus {
        return Global.current.userDefault?.latestAppArchiveStatus ?? .none
    }

    static var currentState = BehaviorRelay<AppArchiveStatus?>(value: localLatestArchiveStatus)
}

extension AppArchiveStatus: RawRepresentable {
    public typealias RawValue = String

    public init?(rawValue: RawValue) {
        switch rawValue {
        case "created":     self = .created
        case "uploading":   self = .uploading
        case "processing":  self = .processing
        case "processed":   self = .processed
        case "none":        self = .none
        case "invalid":     self = .invalid([], nil)
        default:
            return nil
        }
    }

    public var rawValue: RawValue {
        switch self {
        case .created:      return "created"
        case .uploading:    return "uploading"
        case .processing:   return "processing"
        case .processed:    return "processed"
        case .none:         return "none"
        case .invalid:      return "invalid"
        }
    }
}
