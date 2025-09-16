//
//  FormantAnalysis.swift
//  Formant Analyzer
//
//  Created by William Entriken on 2025-09-14.
//

import Foundation
// import Numerics
import AVFoundation
import Accelerate

/// The completed analysis from a speech signals to extract formants and related properties.
struct FormantAnalysis {
    struct Configuration {
    }
    
    struct Formant {
        /// A quantity, in Hz, of the peak location of this formant
        let frequency: Double
        
        /// Modeling this as a filter, the q-factor
        let q: Double
        
        /// A relative quantity, in decibels, of the frequency response of this formant.
        /// Calculate using the frequency response of the non-preemphasis signal at this frequency.
        /// This value is only useful when comparing formants against each other from the same `FormantAnalysis`
        let amplitude: Double
    }
    
    // MARK: Analysis inputs
    let originalSamples: [Double]
    let originalSampleRate: Double
    let configuration: Configuration

    // MARK: Analysis outputs
    let formants: [Formant]
    
    /// Detect steady-state formants in a provided audio recording
    /// - Parameters:
    ///   - samples: Magnitudes of the audio recording, in a range of -1.0...1.0
    ///   - sampleRate: Number of samples per second
    ///   - configuration: How the analysis shall be performed
    init(samples: [Double], sampleRate: Double, configuration: Configuration = .init()) {
        self.originalSamples = samples
        self.originalSampleRate = sampleRate
        self.configuration = configuration
        
        // MOCK ANALYSIS
        self.formants = [
            Formant(frequency: 100, q: 4, amplitude: 2),
            Formant(frequency: 500, q: 3, amplitude: 1),
            Formant(frequency: 800, q: 1, amplitude: 1)
        ]
    }
}
