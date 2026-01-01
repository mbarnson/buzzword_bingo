//
//  SemanticMatcher.swift
//  Buzzword Bingo
//
//  Keyword-indexed hybrid semantic phrase matching using Apple's NLContextualEmbedding.
//  Combines fast keyword lookup with targeted semantic matching for efficient buzzword detection.
//
//  --- NORMALIZATION PIPELINE (Task 0) ---
//  All text normalization follows these consistent rules:
//  1. Lowercase the input
//  2. Split on non-alphanumeric characters (handles contractions: "let's" -> ["let", "s"])
//  3. Filter out empty strings
//  4. Result: array of lowercase alphanumeric word tokens
//
//  Key invariants:
//  - All keyword index keys are lowercase
//  - All phrase words are normalized before lookup
//  - Comparison is always normalized vs normalized
//  --- END NORMALIZATION PIPELINE ---
//

import Foundation
import NaturalLanguage
import Accelerate

/// Semantic matcher using keyword-indexed hybrid approach for efficient buzzword matching
final class SemanticMatcher: @unchecked Sendable {

    // MARK: - Types

    /// Entry in the keyword index representing a buzzword and its metadata
    struct BuzzwordEntry {
        let index: Int           // Square index on the card
        let word: String         // Original buzzword
        let wordCount: Int       // Word count for window sizing
        let normalized: String   // Normalized form
        let keywords: [String]   // Extracted keywords for this buzzword
    }

    // MARK: - Stopwords (Task 1)

    /// Common English stopwords to filter out when extracting keywords
    private static let stopwords: Set<String> = [
        "the", "a", "an", "is", "are", "was", "were", "be", "been", "being",
        "it", "its", "this", "that", "these", "those", "i", "you", "we", "they",
        "to", "of", "in", "on", "at", "by", "for", "with", "from", "and", "or",
        "but", "so", "if", "then", "let", "s", "d", "t", "ll", "ve", "re"
    ]

    // MARK: - Acronym Expansions

    /// Maps common business acronyms to their expansions for improved matching
    private static let acronymExpansions: [String: String] = [
        "eod": "end of day",
        "asap": "as soon as possible",
        "roi": "return on investment",
        "kpi": "key performance indicator",
        "fyi": "for your information",
        "eta": "estimated time arrival",
        "poc": "proof of concept",
        "mvp": "minimum viable product",
        "okr": "objectives key results",
        "b2b": "business to business",
        "b2c": "business to consumer",
        "saas": "software as service",
        "api": "application programming interface",
        "ui": "user interface",
        "ux": "user experience",
        "pr": "pull request",
        "cr": "code review",
        "standup": "stand up meeting",
        "retro": "retrospective"
    ]

    // MARK: - Properties

    private let embeddingModel: NLContextualEmbedding?
    private var cachedEmbeddings: [String: [Double]] = [:]
    private let cache = NSLock()

    // MARK: - Keyword Index Properties (Task 2)

    /// Maps keywords to buzzword entries containing that keyword
    private var keywordIndex: [String: [BuzzwordEntry]] = [:]

    /// Maps Soundex phonetic codes to buzzword entries (for accent/transcription error tolerance)
    private var phoneticIndex: [String: [BuzzwordEntry]] = [:]

    /// Tracks which buzzword indices are currently indexed (for cache invalidation)
    private var currentBuzzwordSet: Set<Int> = []

    // MARK: - Soundex Phonetic Encoding

