//
//  SpeechAnalyzer.swift
//  FormantPlotter
//
//  Created by William Entriken on 1/22/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import Foundation

/// Analyzes speech signals to extract formants and related properties.
class SpeechAnalyzer {
    /// Individual audio samples.
    let samples: [Int16]
    
    /// The rate in Hz.
    let sampleRate: Int
    
    /// Human formants are < 5 kHz, so we do not need signal information above 10 kHz.
    lazy var decimationFactor: Int = {
        max(1, sampleRate / 10000)
    }()
    
    /// The part of `samples` which has a strong signal.
    lazy var strongPart: CountableRange<Int> = {
        SpeechAnalyzer.findStrongPartOfSignal(samples, withChunks: 300, sensitivity: 0.1)
    }()
    
    /// The part of `samples` which is a vowel utterance.
    lazy var vowelPart: CountableRange<Int> = {
        strongPart.truncatedTails(byPortion: 0.15)
    }()
    
    /// The vowel part of `samples` decimated by `decimationFactor`.
    private lazy var vowelSamplesDecimated: [Int16] = {
        let range = vowelPart
        return samples[range].decimated(by: decimationFactor)
    }()
    
    /// Linear prediction coefficients of the vowel signal.
    lazy var estimatedLpcCoefficients: [Double] = {
        SpeechAnalyzer.estimateLpcCoefficients(samples: vowelSamplesDecimated, sampleRate: sampleRate / decimationFactor, modelLength: 10)
    }()
    
    /// Synthesized frequency response for the estimated LPC coefficients.
    /// - Returns: The response at frequencies 0, 15, ... Hz, with the first index (identity) as 1.0.
    lazy var synthesizedFrequencyResponse: [Double] = {
        let frequencies = Array(stride(from: 0, to: sampleRate / decimationFactor / 2, by: 15))
        return SpeechAnalyzer.synthesizeResponseForLPC(estimatedLpcCoefficients, withRate: sampleRate / decimationFactor, atFrequencies: frequencies)
    }()
    
    /// Finds at least the first four formants in the range for estimating human vowel pronunciation.
    /// - Returns: Formants in Hz.
    lazy var formants: [Double] = {
        let complexPolynomial = estimatedLpcCoefficients.map { 0.0.i + $0 }
        let formants = SpeechAnalyzer.findFormants(complexPolynomial, sampleRate: sampleRate / decimationFactor)
        return SpeechAnalyzer.filterSpeechFormants(formants)
    }()
    
    /// Reduces horizontal resolution of `strongPart` for plotting.
    /// - Parameter newSampleCount: The desired number of samples.
    /// - Returns: Downsampled signal values.
    func downsampleStrongPartToSamples(_ newSampleCount: Int) -> [Int16] {
        guard newSampleCount > 0, !strongPart.isEmpty else { return [] }
        let chunkSize = strongPart.count / newSampleCount
        guard chunkSize > 0 else { return Array(samples[strongPart].prefix(newSampleCount)) }
        
        var chunkMaxElements: [Int16] = []
        for chunkStart in stride(from: strongPart.lowerBound, through: strongPart.upperBound - chunkSize, by: chunkSize) {
            let range = chunkStart..<min(chunkStart + chunkSize, strongPart.upperBound)
            chunkMaxElements.append(samples[range].max() ?? 0)
        }
        return chunkMaxElements
    }
    
    /// Reduces horizontal resolution of `samples` for plotting.
    /// - Parameter newSampleCount: The desired number of samples.
    /// - Returns: Downsampled signal values.
    func downsampleToSamples(_ newSampleCount: Int) -> [Int16] {
        guard newSampleCount > 0 else { return [] }
        guard newSampleCount < samples.count else { return samples }
        let chunkSize = samples.count / newSampleCount
        guard chunkSize > 0 else { return Array(samples.prefix(newSampleCount)) }
        
        var chunkMaxElements: [Int16] = []
        for chunkStart in stride(from: samples.startIndex, through: samples.endIndex - chunkSize, by: chunkSize) {
            let range = chunkStart..<min(chunkStart + chunkSize, samples.endIndex)
            chunkMaxElements.append(samples[range].max() ?? 0)
        }
        return chunkMaxElements
    }
    
