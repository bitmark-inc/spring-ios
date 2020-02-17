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
         .getDataGroupByType
         1: section is Post
            - returns correct data group by type
         2: section is Reaction
            - returns correct data group by type
         */
        describe(".getDataGroupByType") {
            var graphData: GraphData!
            var result: [(String, Double)]!

            context("section is Post") { // 1
                let numberOfUpdates = faker.number.randomDouble()
                let numberofMedias = faker.number.randomDouble()
                let numberOfLinks = faker.number.randomDouble()
                let testFunction = {
                    result = GraphDataConverter.getDataGroupByType(with: graphData, in: .post)
                }

                beforeEach {
                    graphData = GraphData(
                        name: nil,
                        data: ["media": numberofMedias,
                               "update": numberOfUpdates,
                               "link": numberOfLinks])
                    testFunction()
                }

                it("returns correct data group by type") {
                    expect({
                        let expectation = [
                            ("update", numberOfUpdates),
                            ("media", numberofMedias),
                            ("story", 0.0),
                            ("link", numberOfLinks)
                        ]

                        if result.count != expectation.count { return .failed(reason: "incorrect data group by type") }
                        for (index, element) in result.enumerated() {
                            if element != expectation[index] { return .failed(reason: "incorrect data group by type") }
                        }

                        return .succeeded
                    }).to(succeed())
                }
            }

            context("section is Reaction") { // 2
                let numberOfLikes = faker.number.randomDouble()
                let numberofHahas = faker.number.randomDouble()
                let testFunction = {
                    result = GraphDataConverter.getDataGroupByType(with: graphData, in: .reaction)
                }

                beforeEach {
                    graphData = GraphData(
                        name: nil,
                        data: ["LIKE": numberOfLikes,
                               "HAHA": numberofHahas])
                    testFunction()
                }

                it("returns correct data group by type") {
                    expect({
                        let expectation = [
                            ("LIKE", numberOfLikes),
                            ("LOVE", 0.0),
                            ("HAHA", numberofHahas),
                            ("WOW", 0.0),
                            ("SORRY", 0.0),
                            ("ANGER", 0.0)
                        ]

                        if result.count != expectation.count { return .failed(reason: "incorrect data group by type") }
                        for (index, element) in result.enumerated() {
                            if element != expectation[index] { return .failed(reason: "incorrect data group by type") }
                        }

                        return .succeeded
                    }).to(succeed())
                }
            }
        }

        /**
        .getDataGroupByDay
        1: section is Post
            1.1: timeUnit is week
            1.2: timeUnit is year
            1.3: timeUnit is decade
        2: section is Reaction
           - returns correct data group by type
        */
        describe(".getDataGroupByDay") {
            var graphDatas: [GraphData]!
            var result: [Date: (String, [Double])]!

            context("section is Post") { // 1
                let numberOfUpdates1 = faker.number.randomDouble()
                let numberOfUpdates2 = faker.number.randomDouble()
                let numberofMedias1 = faker.number.randomDouble()
                let numberofMedias2 = faker.number.randomDouble()
                let numberofMedias3 = faker.number.randomDouble()
                let numberOfLinks = faker.number.randomDouble()

                let testFunction = { (timeUnit, startDate) in
                    result = GraphDataConverter.getDataGroupByDay(with: graphDatas, timeUnit: timeUnit, startDate: startDate, in: .post)
                }

                context("timeUnit is week") { // 1.1
                    beforeEach {
                        graphDatas = [
                            GraphData(name: String(Date("2020-02-17")!.appTimeFormat), data: ["update": numberOfUpdates1, "media": numberofMedias1]),
                            GraphData(name: String(Date("2020-02-18")!.appTimeFormat), data: ["link": numberOfLinks, "update": numberOfUpdates2]),
                            GraphData(name: String(Date("2020-02-20")!.appTimeFormat), data: ["media": numberofMedias2]),
                            GraphData(name: String(Date("2020-02-21")!.appTimeFormat), data: ["media": numberofMedias3])
                        ]
                        testFunction(.week, Date("2020-02-17")!)
                    }

                    it("returns correct data group by day") {
                        expect({
                            let expectationResult: [Date: (String, [Double])] = [
                                Date("2020-02-17")!: ("M", [numberOfUpdates1, numberofMedias1, 0.0, 0.0]),
                                Date("2020-02-18")!: ("T", [numberOfUpdates2, 0.0, 0.0, numberOfLinks]),
                                Date("2020-02-19")!: ("W", [0.0, 0.0, 0.0, 0.0]),
                                Date("2020-02-20")!: ("T", [0.0, numberofMedias2, 0.0, 0.0]),
                                Date("2020-02-21")!: ("F", [0.0, numberofMedias3, 0.0, 0.0]),
                                Date("2020-02-22")!: ("S", [0.0, 0.0, 0.0, 0.0]),
                                Date("2020-02-23")!: ("S", [0.0, 0.0, 0.0, 0.0])
                            ]

                            if result.count != expectationResult.count {
                                return .failed(reason: "incorrect data group by day")
                            }

                            for (key, value) in result {
                                guard let expect = expectationResult[key] else {
                                    return .failed(reason: "incorrect data group by day")
                                }
                                if value != expect {
                                    return .failed(reason: "incorrect data group by day")
                                }
                            }

                            return .succeeded
                        }).to(succeed())
                    }
                }

                context("timeUnit is year") { // 1.2
                    beforeEach {
                        graphDatas = [
                            GraphData(name: String(Date("2020-01-01")!.appTimeFormat), data: ["update": numberOfUpdates1, "media": numberofMedias1]),
                            GraphData(name: String(Date("2020-06-01")!.appTimeFormat), data: ["link": numberOfLinks, "update": numberOfUpdates2]),
                            GraphData(name: String(Date("2020-07-01")!.appTimeFormat), data: ["media": numberofMedias2]),
                            GraphData(name: String(Date("2020-12-01")!.appTimeFormat), data: ["media": numberofMedias3])
                        ]
                        testFunction(.year, Date("2020-01-01")!)
                    }

                    it("returns correct data group by day") {
                        expect({
                            let expectationResult: [Date: (String, [Double])] = [
                                Date("2020-01-01")!: ("J", [numberOfUpdates1, numberofMedias1, 0.0, 0.0]),
                                Date("2020-02-01")!: ("F", [0.0, 0.0, 0.0, 0.0]),
                                Date("2020-03-01")!: ("M", [0.0, 0.0, 0.0, 0.0]),
                                Date("2020-04-01")!: ("A", [0.0, 0.0, 0.0, 0.0]),
                                Date("2020-05-01")!: ("M", [0.0, 0.0, 0.0, 0.0]),
                                Date("2020-06-01")!: ("J", [numberOfUpdates2, 0.0, 0.0, numberOfLinks]),
                                Date("2020-07-01")!: ("J", [0.0, numberofMedias2, 0.0, 0.0]),
                                Date("2020-08-01")!: ("A", [0.0, 0.0, 0.0, 0.0]),
                                Date("2020-09-01")!: ("S", [0.0, 0.0, 0.0, 0.0]),
                                Date("2020-10-01")!: ("O", [0.0, 0.0, 0.0, 0.0]),
                                Date("2020-11-01")!: ("N", [0.0, 0.0, 0.0, 0.0]),
                                Date("2020-12-01")!: ("D", [0.0, numberofMedias3, 0.0, 0.0])
                            ]

                            if result.count != expectationResult.count {
                                return .failed(reason: "incorrect data group by day")
                            }

                            for (key, value) in result {
                                guard let expect = expectationResult[key] else {
                                    return .failed(reason: "incorrect data group by day")
                                }
                                if value != expect {
                                    return .failed(reason: "incorrect data group by day")
                                }
                            }

                            return .succeeded
                        }).to(succeed())
                    }
                }

                context("timeUnit is decade") { // 1.3
                    beforeEach {
                        graphDatas = [
                            GraphData(name: String(Date("2020-01-01")!.appTimeFormat), data: ["update": numberOfUpdates1, "media": numberofMedias1]),
                            GraphData(name: String(Date("2024-01-01")!.appTimeFormat), data: ["link": numberOfLinks, "update": numberOfUpdates2]),
                            GraphData(name: String(Date("2027-01-01")!.appTimeFormat), data: ["media": numberofMedias2]),
                            GraphData(name: String(Date("2021-01-01")!.appTimeFormat), data: ["media": numberofMedias3])
                        ]
                        testFunction(.decade, Date("2020-01-01")!)
                    }

                    it("returns correct data group by day") {
                        expect({
                            let expectationResult: [Date: (String, [Double])] = [
                                Date("2020-01-01")!: ("20", [numberOfUpdates1, numberofMedias1, 0.0, 0.0]),
                                Date("2021-01-01")!: ("21", [0.0, numberofMedias3, 0.0, 0.0]),
                                Date("2022-01-01")!: ("22", [0.0, 0.0, 0.0, 0.0]),
                                Date("2023-01-01")!: ("23", [0.0, 0.0, 0.0, 0.0]),
                                Date("2024-01-01")!: ("24", [numberOfUpdates2, 0.0, 0.0, numberOfLinks]),
                                Date("2025-01-01")!: ("25", [0.0, 0.0, 0.0, 0.0]),
                                Date("2026-01-01")!: ("26", [0.0, 0.0, 0.0, 0.0]),
                                Date("2027-01-01")!: ("27", [0.0, numberofMedias2, 0.0, 0.0]),
                                Date("2028-01-01")!: ("28", [0.0, 0.0, 0.0, 0.0]),
                                Date("2029-01-01")!: ("29", [0.0, 0.0, 0.0, 0.0]),
                            ]

                            if result.count != expectationResult.count {
                                return .failed(reason: "incorrect data group by day")
                            }

                            for (key, value) in result {
                                guard let expect = expectationResult[key] else {
                                    return .failed(reason: "incorrect data group by day")
                                }
                                if value != expect {
                                    return .failed(reason: "incorrect data group by day")
                                }
                            }

                            return .succeeded
                        }).to(succeed())
                    }
                }
            }
        }

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