    /// Encode a word using the Soundex algorithm for phonetic matching
    /// - Parameter word: The word to encode
    /// - Returns: A 4-character Soundex code (e.g., "boil" → "B400")
    private func soundex(_ word: String) -> String {
        guard !word.isEmpty else { return "" }

        let lowercased = word.lowercased()
        let letters = Array(lowercased)

        // Keep first letter (uppercase)
        let firstLetter = String(letters[0]).uppercased()

        // Soundex encoding map
        let codes: [Character: Character] = [
            "b": "1", "f": "1", "p": "1", "v": "1",
            "c": "2", "g": "2", "j": "2", "k": "2", "q": "2", "s": "2", "x": "2", "z": "2",
            "d": "3", "t": "3",
            "l": "4",
            "m": "5", "n": "5",
            "r": "6"
        ]

        // Encode remaining letters
        var result = firstLetter
        var lastCode: Character = codes[letters[0]] ?? "0"

        for letter in letters.dropFirst() {
            if let code = codes[letter] {
                // Skip if same as last code (adjacent duplicates)
                if code != lastCode {
                    result.append(code)
                    lastCode = code
                }
            } else {
                // Vowels and h, w, y reset the lastCode to allow duplicates after them
                lastCode = "0"
            }

            // Stop at 4 characters
            if result.count >= 4 { break }
        }

        // Pad to 4 characters
        while result.count < 4 {
            result.append("0")
        }

        return String(result.prefix(4))
    }

    /// Shared instance for convenience
    static let shared = SemanticMatcher()

    /// Whether the embedding model is available and ready
    var isAvailable: Bool {
        embeddingModel != nil
    }

    // MARK: - Initialization

    init() {
        // Load the English contextual embedding model
        if let embedding = NLContextualEmbedding(language: .english) {
            // Check if assets are available, request if not
            if embedding.hasAvailableAssets {
                // Load the model
                do {
                    try embedding.load()
                    self.embeddingModel = embedding
                } catch {
                    self.embeddingModel = nil
                }
            } else {
                // Request assets asynchronously - will be nil until downloaded
                embedding.requestAssets { _, _ in }
                // For now, model is not available
                self.embeddingModel = nil
            }
        } else {
            self.embeddingModel = nil
        }
    }

    // MARK: - Keyword Extraction (Task 1)

    /// Extract significant keywords from a buzzword by normalizing and filtering stopwords
    /// - Parameter buzzword: The buzzword to extract keywords from
    /// - Returns: Array of significant keywords (lowercase, no stopwords)
    func extractKeywords(_ buzzword: String) -> [String] {
        // Normalize: lowercase, split on non-alphanumeric, filter empty
        let words = buzzword
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        // Filter out stopwords
        let keywords = words.filter { !Self.stopwords.contains($0) }

        return keywords
    }

    // MARK: - Keyword Index Building (Task 2)

    /// Build the keyword index for a set of buzzwords
    /// Uses caching to avoid rebuilding if the same buzzwords are indexed
    /// - Parameter buzzwords: List of (index, word) tuples representing buzzwords
    private func buildIndex(for buzzwords: [(index: Int, word: String)]) {
        // Check if we can skip rebuild - same buzzword indices already indexed
        let newBuzzwordSet = Set(buzzwords.map { $0.index })
        if newBuzzwordSet == currentBuzzwordSet && !keywordIndex.isEmpty {
            return
        }

        // Clear and rebuild
        keywordIndex.removeAll()
        phoneticIndex.removeAll()

        for (index, word) in buzzwords {
            // Normalize the buzzword
            let normalizedWords = word
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
            let normalized = normalizedWords.joined(separator: " ")
            let wordCount = normalizedWords.count

            // Extract keywords
            var keywords = extractKeywords(word)

            // Edge case: if buzzword has no keywords after filtering (e.g., "It"),
            // use the full normalized words as keywords
            if keywords.isEmpty {
                keywords = normalizedWords
            }

            // Create entry
            let entry = BuzzwordEntry(
                index: index,
                word: word,
                wordCount: wordCount,
                normalized: normalized,
                keywords: keywords
            )

            // Map each keyword to this entry (exact match)
            for keyword in keywords {
                keywordIndex[keyword, default: []].append(entry)

                // Also index by Soundex code for phonetic matching
                let phonetic = soundex(keyword)
                if !phonetic.isEmpty {
                    phoneticIndex[phonetic, default: []].append(entry)
                }
            }

            // Check for acronym expansion: if buzzword is a single word that matches a known acronym,
            // also index the expansion's keywords pointing to the same entry
            if wordCount == 1, let expansion = Self.acronymExpansions[normalized] {
                let expansionKeywords = extractKeywords(expansion)
                if !expansionKeywords.isEmpty {
                    print("[SemanticMatcher] Acronym expansion: \"\(word)\" → \"\(expansion)\" → keywords: \(expansionKeywords.joined(separator: ", "))")
                    for expansionKeyword in expansionKeywords {
                        keywordIndex[expansionKeyword, default: []].append(entry)

                        // Also index expansion keywords by Soundex
                        let expansionPhonetic = soundex(expansionKeyword)
                        if !expansionPhonetic.isEmpty {
                            phoneticIndex[expansionPhonetic, default: []].append(entry)
                        }
                    }
                }
            }
        }

        currentBuzzwordSet = newBuzzwordSet
        print("[SemanticMatcher] Built keyword index with \(keywordIndex.count) keywords + \(phoneticIndex.count) phonetic codes for \(buzzwords.count) buzzwords")
    }