    /// Creates an analyzer with given 16-bit PCM samples.
    /// - Parameters:
    ///   - data: The raw PCM data.
    ///   - rate: The sample rate in Hz.
    init(int16Samples data: Data, withFrequency rate: Int) {
        samples = data.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Int16.self))
        }
        sampleRate = rate
    }
    
    /// Analyzes a signal to find the significant part.
    /// - Parameters:
    ///   - signal: The input signal.
    ///   - numChunks: Number of chunks to divide the signal into.
    ///   - factor: Sensitivity factor for energy threshold.
    /// - Returns: The range of the strong signal.
    class func findStrongPartOfSignal(_ signal: [Int16], withChunks numChunks: Int, sensitivity factor: Double) -> CountableRange<Int> {
        guard !signal.isEmpty, numChunks > 0 else { return 0..<0 }
        let chunkSize = max(1, signal.count / numChunks)
        var chunkEnergies: [Double] = []
        var maxChunkEnergy: Double = 0
        
        for chunkStart in stride(from: signal.startIndex, through: signal.endIndex - chunkSize, by: chunkSize) {
            let range = chunkStart..<min(chunkStart + chunkSize, signal.endIndex)
            let chunkEnergy = signal[range].reduce(0.0) { $0 + Double($1) * Double($1) }
            maxChunkEnergy = max(maxChunkEnergy, chunkEnergy)
            chunkEnergies.append(chunkEnergy)
        }
        
        let firstSelectedChunk = chunkEnergies.firstIndex { $0 > maxChunkEnergy * factor } ?? 0
        let lastSelectedChunk = chunkEnergies.reversed().firstIndex { $0 > maxChunkEnergy * factor }.map { chunkEnergies.count - 1 - $0 } ?? chunkEnergies.count - 1
        return firstSelectedChunk * chunkSize..<min((lastSelectedChunk + 1) * chunkSize, signal.count)
    }
    
    /// Estimates LPC polynomial coefficients from the signal using Levinson-Durbin recursion.
    /// - Parameters:
    ///   - samples: The input samples.
    ///   - rate: The sample rate in Hz.
    ///   - modelLength: The number of coefficients.
    /// - Returns: Autocorrelation coefficients for an all-pole model.
    class func estimateLpcCoefficients(samples: [Int16], sampleRate rate: Int, modelLength: Int) -> [Double] {
        guard samples.count > modelLength else {
            return [Double](repeating: 1, count: modelLength + 1)
        }
        
        var correlations: [Double] = []
        var coefficients: [Double] = []
        var modelError: Double
        
        for delay in 0...modelLength {
            var correlationSum = 0.0
            for sampleIndex in 0..<(samples.count - delay) {
                correlationSum += Double(samples[sampleIndex]) * Double(samples[sampleIndex + delay])
            }
            correlations.append(correlationSum)
        }
        
        modelError = correlations[0]
        guard modelError != 0 else { return [Double](repeating: 1, count: modelLength + 1) }
        coefficients.append(1.0)
        
        for delay in 1...modelLength {
            var rcNum = 0.0
            for i in 1...delay {
                rcNum -= coefficients[delay - i] * correlations[i]
            }
            coefficients.append(rcNum / modelError)
            
            for i in stride(from: 1, through: delay / 2, by: 1) {
                let pci = coefficients[i] + coefficients[delay] * coefficients[delay - i]
                let pcki = coefficients[delay - i] + coefficients[delay] * coefficients[i]
                coefficients[i] = pci
                coefficients[delay - i] = pcki
            }
            
            modelError *= 1.0 - coefficients[delay] * coefficients[delay]
        }
        return coefficients
    }
    
    /// Synthesizes the frequency response for the estimated LPC coefficients.
    /// - Parameters:
    ///   - coefficients: The LPC model coefficients.
    ///   - samplingRate: The sampling frequency in Hz.
    ///   - frequencies: The frequencies to evaluate.
    /// - Returns: The response from 0 to 1 for each frequency.
    class func synthesizeResponseForLPC(_ coefficients: [Double], withRate samplingRate: Int, atFrequencies frequencies: [Int]) -> [Double] {
        var response: [Double] = []
        for frequency in frequencies {
            let radians = Double(frequency) / Double(samplingRate) * Double.pi * 2
            var sum: Complex<Double> = 0.0 + 0.0.i
            for (index, coefficient) in coefficients.enumerated() {
                sum += Complex<Double>(abs: coefficient, arg: Double(index) * radians)
            }
            response.append(20 * log10(1.0 / sum.abs))
        }
        return response
    }
    
    /// Finds one root of a complex polynomial using Laguerre's method.
    /// - Parameters:
    ///   - polynomial: The polynomial coefficients.
    ///   - guess: The initial guess for the root.
    /// - Returns: The computed root.
    class func laguerreRoot(_ polynomial: [Complex<Double>], initialGuess guess: Complex<Double> = 0.0 + 0.0.i) -> Complex<Double> {
        let m = polynomial.count - 1
        let MR = 8
        let MT = 10
        let maximumIterations = MR * MT
        let EPSS = 1.0e-7
        
        var x = guess
        let frac = [0.0, 0.5, 0.25, 0.75, 0.125, 0.375, 0.625, 0.875, 1.0]
        
        for iteration in 1...maximumIterations {
            var b = polynomial[m]
            var err = b.abs
            var d: Complex<Double> = 0.0 + 0.0.i
            var f: Complex<Double> = 0.0 + 0.0.i
            let abx = x.abs
            
            for j in stride(from: m - 1, through: 0, by: -1) {
                f = x * f + d
                d = x * d + b
                b = x * b + polynomial[j]
                err = b.abs + abx * err
            }
            err *= EPSS
            
            if b.abs < err {
                return x
            }
            
            let g = d / b
            let g2 = g * g
            let h = g2 - 2.0 * f / b
            let sq = sqrt((Double(m) - 1) * (Double(m) * h - g2))
            var gp = g + sq
            let gm = g - sq
            let abp = gp.abs
            let abm = gm.abs
            if abp < abm {
                gp = gm
            }
            let dx = max(abp, abm) > 0.0 ? Double(m) / gp : (1 + abx) * (cos(Double(iteration)) + sin(Double(iteration)).i)
            let x1 = x - dx
            
            if x == x1 {
                return x
            }
            
            x = iteration % MT > 0 ? x1 : x - frac[iteration / MT] * dx
        }
        NSLog("Too many iterations in Laguerre, returning zero")
        return 0 + 0.i
    }
    
    /// Finds the roots of a complex polynomial using Laguerre's method.
    /// - Parameters:
    ///   - polynomial: The polynomial coefficients.
    ///   - rate: The sample rate in Hz.
    /// - Returns: Formant frequencies in Hz.
    class func findFormants(_ polynomial: [Complex<Double>], sampleRate rate: Int) -> [Double] {
        var roots: [Complex<Double>] = []
        var deflatedPolynomial = polynomial
        let modelOrder = polynomial.count - 1
        
        for j in stride(from: modelOrder, through: 1, by: -1) {
            var root = laguerreRoot(deflatedPolynomial)
            if abs(root.imag) < 2.0e-6 * abs(root.real) {
                root.imag = 0.0
            }
            roots.append(root)
            
            var b = deflatedPolynomial[j]
            for jj in stride(from: j - 1, through: 0, by: -1) {
                let c = deflatedPolynomial[jj]
                deflatedPolynomial[jj] = b
                b = root * b + c
            }
        }
        
        let polishedRoots = roots.map { laguerreRoot(polynomial, initialGuess: $0) }
        let formantFrequencies = polishedRoots.map { $0.arg * Double(rate) / Double.pi / 2 }
        return formantFrequencies.sorted()
    }
    
    /// Filters formants to ensure they are valid for human speech.
    /// - Parameter formants: The input formants in Hz.
    /// - Returns: At least four filtered formants in Hz.
    class func filterSpeechFormants(_ formants: [Double]) -> [Double] {
        let MIN_FORMANT = 50.0
        let MAX_FORMANT = 5000.0
        let MIN_DISTANCE = 10.0
        
        var editedFormants = formants.sorted().filter { $0 >= MIN_FORMANT && $0 <= MAX_FORMANT }
        var done = false
        while !done {
            done = true
            for (index, formantA) in editedFormants.enumerated() {
                guard index < editedFormants.count - 1 else { continue }
                let formantB = editedFormants[index + 1]
                if abs(formantA - formantB) < MIN_DISTANCE {
                    let newFormant = (formantA + formantB) / 2
                    editedFormants.remove(at: index + 1)
                    editedFormants[index] = newFormant
                    editedFormants.sort()
                    done = false
                    break
                }
            }
        }
        
        while editedFormants.count < 4 {
            editedFormants.append(9999.0)
        }
        
        return editedFormants
    }
}

/// Truncates the tails of a range by a portion of its length.
extension CountableRange where Bound.Stride == Int {
    /// Shrinks range by `portion` of its length from each side.
    /// - Parameter portion: A fraction in the range 0...0.5.
    func truncatedTails(byPortion portion: Double) -> CountableRange<Bound> {
        let start = lowerBound.advanced(by: Int((portion * Double(count)).rounded()))
        let end = lowerBound.advanced(by: Int(((1 - portion) * Double(count)).rounded()))
        return start..<end
    }
}

extension ArraySlice {
    /// Selects the first of every `step` items.
    /// - parameter step: the decimation factor.
    /// - returns: the decimated array.
    func decimated(by step: Int) -> [Element] {
        guard step > 0 else { return [] }
        return Swift.stride(from: startIndex, to: endIndex, by: step).map { self[$0] }
    }
}
