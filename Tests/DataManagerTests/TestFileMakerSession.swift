//
//  TestFileMakerSession.swift
//  DataManagerTests
//
//  Created by manager on 2020/09/25.
//

import XCTest
@testable import DataManager

class TestFileMakerSession: XCTestCase {
    func testClampWaitTime() {
        let maxTime = FileMakerSession.maxWaitTime
        let minTime = FileMakerSession.minWaitTime
        let middleTime = (maxTime + minTime) / 2
        XCTAssertEqual(FileMakerSession.clampWaitTime(minTime-1.0), minTime)
        XCTAssertEqual(FileMakerSession.clampWaitTime(maxTime+1.0), maxTime)
        XCTAssertEqual(FileMakerSession.clampWaitTime(middleTime), middleTime)
    }
}