    // MARK: - Public Methods

    /// Find the best matching buzzword from a list using keyword-indexed hybrid matching
    /// - Parameters:
    ///   - phrase: The recognized speech phrase
    ///   - buzzwords: List of buzzwords to match against (index, word tuples)
    ///   - threshold: Minimum similarity score (unused for single-word, 0.85 for multi-word)
    /// - Returns: The best matching buzzword and its index, or nil if no match
    func findBestMatch(
        forPhrase phrase: String,
        in buzzwords: [(index: Int, word: String)],
        threshold: Double = 0.88
    ) -> (index: Int, word: String, score: Double)? {
        guard let model = embeddingModel else {
            print("[SemanticMatcher] Model not available")
            return nil
        }

        // Normalize phrase into word array
        let phraseWords = phrase
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        guard !phraseWords.isEmpty else { return nil }

        // DEBUG: Show full input and all words being scanned
        print("[SemanticMatcher] === INPUT PHRASE (\(phraseWords.count) words) ===")
        print("[SemanticMatcher] Raw: \"\(phrase.prefix(200))\"")
        print("[SemanticMatcher] Words: \(phraseWords.joined(separator: " "))")

        // Build/use cached index
        buildIndex(for: buzzwords)

        // Enhanced debug logging: show keyword lookup results
        let indexedKeywords = Set(keywordIndex.keys)
        let phraseWordSet = Set(phraseWords)

        // Log exact keyword hits (words found in index)
        let exactHits = phraseWords.filter { indexedKeywords.contains($0) }
        if !exactHits.isEmpty {
            // Group by buzzword for clearer output
            var hitsByBuzzword: [String: [String]] = [:]
            for hit in exactHits {
                if let entries = keywordIndex[hit] {
                    for entry in entries {
                        hitsByBuzzword[entry.word, default: []].append(hit)
                    }
                }
            }
            for (buzzword, hits) in hitsByBuzzword {
                print("[SemanticMatcher] Exact keyword hit: \"\(hits.joined(separator: ", "))\" → [\(buzzword)]")
            }
        }

        // Log words not found in index (batch non-stopwords together)
        let noMatchWords = phraseWords.filter { !indexedKeywords.contains($0) && !Self.stopwords.contains($0) }
        if !noMatchWords.isEmpty {
            print("[SemanticMatcher] No keyword match for: \(noMatchWords.map { "\"\($0)\"" }.joined(separator: ", "))")
        }

        var allMatches: [(index: Int, word: String, score: Double)] = []
        var matchedIndices: Set<Int> = []

