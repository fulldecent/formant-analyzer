//
//  SpeechAnalyzerTests.swift
//  FormantPlotter
//
//  Created by Full Decent on 1/24/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import XCTest
@testable import Formant_Analyzer

class SpeechAnalyzerTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    var analyzers: [String: SpeechAnalyzer] = {
        var retval = [String: SpeechAnalyzer]()
        for file in Bundle.main.urls(forResourcesWithExtension: "raw", subdirectory: nil)! {
            let baseName = file.deletingPathExtension().lastPathComponent
            let speechData = NSData(contentsOf: file)!
            let analyzer = SpeechAnalyzer(int16Samples: speechData as Data, withFrequency: 44100)
            retval[baseName] = analyzer
        }
        return retval
    }()
    
    func testSamplesCount() {
        let testData = [
            "arm": 72704,
            "beat": 96667,
            "bid": 56832,
            "calm": 84992,
            "cat": 73728,
            "four": 74240,
            "who": 81920
        ]
        for (file, expectedResult) in testData {
            print("Testing \(file)")
            XCTAssertEqual(analyzers[file]!.samples.count, expectedResult)
        }
    }
    
    func testFindStrongPartOfSignal() {
        let testData = [
            // This is MATLAB results all minus one (MATLAB uses 1-indexing for arrays, Swift uses 0)
            ("arm",  22264 ..< 36542),
            ("beat", 28658 ..< 37352),
            ("bid",  23814 ..< 32697),
            ("calm", 28583 ..< 42450),
            ("cat",  23520 ..< 40670),
            ("four", 32851 ..< 46930),
            ("who",  20202 ..< 34398)
        ]
        for (file, expectedResult) in testData {
            let samples = analyzers[file]!.samples
            let strongPart = SpeechAnalyzer.findStrongPartOfSignal(samples, withChunks: 300, sensitivity: 0.1)
            print("Testing \(file)")
            XCTAssertEqual(strongPart.startIndex, expectedResult.startIndex)
            XCTAssertEqual(strongPart.count, expectedResult.count)
        }
    }
    
    func testTruncateTailsOfRange() {
        let testData = [
            // This is MATLAB results all minus one (MATLAB uses 1-indexing for arrays, Swift uses 0)
            ("arm",  22264 ..< 36542, 24406 ..< 34400),
            ("beat", 28658 ..< 37352, 29962 ..< 36048),
            ("bid",  23814 ..< 32697, 25146 ..< 31365),
            ("calm", 28583 ..< 42450, 30663 ..< 40370),
            ("cat",  23520 ..< 40670, 26093 ..< 38098),
            ("four", 32851 ..< 46930, 34963 ..< 44818),
            ("who",  20202 ..< 34398, 22331 ..< 32269)
        ]
        for (file, input, expectedResult) in testData {
            print("Testing \(file)")
            let result = input.truncatedTails(byPortion: 0.15)
            XCTAssertEqual(result.startIndex, expectedResult.startIndex)
            XCTAssertEqual(result.count, expectedResult.count)
        }
    }
    
    func testVowelRange() {
        let testData: [(String, CountableRange<Int>)] = [
            // This is MATLAB results all minus one (MATLAB uses 1-indexing for arrays, Swift uses 0)
            ("arm",  24406 ..< 34400),
            ("beat", 29962 ..< 36048),
            ("bid",  25146 ..< 31365),
            ("calm", 30663 ..< 40370),
            ("cat",  26093 ..< 38098),
            ("four", 34963 ..< 44818),
            ("who",  22331 ..< 32269)
        ]
        for (file, expectedResult) in testData {
            print("Testing \(file)")
            let result = analyzers[file]!.vowelPart
            XCTAssertEqual(result.startIndex, expectedResult.startIndex)
            XCTAssertEqual(result.count, expectedResult.count)
        }
    }
    
    func testEstimateLpcCoefficients() {
        let testData: [(String, [Double])] = [
            ("arm",  [1.000000,-1.999524,0.743812,0.248833,0.135208,0.152699,-0.069143,-0.285817,-0.113623,0.189982])
        ]
        for (file, expectedResult) in testData {
            print("Testing \(file)")
            let analyzer = analyzers[file]!
            let result = analyzer.estimatedLpcCoefficients
            for index in 1...expectedResult.count {
                XCTAssertEqualWithAccuracy(result[index], expectedResult[index], accuracy: 0.000001)
            }
        }
    }
 
    /// Make sure nothing crashes when input data is empty
    func testZeroData() {
        let speechData = Data()
        let analyzer = SpeechAnalyzer(int16Samples: speechData as Data, withFrequency: 44100)
        let result = analyzer.estimatedLpcCoefficients
    }
}
