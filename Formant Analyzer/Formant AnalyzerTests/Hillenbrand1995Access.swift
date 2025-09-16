//
//  Hillenbrand1995Access.swift
//  Formant Analyzer
//
//  Created by William Entriken on 2025-09-15.
//

import Foundation

class Hillenbrand1995Access {
    struct VowelDataLine {
        /// Time in milliseconds
        let duration: Double
        
        /// Fundamental frequency in Hz
        let f0: Double?
        
        /// First formant frequency in Hz
        let f1: Double?
        
        /// Second formant frequency in Hz
        let f2: Double?
        
        /// Third formant frequency in Hz
        let f3: Double?
        
        /// Fourth formant frequency in Hz
        let f4: Double?
    }
    
    static func loadSteadyStateFormants() -> [String: VowelDataLine] {
        // Construct the path to the file in the specified bundle
        let bundle = Bundle(for: Hillenbrand1995Access.self)
        guard let resourceURL = bundle.resourceURL?.appendingPathComponent("vowdata.dat") else {
            fatalError("File not found")
        }
        let fileContents = try! String(contentsOf: resourceURL, encoding: .utf8)
        let dataLines = fileContents.split(whereSeparator: \.isNewline).filter { line in
            let dataLineRegex = /^[mwbg]\d{2}\w+(\W+\d+){15}\W*$/
            return try! dataLineRegex.wholeMatch(in: line) != nil
        }

        var result = [String: VowelDataLine]()
        for line in dataLines {
            let parts = line.split(whereSeparator: { $0.isWhitespace })
            guard parts.count >= 6 else { continue }
            
            // Derive filename from first part (e.g., "w23oo")
            let filename = String(parts[0]) + ".wav"
            // Parse in order: duration, f0, f1, f2, f3, f4 (adjust indices if data order differs)
            let duration = Double(parts[1])!
            let f0 = Double(parts[2])! > 0 ? Double(parts[2]) : nil
            let f1 = Double(parts[3])! > 0 ? Double(parts[3]) : nil
            let f2 = Double(parts[4])! > 0 ? Double(parts[4]) : nil
            let f3 = Double(parts[5])! > 0 ? Double(parts[5]) : nil
            let f4 = Double(parts[6])! > 0 ? Double(parts[6]) : nil
            
            let vowelData = VowelDataLine(duration: duration, f0: f0, f1: f1, f2: f2, f3: f3, f4: f4)
            // Assuming filenames are unique; otherwise, this overwrites duplicates
            result[filename] = vowelData
        }
        return result
    }
}
