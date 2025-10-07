// Formant Analyzer
// (c) William Entriken
// See LICENSE

import Foundation
import AVFoundation
import AVFAudio  // Required for AVAudioApplication
import Combine
import SwiftUI

@MainActor
class AppViewModel: ObservableObject {
    // MARK: - App State
    enum Status: Equatable {
        case idle
        case recording
        case processing
        case ready
        case error(String)
    }
    
    @Published var status: Status = .idle
    @Published var formantAnalysis: FormantAnalysis = .empty
    @Published var targetVowels: [TherapeuticVowel] = SpeakerProfile.baseVowels
    
    // MARK: - Configuration properties
    @Published var resampleRate: Double = FormantAnalysis.Configuration.default.resampleRate
    @Published var preemphasisCoefficient: Double = FormantAnalysis.Configuration.default.preemphasisCoefficient
    @Published var framingChunkDuration: Double = FormantAnalysis.Configuration.default.framingChunkDuration
    @Published var framingPowerThreshold: Double = FormantAnalysis.Configuration.default.framingPowerThreshold
    @Published var framingTrimFactor: Double = FormantAnalysis.Configuration.default.framingTrimFactor
    @Published var cosineWindowAlpha: Double = FormantAnalysis.Configuration.default.cosineWindowAlpha
    @Published var lpcModelOrder: Int = FormantAnalysis.Configuration.default.lpcModelOrder
        
    // MARK: - Private properties
    private let audioEngine = AVAudioEngine()
    private var recordedSamples: [Double] = []
    private var recordedSampleRate: Double = 0
    private var recordingTask: Task<Void, Never>?
    private let recordingDuration: TimeInterval = 1.5
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods (Recording Control)
    
    func startRecording() {
        Task {
            let granted = await requestMicrophonePermission()
            guard granted else {
                status = .error("Microphone permission denied")
                return
            }
            
            beginRecording()
        }
    }
    
    nonisolated func stopRecording() {
        Task { @MainActor in
            recordingTask?.cancel()
            recordingTask = nil
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            
            status = .processing
            await processRecording()
        }
    }
    
    func reset() {
        status = .idle
        formantAnalysis = .empty
        recordedSamples = []
        recordedSampleRate = 0
    }
    
    // MARK: - Private methods (permissions)
    
    /// Request microphone permission using modern AVAudioApplication API (iOS 17+, macOS 14+)
    private func requestMicrophonePermission() async -> Bool {
        let audioApp = AVAudioApplication.shared
        
        switch audioApp.recordPermission {
        case .granted:
            return true
        case .undetermined:
            return await requestMicrophonePermission()
        case .denied:
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - Private methods (recording)
    
    private func beginRecording() {
        do {
            // Configure audio session (iOS/iPadOS only)
            #if !os(macOS)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [])
            try audioSession.setActive(true)
            #endif
            
            // Reset recording state
            recordedSamples = []
            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)
            recordedSampleRate = inputFormat.sampleRate
            
            // Install tap to capture audio buffers
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
                Task { @MainActor in
                    self?.appendBuffer(buffer)
                }
            }
            
            // Start the audio engine
            audioEngine.prepare()
            try audioEngine.start()
            status = .recording
            
            // Schedule automatic stop using Swift Concurrency
            recordingTask = Task {
                try? await Task.sleep(for: .seconds(recordingDuration))
                if !Task.isCancelled {
                    stopRecording()
                }
            }
            
        } catch {
            let errorMessage = "Failed to start recording: \(error.localizedDescription)"
            status = .error(errorMessage)
            print(errorMessage)
        }
    }
    
    private func appendBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataPointer = channelData.pointee
        let frameLength = Int(buffer.frameLength)
        
        // Convert Float32 samples to Double and append
        for i in 0..<frameLength {
            recordedSamples.append(Double(channelDataPointer[i]))
        }
    }
    
    // MARK: - Private Methods (Analysis Pipeline)
    
    private func processRecording() async {
        guard !recordedSamples.isEmpty else {
            status = .error("No audio data recorded")
            return
        }
        
        guard recordedSampleRate > 0 else {
            status = .error("Invalid sample rate")
            return
        }
        
        await rerunAnalysis()
    }
    
    /// Re-runs the formant analysis with current configuration and recorded samples.
    private func rerunAnalysis() async {
        guard !recordedSamples.isEmpty, recordedSampleRate > 0 else {
            formantAnalysis = .empty
            return
        }
        
        let config = FormantAnalysis.Configuration(
            resampleRate: resampleRate,
            preemphasisCoefficient: preemphasisCoefficient,
            framingChunkDuration: framingChunkDuration,
            framingPowerThreshold: framingPowerThreshold,
            framingTrimFactor: framingTrimFactor,
            cosineWindowAlpha: cosineWindowAlpha,
            lpcModelOrder: lpcModelOrder
        )
        
        // Capture values for background processing
        let samples = recordedSamples
        let sampleRate = recordedSampleRate
        
        // Run analysis on a background task
        let newAnalysis = await Task.detached(priority: .userInitiated) {
            FormantAnalysis(
                samples: samples,
                sampleRate: sampleRate,
                configuration: config
            )
        }.value
        
        // Update UI (already on MainActor)
        self.formantAnalysis = newAnalysis
        self.status = .ready
    }
    
    /// Sets up a Combine pipeline that listens for changes to any configuration parameter and triggers a re-analysis.
    private func setupBindings() {
        let configurationPublishers: [AnyPublisher<Void, Never>] = [
            $resampleRate.map { _ in () }.eraseToAnyPublisher(),
            $preemphasisCoefficient.map { _ in () }.eraseToAnyPublisher(),
            $framingChunkDuration.map { _ in () }.eraseToAnyPublisher(),
            $framingPowerThreshold.map { _ in () }.eraseToAnyPublisher(),
            $framingTrimFactor.map { _ in () }.eraseToAnyPublisher(),
            $cosineWindowAlpha.map { _ in () }.eraseToAnyPublisher(),
            $lpcModelOrder.map { _ in () }.eraseToAnyPublisher()
        ]
        
        Publishers.MergeMany(configurationPublishers)
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    // Only re-run if we have recorded samples to analyze
                    if self?.recordedSamples.isEmpty == false {
                        await self?.rerunAnalysis()
                    }
                }
            }
            .store(in: &cancellables)
    }
}
