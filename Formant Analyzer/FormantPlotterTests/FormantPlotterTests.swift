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
        XCTAssertEqual(analyzerForBaseName("arm").vowelRange().location, 24407)
        XCTAssertEqual(analyzerForBaseName("beat").vowelRange().location, 29963)
        XCTAssertEqual(analyzerForBaseName("bid").vowelRange().location, 25147)
        XCTAssertEqual(analyzerForBaseName("calm").vowelRange().location, 30664)
        XCTAssertEqual(analyzerForBaseName("cat").vowelRange().location, 26093)
        XCTAssertEqual(analyzerForBaseName("four").vowelRange().location, 34964)
        XCTAssertEqual(analyzerForBaseName("who").vowelRange().location, 22332)

        XCTAssertEqual(analyzerForBaseName("arm").vowelRange().length, 9994)
        XCTAssertEqual(analyzerForBaseName("beat").vowelRange().length, 6086)
        XCTAssertEqual(analyzerForBaseName("bid").vowelRange().length, 6219)
        XCTAssertEqual(analyzerForBaseName("calm").vowelRange().length, 9707)
        XCTAssertEqual(analyzerForBaseName("cat").vowelRange().length, 12006)
        XCTAssertEqual(analyzerForBaseName("four").vowelRange().length, 9855)
        XCTAssertEqual(analyzerForBaseName("who").vowelRange().length, 9938)
    }
}
