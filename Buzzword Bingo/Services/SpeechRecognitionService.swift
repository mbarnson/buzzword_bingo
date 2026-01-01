//
//  SpeechRecognitionService.swift
//  Buzzword Bingo
//
//  Speech recognition service using Apple's Speech framework.
//  Listens for buzzwords during meetings.
//

import Foundation
import Observation
import Speech
import AVFoundation

@Observable
@MainActor
final class SpeechRecognitionService {
    // MARK: - Public Properties

    /// Whether speech recognition is currently active
    private(set) var isListening = false

    /// Whether the user has authorized speech recognition
    private(set) var isAuthorized = false

    /// The current recognized transcript
    private(set) var transcript = ""

    /// Last error message, if any
    private(set) var lastError: String?

    /// Callback fired when new speech is recognized
    var onPhraseRecognized: ((String) -> Void)?

    // MARK: - Private Properties

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    /// Track the last callback time for debouncing
    private var lastCallbackTime: Date = .distantPast

    /// Minimum interval between callbacks (debouncing)
    /// 2.5 seconds gives Apple Speech time to correct/finalize transcription
    private let callbackDebounceInterval: TimeInterval = 2.5

    /// Track the last transcript to detect new content
    private var lastProcessedTranscript = ""

    /// Timer for periodic transcript clearing
    private var clearTimer: Timer?

    /// Timer for flushing remaining content after speech stops
    private var flushTimer: Timer?

    /// Interval before flushing remaining content (after last transcript update)
    private let flushInterval: TimeInterval = 3.0

    /// Number of words to include in the sliding window sent to semantic matcher
    private let slidingWindowWordCount = 50

    /// Track the word index up to which we've already had a successful match
    /// This prevents re-matching the same buzzword as speech continues
    private var lastMatchedWordIndex: Int = 0

    // MARK: - Initialization

    init() {
        // Initialize with default locale
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    // MARK: - Authorization

    /// Request authorization for speech recognition
    /// - Returns: True if authorization was granted
    @MainActor
    func requestAuthorization() async -> Bool {
        // Request speech recognition permission (non-isolated to avoid actor hop issues)
        let speechStatus = await fetchSpeechAuthorization()

        guard speechStatus == .authorized else {
            lastError = speechAuthorizationErrorMessage(for: speechStatus)
            isAuthorized = false
            return false
        }

        // Request microphone permission
        #if os(macOS)
        let micStatus = await AVCaptureDevice.requestAccess(for: .audio)
        guard micStatus else {
            lastError = "Microphone access denied"
            isAuthorized = false
            return false
        }
        #else
        let micStatus = await AVAudioApplication.requestRecordPermission()
        guard micStatus else {
            lastError = "Microphone access denied"
            isAuthorized = false
            return false
        }
        #endif

        isAuthorized = true
        lastError = nil
        return true
    }

    private func speechAuthorizationErrorMessage(for status: SFSpeechRecognizerAuthorizationStatus) -> String {
        switch status {
        case .denied:
            return "Speech recognition access denied. Please enable in Settings."
        case .restricted:
            return "Speech recognition is restricted on this device."
        case .notDetermined:
            return "Speech recognition permission not yet requested."
        case .authorized:
            return "" // Should not happen
        @unknown default:
            return "Unknown speech recognition authorization status."
        }
    }

    /// Fetch speech authorization status
    private func fetchSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    // MARK: - Listening Control

    /// Start listening for speech
    func startListening() {
        guard !isListening else { return }
        guard isAuthorized else {
            lastError = "Not authorized for speech recognition"
            return
        }
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            lastError = "Speech recognizer is not available"
            return
        }

        do {
            try startRecognition()
            isListening = true
            lastError = nil

            // Start periodic clear timer (every 30 seconds)
            startClearTimer()
        } catch {
            lastError = "Failed to start speech recognition: \(error.localizedDescription)"
            isListening = false
        }
    }

    /// Stop listening for speech
    func stopListening() {
        guard isListening else { return }

        stopClearTimer()
        flushTimer?.invalidate()
        flushTimer = nil

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isListening = false

        // Reset match tracking when listening stops
        lastMatchedWordIndex = 0
    }

    // MARK: - Private Methods

    private func startRecognition() throws {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        #endif

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest else {
            throw SpeechRecognitionError.requestCreationFailed
        }

        // Configure for continuous recognition
        recognitionRequest.shouldReportPartialResults = true

        // Use on-device recognition if available (iOS 13+/macOS 10.15+)
        if #available(iOS 13, macOS 10.15, *) {
            recognitionRequest.requiresOnDeviceRecognition = speechRecognizer?.supportsOnDeviceRecognition ?? false
        }

        // Get the audio input node
        let inputNode = audioEngine.inputNode

