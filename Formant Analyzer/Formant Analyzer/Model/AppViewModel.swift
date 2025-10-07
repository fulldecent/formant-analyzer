// Formant Analyzer
// (c) William Entriken
// See LICENSE

import Foundation
import AVFoundation
import Combine
import SwiftUI

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
    // These are bound to the UI controls in DetailPageView
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
    private var recordingTimer: Timer?
    private let recordingDuration: TimeInterval = 1.5
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods (Recording Control)
    
    func startRecording() {
        requestMicrophonePermission { [weak self] granted in
            guard granted else {
                DispatchQueue.main.async {
                    self?.status = .error("Microphone permission denied")
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.beginRecording()
            }
        }
    }
    
    func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        status = .processing
        processRecording()
    }
    
    func reset() {
        status = .idle
        formantAnalysis = .empty
        recordedSamples = []
        recordedSampleRate = 0
    }
    
    // MARK: - Private Methods (Platform-specific permissions)
    
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        #if os(macOS)
        // macOS uses AVCaptureDevice for audio permission
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
        #else
        // iOS and iPadOS use AVAudioSession
        let audioSession = AVAudioSession.sharedInstance()
        switch audioSession.recordPermission {
        case .granted:
            completion(true)
        case .undetermined:
            audioSession.requestRecordPermission { granted in
                completion(granted)
            }
        case .denied:
            completion(false)
        @unknown default:
            completion(false)
        }
        #endif
    }
    
    // MARK: - Private Methods (Recording)
    
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
                self?.appendBuffer(buffer)
            }
            
            // Start the audio engine
            audioEngine.prepare()
            try audioEngine.start()
            status = .recording
            
            // Schedule automatic stop after 1.5 seconds
            recordingTimer = Timer.scheduledTimer(withTimeInterval: recordingDuration, repeats: false) { [weak self] _ in
                self?.stopRecording()
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
    
    private func processRecording() {
        guard !recordedSamples.isEmpty else {
            status = .error("No audio data recorded")
            return
        }
        
        guard recordedSampleRate > 0 else {
            status = .error("Invalid sample rate")
            return
        }
        
        rerunAnalysis()
    }
    
    /// Re-runs the formant analysis with current configuration and recorded samples.
    private func rerunAnalysis() {
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
        
        // Run analysis on a background thread to keep UI responsive
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let newAnalysis = FormantAnalysis(
                samples: self.recordedSamples,
                sampleRate: self.recordedSampleRate,
                configuration: config
            )
            
            // Switch back to main thread to update the UI
            DispatchQueue.main.async {
                self.formantAnalysis = newAnalysis
                self.status = .ready
            }
        }
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
                // Only re-run if we have recorded samples to analyze
                if self?.recordedSamples.isEmpty == false {
                    self?.rerunAnalysis()
                }
            }
            .store(in: &cancellables)
    }
}
