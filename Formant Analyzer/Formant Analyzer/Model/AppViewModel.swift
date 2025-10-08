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
    // MARK: - App state
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
    private let audioRecorder = AudioRecorder()
    private var recordedAudio: RecordedAudio?
    private let recordingDuration: TimeInterval = 1.5
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init() {
        setupBindings()
    }
    
    // MARK: - Public methods (recording control)
    
    func startRecording() {
        Task {
            let granted = await audioRecorder.requestPermission()
            guard granted else {
                status = .error("Microphone permission denied")
                return
            }
            
            do {
                status = .recording
                
                try await audioRecorder.startRecording(duration: recordingDuration) { [weak self] audio in
                    Task { @MainActor in
                        self?.handleRecordingComplete(audio)
                    }
                }
            } catch {
                status = .error("Failed to start recording: \(error.localizedDescription)")
            }
        }
    }
    
    func stopRecording() async {
        let audio = await audioRecorder.stopRecording()
        handleRecordingComplete(audio)
    }
    
    func reset() {
        status = .idle
        formantAnalysis = .empty
        recordedAudio = nil
        audioRecorder.reset()
    }
    
    // MARK: - Private methods (recording)
    
    private func handleRecordingComplete(_ audio: RecordedAudio) {
        recordedAudio = audio
        
        guard !audio.isEmpty else {
            status = .error("No audio data recorded")
            return
        }
        
        status = .processing
        
        Task {
            await processRecording()
        }
    }
    
    // MARK: - Private methods (analysis pipeline)
    
    private func processRecording() async {
        guard let audio = recordedAudio else {
            status = .error("No audio data available")
            return
        }
        
        guard !audio.isEmpty else {
            status = .error("No audio data recorded")
            return
        }
        
        await rerunAnalysis()
    }
    
    /// Re-runs the formant analysis with current configuration and recorded samples.
    private func rerunAnalysis() async {
        guard let audio = recordedAudio, !audio.isEmpty else {
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
        let samples = audio.samples
        let sampleRate = audio.sampleRate
        
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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Defer to next run loop to avoid "publishing changes from within view updates"
                DispatchQueue.main.async {
                    Task { @MainActor in
                        // Only re-run if we have recorded audio to analyze
                        if self?.recordedAudio?.isEmpty == false {
                            await self?.rerunAnalysis()
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
}