        // KEYWORD COVERAGE CHECK: For multi-word buzzwords, if ALL keywords appear anywhere in phrase, instant match
        for (_, word) in buzzwords {
            let normalizedWords = word
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
            let wordCount = normalizedWords.count

            // Only check multi-word buzzwords
            guard wordCount > 1 else { continue }

            var keywords = extractKeywords(word)
            if keywords.isEmpty {
                keywords = normalizedWords
            }

            // Check how many keywords appear in the phrase
            let foundKeywords = keywords.filter { phraseWordSet.contains($0) }
            let coverage = foundKeywords.count

            // Require at least 2 keywords for instant match (prevents false positives
            // from phrases like "Let's be proactive" which only has 1 keyword)
            if coverage == keywords.count && keywords.count >= 2 {
                // 100% keyword coverage with 2+ keywords - instant match!
                // Find the entry for this buzzword
                if let entries = keywordIndex[keywords.first!] {
                    if let entry = entries.first(where: { $0.word == word }) {
                        if !matchedIndices.contains(entry.index) {
                            print("[SemanticMatcher] Keyword coverage for \"\(word)\": \(coverage)/\(keywords.count) keywords found [\(foundKeywords.joined(separator: ", "))] → instant match")
                            allMatches.append((entry.index, entry.word, 1.0))
                            matchedIndices.insert(entry.index)
                        }
                    }
                }
            } else if coverage > 0 {
                // Partial coverage - log for debugging, will proceed with semantic check
                print("[SemanticMatcher] Keyword coverage for \"\(word)\": \(coverage)/\(keywords.count) keywords found [\(foundKeywords.joined(separator: ", "))] → semantic check")
            }
        }

        // Scan phrase words against keyword index (O(w) hash lookups)
        for (position, phraseWord) in phraseWords.enumerated() {
            // First try exact keyword match
            var entries = keywordIndex[phraseWord]
            var isPhoneticMatch = false

            // Fallback to phonetic matching if no exact match
            if entries?.isEmpty ?? true {
                let phonetic = soundex(phraseWord)
                if let phoneticEntries = phoneticIndex[phonetic], !phoneticEntries.isEmpty {
                    entries = phoneticEntries
                    isPhoneticMatch = true
                    let matchedBuzzwords = phoneticEntries.map { $0.word }.joined(separator: ", ")
                    print("[SemanticMatcher] Phonetic match: \"\(phraseWord)\" (\(phonetic)) → candidates: \(matchedBuzzwords)")
                }
            }

            guard let entries, !entries.isEmpty else { continue }

            for entry in entries {
                // Skip if we already matched this buzzword
                if matchedIndices.contains(entry.index) { continue }

                if entry.wordCount == 1 {
                    // Single-word buzzword
                    if phraseWord == entry.normalized {
                        // Exact match - instant accept
                        print("[SemanticMatcher] keyword hit: \"\(phraseWord)\" -> instant match \"\(entry.word)\"")
                        allMatches.append((entry.index, entry.word, 1.0))
                        matchedIndices.insert(entry.index)
                    } else if isPhoneticMatch {
                        // Phonetic match for single word - do semantic check
                        guard let phraseEmbedding = getEmbedding(for: phraseWord, using: model),
                              let buzzwordEmbedding = getCachedOrComputeEmbedding(
                                  for: entry.normalized,
                                  originalWord: entry.word,
                                  using: model
                              ) else { continue }

                        let similarity = cosineSimilarity(phraseEmbedding, buzzwordEmbedding)

                        if similarity >= 0.80 {
                            print("[SemanticMatcher] Phonetic+semantic match: \"\(phraseWord)\" → \"\(entry.word)\" (\(String(format: "%.2f", similarity)))")
                            allMatches.append((entry.index, entry.word, similarity))
                            matchedIndices.insert(entry.index)
                        }
                    }
                } else {
                    // Multi-word buzzword: extract window and do semantic comparison
                    let windowStart = max(0, position - entry.wordCount + 1)
                    let windowEnd = min(position + 1, phraseWords.count)
                    let windowWords = Array(phraseWords[windowStart..<windowEnd])
                    let window = windowWords.joined(separator: " ")

                    // Get embeddings
                    guard let windowEmbedding = getEmbedding(for: window, using: model),
                          let buzzwordEmbedding = getCachedOrComputeEmbedding(
                              for: entry.normalized,
                              originalWord: entry.word,
                              using: model
                          ) else { continue }

                    let similarity = cosineSimilarity(windowEmbedding, buzzwordEmbedding)

                    // Use 0.80 for phonetic-triggered matches, 0.85 for exact keyword matches
                    let multiWordThreshold = isPhoneticMatch ? 0.80 : 0.85
                    if similarity >= multiWordThreshold {
                        print("[SemanticMatcher] keyword hit: \"\(phraseWord)\" -> semantic check \"\(entry.word)\" (\(String(format: "%.2f", similarity)))")
                        allMatches.append((entry.index, entry.word, similarity))
                        matchedIndices.insert(entry.index)
                    } else if similarity >= 0.7 {
                        print("[SemanticMatcher] keyword hit: \"\(phraseWord)\" -> \"\(entry.word)\" below threshold (\(String(format: "%.2f", similarity)))")
                    }
                }
            }
        }

