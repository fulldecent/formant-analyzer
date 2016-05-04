//
//  FormantPlotterUITests.swift
//  FormantPlotterUITests
//
//  Created by William Entriken on 11/10/15.
//  Copyright © 2015 William Entriken. All rights reserved.
//

import XCTest

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
        snapshot("1Sig", waitForLoadingIndicator:false)
    }
    
    func testLpc() {
        let app = XCUIApplication()
        app.buttons["LPC"].tap()
        snapshot("2Lpc", waitForLoadingIndicator:false)
    }

    func testHw() {
        let app = XCUIApplication()
        app.segmentedControls.buttons.elementBoundByIndex(2).tap()
        snapshot("3Hw", waitForLoadingIndicator:false)
    }

    func testFrmnt() {
        let app = XCUIApplication()
        app.buttons["Frmnt"].tap()
        snapshot("4Frmnt", waitForLoadingIndicator:false)
    }
}