        // Create recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            self?.handleRecognitionResult(result: result, error: error)
        }

        // Configure audio tap - capture request directly to avoid actor isolation issues
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        let request = recognitionRequest
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { @Sendable buffer, _ in
            nonisolated(unsafe) let req = request
            req.append(buffer)
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
    }

    private func handleRecognitionResult(result: SFSpeechRecognitionResult?, error: Error?) {
        if let error {
            // Don't treat cancellation as an error
            if (error as NSError).code == 216 || (error as NSError).code == 1 {
                // Recognition was cancelled or ended normally
                return
            }

            DispatchQueue.main.async { [weak self] in
                self?.lastError = error.localizedDescription
            }
            return
        }

        guard let result else { return }

        let newTranscript = result.bestTranscription.formattedString

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.transcript = newTranscript

            // Check if we have new content to report
            if newTranscript != self.lastProcessedTranscript {
                self.processNewTranscript(newTranscript)
            }

            // Schedule/reschedule flush timer for end-of-speech detection
            self.scheduleFlushTimer()
        }
    }

    /// Schedule a timer to flush remaining content if speech stops
    private func scheduleFlushTimer() {
        flushTimer?.invalidate()
        flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.flushRemainingContent()
            }
        }
    }

    /// Force process any remaining content that might be stuck due to overlap
    private func flushRemainingContent() {
        guard !transcript.isEmpty else { return }

        let words = transcript.split(separator: " ")

        // Only flush if there's unprocessed content after our last match
        guard words.count > lastMatchedWordIndex else { return }

        let slidingWindow = extractSlidingWindow(from: transcript, wordCount: slidingWindowWordCount)
        guard !slidingWindow.isEmpty else { return }

        print("[SpeechService] Flush timer: forcing callback for remaining \(words.count - lastMatchedWordIndex) words")
        lastCallbackTime = Date()
        lastProcessedTranscript = transcript

        onPhraseRecognized?(slidingWindow)
    }

    private func processNewTranscript(_ newTranscript: String) {
        let now = Date()
        let timeSinceLastCallback = now.timeIntervalSince(lastCallbackTime)

        // Debounce: only fire callback if enough time has passed
        guard timeSinceLastCallback >= callbackDebounceInterval else {
            // DEBUG: Show why we're skipping
            print("[SpeechService] Skipping: debounce (\(String(format: "%.1f", timeSinceLastCallback))s < \(callbackDebounceInterval)s)")
            return
        }

        // Extract sliding window of last N words for semantic matching
        // This allows complete phrases to match better than fragments
        let slidingWindow = extractSlidingWindow(from: newTranscript, wordCount: slidingWindowWordCount)

        // Only fire callback if we have content
        guard !slidingWindow.isEmpty else { return }

        // Check if the sliding window substantially overlaps with already-matched content
        // Skip if we would be re-processing content that already matched
        let words = newTranscript.split(separator: " ")
        let windowStartIndex = max(0, words.count - slidingWindowWordCount)

        // CRITICAL: Detect if Apple reset the transcript (word count dropped below our marker)
        // This happens periodically or after long pauses - we must reset our tracking
        if words.count < lastMatchedWordIndex {
            print("[SpeechService] Transcript reset detected (\(words.count) < \(lastMatchedWordIndex)), clearing match index")
            lastMatchedWordIndex = 0
        }

        // If the window starts before or at where we last matched, check for overlap
        if windowStartIndex < lastMatchedWordIndex {
            // Calculate how much of the window overlaps with matched content
            let overlapWords = lastMatchedWordIndex - windowStartIndex
            let windowWords = min(slidingWindowWordCount, words.count)
            let newWords = windowWords - overlapWords

            // Always process if we have at least 10 new words (regardless of overlap %)
            // This ensures end-of-speech phrases get processed
            if newWords >= 10 {
                // Enough new content - proceed with callback
            } else if windowWords > 0 && Double(overlapWords) / Double(windowWords) > 0.5 {
                // Not enough new words and >50% overlap - skip
                print("[SpeechService] Skipping: overlap \(overlapWords)/\(windowWords) = \(Int(Double(overlapWords)/Double(windowWords)*100))% (\(newWords) new words, lastMatchedWordIndex=\(lastMatchedWordIndex), windowStart=\(windowStartIndex))")
                return
            }
        }

        print("[SpeechService] Firing callback: \(words.count) words, windowStart=\(windowStartIndex), lastMatched=\(lastMatchedWordIndex)")
        lastCallbackTime = now
        lastProcessedTranscript = newTranscript

        onPhraseRecognized?(slidingWindow)
    }

    /// Extract the last N words from a transcript as a sliding window
    /// - Parameters:
    ///   - text: The full transcript text
    ///   - wordCount: Maximum number of words to include in the window
    /// - Returns: The trailing portion of text containing up to wordCount words
    private func extractSlidingWindow(from text: String, wordCount: Int) -> String {
        let words = text.split(separator: " ")
        let startIndex = max(0, words.count - wordCount)
        return words[startIndex...].joined(separator: " ")
    }

    /// Mark that a match was found, so we don't re-match the same content
    /// Call this from the callback handler when a buzzword is detected
    func markMatchFound() {
        // Mark the current position in the transcript as matched
        let words = transcript.split(separator: " ")
        lastMatchedWordIndex = words.count
    }

    // MARK: - Transcript Management

    private func startClearTimer() {
        clearTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.clearTranscriptIfNeeded()
            }
        }
    }

    private func stopClearTimer() {
        clearTimer?.invalidate()
        clearTimer = nil
    }

    private func clearTranscriptIfNeeded() {
        // Clear transcript to prevent memory buildup
        // Only clear if we're not in the middle of active recognition
        guard transcript.count > 5000 else { return }

        transcript = ""
        lastProcessedTranscript = ""

        // Reset match tracking when transcript is cleared
        lastMatchedWordIndex = 0
    }
}

// MARK: - Errors

enum SpeechRecognitionError: LocalizedError {
    case requestCreationFailed
    case audioEngineError

    var errorDescription: String? {
        switch self {
        case .requestCreationFailed:
            return "Failed to create speech recognition request"
        case .audioEngineError:
            return "Audio engine error occurred"
        }
    }
}
