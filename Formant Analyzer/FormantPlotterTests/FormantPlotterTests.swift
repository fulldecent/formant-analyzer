//
//  FormantPlotterTests.swift
//  FormantPlotterTests
//
//  Created by William Entriken on 11/17/15.
//  Copyright © 2015 William Entriken. All rights reserved.
//

import XCTest

class FormantPlotterTests: XCTestCase {
    
    var analyzers = [String: SpeechAnalyzer]()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func analyzerForBaseName(baseName: String) -> SpeechAnalyzer {
        if analyzers[baseName] == nil {
            let filePath = NSBundle.mainBundle().pathForResource(baseName, ofType: "raw")
            let speechData = NSData(contentsOfFile: filePath!)
            let analyzer = SpeechAnalyzer(data: speechData!)
            analyzers[baseName] = analyzer
        }
        return analyzers[baseName]!
    }
    
    func testTotalSamples() {
        XCTAssertEqual(analyzerForBaseName("arm").totalSamples(), 72704)
        XCTAssertEqual(analyzerForBaseName("beat").totalSamples(), 96667)
        XCTAssertEqual(analyzerForBaseName("bid").totalSamples(), 56832)
        XCTAssertEqual(analyzerForBaseName("calm").totalSamples(), 84992)
        XCTAssertEqual(analyzerForBaseName("cat").totalSamples(), 73728)
        XCTAssertEqual(analyzerForBaseName("four").totalSamples(), 74240)
        XCTAssertEqual(analyzerForBaseName("who").totalSamples(), 81920)
    }
    
    func testVowelRange() {
        XCTAssertEqual(analyzerForBaseName("arm").vowelRange().location, 24405)
        XCTAssertEqual(analyzerForBaseName("beat").vowelRange().location, 29961)
        XCTAssertEqual(analyzerForBaseName("bid").vowelRange().location, 25146)
        XCTAssertEqual(analyzerForBaseName("calm").vowelRange().location, 30662)
        XCTAssertEqual(analyzerForBaseName("cat").vowelRange().location, 26092)
        XCTAssertEqual(analyzerForBaseName("four").vowelRange().location, 34962)
        XCTAssertEqual(analyzerForBaseName("who").vowelRange().location, 22331)

        XCTAssertEqual(analyzerForBaseName("arm").vowelRange().length, 9993)
        XCTAssertEqual(analyzerForBaseName("beat").vowelRange().length, 6085)
        XCTAssertEqual(analyzerForBaseName("bid").vowelRange().length, 6217)
        XCTAssertEqual(analyzerForBaseName("calm").vowelRange().length, 9706)
        XCTAssertEqual(analyzerForBaseName("cat").vowelRange().length, 12004)
        XCTAssertEqual(analyzerForBaseName("four").vowelRange().length, 9854)
        XCTAssertEqual(analyzerForBaseName("who").vowelRange().length, 9936)
    }
}