        // Semantic fallback: if no keyword matches found, use last 5 words for paraphrase detection
        if allMatches.isEmpty {
            let fallbackThreshold = 0.88
            let lastWords = Array(phraseWords.suffix(5))
            let fallbackPhrase = lastWords.joined(separator: " ")

            print("[SemanticMatcher] No keyword hits, semantic fallback with: \"\(fallbackPhrase)\"")

            guard let fallbackEmbedding = getEmbedding(for: fallbackPhrase, using: model) else {
                return nil
            }

            var bestFallback: (index: Int, word: String, score: Double)?
            for (index, word) in buzzwords {
                let normalizedWord = word
                    .lowercased()
                    .components(separatedBy: CharacterSet.alphanumerics.inverted)
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")

                guard let wordEmbedding = getCachedOrComputeEmbedding(
                    for: normalizedWord,
                    originalWord: word,
                    using: model
                ) else { continue }

                let similarity = cosineSimilarity(fallbackEmbedding, wordEmbedding)

                if similarity >= 0.7 {
                    print("[SemanticMatcher] fallback: \"\(fallbackPhrase)\" vs \"\(word)\" -> \(String(format: "%.2f", similarity))")
                }

                if similarity >= fallbackThreshold {
                    if similarity > (bestFallback?.score ?? 0) {
                        bestFallback = (index, word, similarity)
                    }
                }
            }
            if let fallback = bestFallback {
                allMatches.append(fallback)
            }
        }

        if allMatches.isEmpty {
            print("[SemanticMatcher] No match found")
        } else {
            let matchNames = allMatches.map { "\"\($0.word)\"" }.joined(separator: ", ")
            print("[SemanticMatcher] MATCHES (\(allMatches.count)): \(matchNames)")
        }

