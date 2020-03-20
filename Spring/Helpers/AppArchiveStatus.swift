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
    case requesting
    case uploading
    case processing
    case processed
    case none
    case invalid([Int64], ArchiveMessageError?)

    static var localLatestArchiveStatuses: [AppArchiveStatus] {
        return Global.current.userDefault?.latestAppArchiveStatus ?? []
    }

    static var currentState = BehaviorRelay<[AppArchiveStatus]>(value: localLatestArchiveStatuses)

    static func transfer(from oldStatus: AppArchiveStatus, to status: AppArchiveStatus) {
        guard let userDefaults = Global.current.userDefault else { return }
        var currentStatuses = userDefaults.latestAppArchiveStatus
        currentStatuses.removeAll(where: { $0 == oldStatus })
        currentStatuses.append(status)
        userDefaults.latestAppArchiveStatus = currentStatuses
    }

    static func append(_ status: AppArchiveStatus) {
        guard let userDefaults = Global.current.userDefault else { return }
        var currentStatuses = userDefaults.latestAppArchiveStatus
        currentStatuses.append(status)
        userDefaults.latestAppArchiveStatus = currentStatuses
    }

    static var isStartPoint: Bool {
        let statues = currentState.value

        if let firstStatus = statues.first {
            switch firstStatus {
            case .none, .created, .invalid: return true
            default:
                return false
            }
        } else {
            return true
        }
    }

    static var isRequestingPoint: Bool {
        return currentState.value
            .contains(where: { return $0 == .uploading || $0 == .requesting })
    }
}

extension AppArchiveStatus: RawRepresentable {
    public typealias RawValue = String

    public init?(rawValue: RawValue) {
        switch rawValue {
        case "created":     self = .created
        case "requesting":  self = .requesting
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
        case .requesting:   return "requesting"
        case .uploading:    return "uploading"
        case .processing:   return "processing"
        case .processed:    return "processed"
        case .none:         return "none"
        case .invalid:      return "invalid"
        }
    }
}

extension AppArchiveStatus: Equatable {
    
}
