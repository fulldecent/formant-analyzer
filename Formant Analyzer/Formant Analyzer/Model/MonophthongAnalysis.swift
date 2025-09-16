//
//  MonophthongAnalysis.swift
//  Formant Analyzer
//
//  Created by William Entriken on 2025-09-14.
//

import Foundation
// import Numerics
import AVFoundation
import Accelerate

/// The completed analysis from a speech signals to extract formants and related properties.
struct MonophthongAnalysis {
    struct Configuration {
    }
    
    /*
    enum Classification {
    }
     */
    
    
    // MARK: Analysis inputs
    let formants: [FormantAnalysis.Formant]
    let configuration: Configuration

    // MARK: Analysis outputs
    //let classification: Classification
    let classification: String /// IPA
    
    init(formants: [FormantAnalysis.Formant], configuration: Configuration) {
        self.formants = formants
        self.configuration = configuration
        // MOCK ANALYSIS
        self.classification = "†"
    }
}
