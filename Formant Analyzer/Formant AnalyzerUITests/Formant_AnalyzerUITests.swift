//
//  FormantPlotterUITests.swift
//  FormantPlotterUITests
//
//  Created by William Entriken on 11/10/15.
//  Copyright © 2015 William Entriken. All rights reserved.
//

import XCTest

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

class Formant_AnalyzerUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        app.buttons["Microphone"].tap()
        app.sheets["Audio source"].collectionViews.buttons["arm"].tap()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSig() {
        let app = XCUIApplication()
        app.buttons["Sig"].tap()
        delay(0.5) {
            snapshot("1Sig", waitForLoadingIndicator:true)
        }
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testLpc() {
        let app = XCUIApplication()
        app.buttons["LPC"].tap()
        delay(0.5) {
            snapshot("2Lpc", waitForLoadingIndicator:true)
        }
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testHw() {
        let app = XCUIApplication()
        app.segmentedControls.buttons.elementBoundByIndex(2).tap()
        delay(0.5) {
            snapshot("3Hw", waitForLoadingIndicator:true)
        }
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testFrmnt() {
        let app = XCUIApplication()
        app.buttons["Frmnt"].tap()
        delay(0.5) {
            snapshot("4Frmnt", waitForLoadingIndicator:true)
        }
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
}