        // Return the best match (highest score) for backward compatibility
        return allMatches.max(by: { $0.score < $1.score })
    }

    /// Find ALL matching buzzwords from a list using keyword-indexed hybrid matching
    /// - Parameters:
    ///   - phrase: The recognized speech phrase
    ///   - buzzwords: List of buzzwords to match against (index, word tuples)
    /// - Returns: All matching buzzwords with their indices and scores
    func findAllMatches(
        forPhrase phrase: String,
        in buzzwords: [(index: Int, word: String)]
    ) -> [(index: Int, word: String, score: Double)] {
        guard let model = embeddingModel else {
            print("[SemanticMatcher] Model not available")
            return []
        }

        // Normalize phrase into word array
        let phraseWords = phrase
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        guard !phraseWords.isEmpty else { return [] }

        // Build/use cached index
        buildIndex(for: buzzwords)

        // DEBUG: Show what we're searching
        let indexedKeywords = Set(keywordIndex.keys)
        let exactHits = phraseWords.filter { indexedKeywords.contains($0) }
        if !exactHits.isEmpty {
            print("[SemanticMatcher:findAll] Exact keyword hits in phrase: \(exactHits.joined(separator: ", "))")
        } else {
            print("[SemanticMatcher:findAll] No exact keyword hits. Phrase words: \(phraseWords.suffix(10).joined(separator: " "))")
        }

        let phraseWordSet = Set(phraseWords)

        var allMatches: [(index: Int, word: String, score: Double)] = []
        var matchedIndices: Set<Int> = []

        // KEYWORD COVERAGE CHECK: For multi-word buzzwords, if ALL keywords appear anywhere in phrase, instant match
        for (_, word) in buzzwords {
            let normalizedWords = word
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
            let wordCount = normalizedWords.count

            // Only check multi-word buzzwords
            guard wordCount > 1 else { continue }

            var keywords = extractKeywords(word)
            if keywords.isEmpty {
                keywords = normalizedWords
            }

            // Check how many keywords appear in the phrase
            let foundKeywords = keywords.filter { phraseWordSet.contains($0) }
            let coverage = foundKeywords.count

            // Require at least 2 keywords for instant match (prevents false positives
            // from phrases like "Let's be proactive" which only has 1 keyword)
            if coverage == keywords.count && keywords.count >= 2 {
                // 100% keyword coverage with 2+ keywords - instant match!
                if let entries = keywordIndex[keywords.first!] {
                    if let entry = entries.first(where: { $0.word == word }) {
                        if !matchedIndices.contains(entry.index) {
                            print("[SemanticMatcher:findAll] Keyword coverage MATCH: \"\(word)\" (\(coverage)/\(keywords.count) keywords)")
                            allMatches.append((entry.index, entry.word, 1.0))
                            matchedIndices.insert(entry.index)
                        }
                    }
                }
            }
        }

        // Scan phrase words against keyword index
        for (position, phraseWord) in phraseWords.enumerated() {
            // First try exact keyword match
            var entries = keywordIndex[phraseWord]

            // Fallback to phonetic matching if no exact match
            if entries?.isEmpty ?? true {
                let phonetic = soundex(phraseWord)
                if let phoneticEntries = phoneticIndex[phonetic], !phoneticEntries.isEmpty {
                    entries = phoneticEntries
                    // Log phonetic match for debugging
                    let matchedBuzzwords = phoneticEntries.map { $0.word }.joined(separator: ", ")
                    print("[SemanticMatcher] Phonetic match: \"\(phraseWord)\" (\(phonetic)) → candidates: \(matchedBuzzwords)")
                }
            }

            guard let entries, !entries.isEmpty else { continue }

            for entry in entries {
                if matchedIndices.contains(entry.index) { continue }

                if entry.wordCount == 1 {
                    // For single-word buzzwords via phonetic match, still require semantic check
                    // to avoid false positives (phonetic can be too permissive)
                    if phraseWord == entry.normalized {
                        // Exact match - instant accept
                        print("[SemanticMatcher:findAll] MATCH: \"\(phraseWord)\" → \"\(entry.word)\"")
                        allMatches.append((entry.index, entry.word, 1.0))
                        matchedIndices.insert(entry.index)
                    } else {
                        // Phonetic match for single word - do semantic check
                        guard let phraseEmbedding = getEmbedding(for: phraseWord, using: model),
                              let buzzwordEmbedding = getCachedOrComputeEmbedding(
                                  for: entry.normalized,
                                  originalWord: entry.word,
                                  using: model
                              ) else { continue }

                        let similarity = cosineSimilarity(phraseEmbedding, buzzwordEmbedding)

                        // Use 0.80 threshold for phonetic matches (slightly lower due to transcription error)
                        if similarity >= 0.80 {
                            print("[SemanticMatcher] Phonetic+semantic match: \"\(phraseWord)\" → \"\(entry.word)\" (\(String(format: "%.2f", similarity)))")
                            allMatches.append((entry.index, entry.word, similarity))
                            matchedIndices.insert(entry.index)
                        }
                    }
                } else {
                    let windowStart = max(0, position - entry.wordCount + 1)
                    let windowEnd = min(position + 1, phraseWords.count)
                    let windowWords = Array(phraseWords[windowStart..<windowEnd])
                    let window = windowWords.joined(separator: " ")

                    guard let windowEmbedding = getEmbedding(for: window, using: model),
                          let buzzwordEmbedding = getCachedOrComputeEmbedding(
                              for: entry.normalized,
                              originalWord: entry.word,
                              using: model
                          ) else { continue }

                    let similarity = cosineSimilarity(windowEmbedding, buzzwordEmbedding)

                    // Use 0.80 for phonetic-triggered matches, 0.85 for exact keyword matches
                    let threshold = keywordIndex[phraseWord] != nil ? 0.85 : 0.80
                    if similarity >= threshold {
                        allMatches.append((entry.index, entry.word, similarity))
                        matchedIndices.insert(entry.index)
                    }
                }
            }
        }

        return allMatches
    }

    /// Pre-compute and cache embeddings for a list of buzzwords
    /// Call this when setting up a bingo card for better performance
    /// - Parameters:
    ///   - buzzwords: List of buzzwords to pre-cache
    func precomputeEmbeddings(for buzzwords: [String]) {
        guard let model = embeddingModel else { return }

        for word in buzzwords {
            let normalized = word
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            _ = getCachedOrComputeEmbedding(for: normalized, originalWord: word, using: model)
        }
    }

    /// Clear the embedding cache and keyword index
    func clearCache() {
        cache.lock()
        cachedEmbeddings.removeAll()
        keywordIndex.removeAll()
        phoneticIndex.removeAll()
        currentBuzzwordSet.removeAll()
        cache.unlock()
    }

    // MARK: - Private Methods

    /// Get embedding for a string, using cache if available
    private func getCachedOrComputeEmbedding(
        for normalizedWord: String,
        originalWord: String,
        using model: NLContextualEmbedding
    ) -> [Double]? {
        cache.lock()
        if let cached = cachedEmbeddings[normalizedWord] {
            cache.unlock()
            return cached
        }
        cache.unlock()

        guard let embedding = getEmbedding(for: normalizedWord, using: model) else {
            return nil
        }

        cache.lock()
        cachedEmbeddings[normalizedWord] = embedding
        cache.unlock()

        return embedding
    }

    /// Get sentence embedding using mean pooling of token embeddings
    private func getEmbedding(for text: String, using model: NLContextualEmbedding) -> [Double]? {
        guard let result = try? model.embeddingResult(for: text, language: .english) else {
            return nil
        }

        // Collect all token vectors
        var tokenVectors: [[Double]] = []

        result.enumerateTokenVectors(in: text.startIndex..<text.endIndex) { vector, range in
            tokenVectors.append(vector.map { Double($0) })
            return true
        }

        guard !tokenVectors.isEmpty else { return nil }

        // Mean pooling: average all token vectors to get sentence vector
        return meanPool(tokenVectors)
    }

    /// Mean pool multiple vectors into a single vector using Accelerate
    private func meanPool(_ vectors: [[Double]]) -> [Double]? {
        guard let first = vectors.first else { return nil }
        let dimension = first.count

        // Verify all vectors have same dimension
        guard vectors.allSatisfy({ $0.count == dimension }) else { return nil }

        if vectors.count == 1 {
            return first
        }

        // Sum all vectors
        var result = [Double](repeating: 0.0, count: dimension)

        for vector in vectors {
            vDSP_vaddD(result, 1, vector, 1, &result, 1, vDSP_Length(dimension))
        }

        // Divide by count to get mean
        var count = Double(vectors.count)
        vDSP_vsdivD(result, 1, &count, &result, 1, vDSP_Length(dimension))

        return result
    }

    /// Calculate cosine similarity between two vectors using Accelerate
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0.0 }

        let count = vDSP_Length(a.count)

        // Calculate dot product: a . b
        var dotProduct: Double = 0.0
        vDSP_dotprD(a, 1, b, 1, &dotProduct, count)

        // Calculate magnitudes: ||a|| and ||b||
        var magnitudeA: Double = 0.0
        var magnitudeB: Double = 0.0
        vDSP_svesqD(a, 1, &magnitudeA, count)
        vDSP_svesqD(b, 1, &magnitudeB, count)

        magnitudeA = sqrt(magnitudeA)
        magnitudeB = sqrt(magnitudeB)

        // Avoid division by zero
        guard magnitudeA > 0.0 && magnitudeB > 0.0 else { return 0.0 }

        // Cosine similarity = (a . b) / (||a|| * ||b||)
        return dotProduct / (magnitudeA * magnitudeB)
    }
}
