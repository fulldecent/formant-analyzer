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
        for file in NSBundle.mainBundle().URLsForResourcesWithExtension("raw", subdirectory: nil)! {
            let baseName = file.URLByDeletingPathExtension!.lastPathComponent!
            let speechData = NSData(contentsOfURL: file)!
            let analyzer = SpeechAnalyzer(int16Samples: speechData, withFrequency: 44100)
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
            "arm": 22265 ... 36542,
            "beat": 28659 ... 37352,
            "bid": 23815 ... 32697,
            "calm": 28584 ... 42450,
            "cat": 23521 ... 40670,
            "four": 32852 ... 46930,
            "who": 20203 ... 34398
        ]
        for (file, expectedResult) in testData {
            let samples = analyzers[file]!.samples
            let strongPart = SpeechAnalyzer.findStrongPartOfSignal(samples, withChunks: 300, sensitivity: 0.1)
            print("Testing \(file)")
            XCTAssertEqual(strongPart.startIndex, expectedResult.startIndex - 1) // Matlab uses array indicies starting with 1
            XCTAssertEqual(strongPart.count, expectedResult.count)
        }
    }
    
    func testTruncateTailsOfRange() {
        let testData = [
            ["arm",  22265 ... 36542, 24407 ... 34400],
            ["beat", 28659 ... 37352, 29963 ... 36048],
            ["bid",  23815 ... 32697, 25147 ... 31365]
/* TEMP HACK FOR BROKEN COMPILER
            ,
            ["calm", 28584 ... 42450, 30664 ... 40370],
            ["cat",  23521 ... 40670, 26094 ... 38097],
            ["four", 32852 ... 46930, 34964 ... 44818],
            ["who",  20203 ... 34398, 22332 ... 32269]
*/
        ]
        for (file, input, expectedResult) in testData {
            print("Testing \(file)")
            let result = SpeechAnalyzer.truncateTailsOfRange(input, portion: 0.15)
            XCTAssertEqual(result.startIndex, expectedResult.startIndex - 1) // Matlab uses array indicies starting with 1
            XCTAssertEqual(result.count, expectedResult.count)
        }
    }
    
    func testVowelRange() {
        XCTAssertEqual(analyzers["arm"]!.vowelPart.startIndex, 24407)
        XCTAssertEqual(analyzers["beat"]!.vowelPart.startIndex, 29963)
        XCTAssertEqual(analyzers["bid"]!.vowelPart.startIndex, 25147)
        XCTAssertEqual(analyzers["calm"]!.vowelPart.startIndex, 30664)
        XCTAssertEqual(analyzers["cat"]!.vowelPart.startIndex, 26093)
        XCTAssertEqual(analyzers["four"]!.vowelPart.startIndex, 34964)
        XCTAssertEqual(analyzers["who"]!.vowelPart.startIndex, 22332)
        
        XCTAssertEqual(analyzers["arm"]!.vowelPart.count, 9994)
        XCTAssertEqual(analyzers["beat"]!.vowelPart.count, 6086)
        XCTAssertEqual(analyzers["bid"]!.vowelPart.count, 6219)
        XCTAssertEqual(analyzers["calm"]!.vowelPart.count, 9707)
        XCTAssertEqual(analyzers["cat"]!.vowelPart.count, 12006)
        XCTAssertEqual(analyzers["four"]!.vowelPart.count, 9855)
        XCTAssertEqual(analyzers["who"]!.vowelPart.count, 9938)
    }
    
    func testEstimateLpcCoefficients() {
        let testData = [
            ["arm",  [1.000000,-1.919368,0.619068,0.233535,0.148104,0.170560,-0.004071,-0.209700,-0.135552,0.053624,0.029470,-0.063285,0.007528,0.104894,0.045091,-0.055311,-0.021498,0.044832,-0.007362,-0.048691]]
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
}
