//
//  Formant_AnalyzerTests.swift
//  Formant AnalyzerTests
//
//  Created by William Entriken on 2025-09-14.
//

import Testing

struct HillenbrandBenchmark {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        
        let hillenbrandData = Hillenbrand1995Access.loadSteadyStateFormants()
        print(hillenbrandData)
        
        #expect(!hillenbrandData.isEmpty)
    }
}
