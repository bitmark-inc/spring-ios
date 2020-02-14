//
//  GraphDataConverterSpec.swift
//  SpringTests
//
//  Created by Thuyen Truong on 2/14/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Quick
import Nimble
import SwiftDate

@testable import Spring

class GraphDataConverterSpec: QuickSpec {

    override func spec() {

        /**
         .getStats
         1: section is Post
            1.1: data has redundant keys & missing key
                - contains enough all keys to view in graph; remove 'story'; remove redundant key
                - correct statsData & missing key's value is initted with StatsData(sysAvg: 0, count: 0)
            1.2: data is 0
                - returns nil
         2: section is Reaction
            2.1: 1.1: data has redundant keys & missing key
                - contains enough all keys to view in graph; remove redundant key
                - correct statsData & missing key's value is initted with StatsData(sysAvg: 0, count: 0)
            2.2: data is 0
                - returns nil
        */
        describe(".getStats") {
            var statsGroup: StatsGroups!
            var result: [(name: String, data: StatsData)]?

            context("section is Post") { // 1
                let testFunction = {
                    result = GraphDataConverter.getStats(with: statsGroup, in: .post)
                }
                context("data has redundant keys & missing key") { // 1.1
                    let sysAvgOfUpdate = faker.number.randomDouble()
                    let countOfUpdate = faker.number.randomDouble()
                    let sysAvgOfMedia = faker.number.randomDouble()
                    let countOfMedia = faker.number.randomDouble()

                    beforeEach {
                        statsGroup = [
                            "update": StatsData(sysAvg: sysAvgOfUpdate, count: countOfUpdate),
                            "media": StatsData(sysAvg: sysAvgOfMedia, count: countOfMedia),
                            "undefined": StatsData(sysAvg: 19.35353, count: 67)
                        ]
                        testFunction()
                    }

                    it("contains enough all keys to view in graph; remove 'story'; remove redundant key") {
                        expect(result).notTo(beNil())
                        if let result = result {
                            expect(result.compactMap { $0.name }).to(equal(["update", "media", "link"]))
                        }
                    }

                    it("correct statsData & missing key's value is initted with StatsData(sysAvg: 0, count: 0)") {
                        if let result = result {
                            expect({
                                let updateData = result[0].data
                                if updateData.sysAvg == sysAvgOfUpdate && updateData.count == countOfUpdate {
                                    return .succeeded
                                } else {
                                    return .failed(reason: "incorrect update stats")
                                }
                            }).to(succeed())

                            expect({
                                let mediaData = result[1].data
                                if mediaData.sysAvg == sysAvgOfMedia && mediaData.count == countOfMedia {
                                    return .succeeded
                                } else {
                                    return .failed(reason: "incorrect media stats")
                                }
                            }).to(succeed())

                            expect({
                                let linkData = result[2].data
                                if linkData.sysAvg == 0 && linkData.count == 0 {
                                    return .succeeded
                                } else {
                                    return .failed(reason: "incorrect link stats")
                                }
                            }).to(succeed())
                        }
                    }
                }

                context("data is 0") { // 1.2
                    beforeEach {
                        statsGroup = [
                            "update": StatsData(sysAvg: 0, count: 0),
                            "media": StatsData(sysAvg: 0, count: 0),
                            "undefined": StatsData(sysAvg: 20, count: 10)
                        ]
                        testFunction()
                    }

                    it("returns nil") {
                        expect(result).to(beNil())
                    }
                }
            }

            context("section is Reaction") { // 2
                let testFunction = {
                    result = GraphDataConverter.getStats(with: statsGroup, in: .reaction)
                }
                context("data has redundant keys & missing key") { // 2.1
                    let sysAvgOfLike = faker.number.randomDouble()
                    let countOfLike = faker.number.randomDouble()
                    let sysAvgOfHaha = faker.number.randomDouble()
                    let countOfHaha = faker.number.randomDouble()

                    beforeEach {
                        statsGroup = [
                            "LIKE": StatsData(sysAvg: sysAvgOfLike, count: countOfLike),
                            "HAHA": StatsData(sysAvg: sysAvgOfHaha, count: countOfHaha),
                            "UNDEFINED": StatsData(sysAvg: 19.35353, count: 67)
                        ]
                        testFunction()
                    }

                    it("contains enough all keys to view in graph; remove redundant key") {
                        expect(result).notTo(beNil())
                        if let result = result {
                            expect(result.compactMap { $0.name }).to(equal(["LIKE", "LOVE", "HAHA", "WOW", "SORRY", "ANGER"]))
                        }
                    }

                    it("correct statsData & missing key's value is initted with StatsData(sysAvg: 0, count: 0)") {
                        if let result = result {
                            expect({
                                let LIKEData = result[0].data
                                if LIKEData.sysAvg == sysAvgOfLike && LIKEData.count == countOfLike {
                                    return .succeeded
                                } else {
                                    return .failed(reason: "incorrect LIKE stats")
                                }
                            }).to(succeed())

                            expect({
                                let LOVEData = result[1].data
                                if LOVEData.sysAvg == 0 && LOVEData.count == 0 {
                                    return .succeeded
                                } else {
                                    return .failed(reason: "incorrect LOVE stats")
                                }
                            }).to(succeed())

                            expect({
                                let HAHAData = result[2].data
                                if HAHAData.sysAvg == sysAvgOfHaha && HAHAData.count == countOfHaha {
                                    return .succeeded
                                } else {
                                    return .failed(reason: "incorrect HAHA stats")
                                }
                            }).to(succeed())

                            expect({
                                let WOWData = result[3].data
                                if WOWData.sysAvg == 0 && WOWData.count == 0 {
                                    return .succeeded
                                } else {
                                    return .failed(reason: "incorrect WOW stats")
                                }
                            }).to(succeed())

                            expect({
                                let SorryData = result[4].data
                                if SorryData.sysAvg == 0 && SorryData.count == 0 {
                                    return .succeeded
                                } else {
                                    return .failed(reason: "incorrect SORRY stats")
                                }
                            }).to(succeed())

                            expect({
                                let AngerData = result[4].data
                                if AngerData.sysAvg == 0 && AngerData.count == 0 {
                                    return .succeeded
                                } else {
                                    return .failed(reason: "incorrect ANGER stats")
                                }
                            }).to(succeed())
                        }
                    }
                }

                context("data is 0") { // 1.2
                    beforeEach {
                        statsGroup = [
                            "LIKE": StatsData(sysAvg: 0, count: 0),
                            "HAHA": StatsData(sysAvg: 0, count: 0),
                            "undefined": StatsData(sysAvg: 20, count: 10)
                        ]
                        testFunction()
                    }

                    it("returns nil") {
                        expect(result).to(beNil())
                    }
                }
            }
        }
    }
}
