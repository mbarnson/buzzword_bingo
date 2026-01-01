//
//  FuzzyMatcher.swift
//  Buzzword Bingo
//
//  Fuzzy phrase matching for speech recognition.
//  Because people don't say "synergy" with perfect diction.
//

import Foundation

/// Utility for fuzzy string matching using Levenshtein distance
struct FuzzyMatcher {

    // MARK: - Public Methods

    /// Check if a recognized phrase matches a buzzword
    /// - Parameters:
    ///   - phrase: The recognized speech phrase
    ///   - buzzword: The buzzword to match against
    ///   - threshold: Minimum similarity score (0.0-1.0), default 0.7
    /// - Returns: True if the phrase matches the buzzword
    static func matches(phrase: String, against buzzword: String, threshold: Double = 0.7) -> Bool {
        let normalizedPhrase = normalize(phrase)
        let normalizedBuzzword = normalize(buzzword)

        // Empty strings don't match
        guard !normalizedPhrase.isEmpty && !normalizedBuzzword.isEmpty else {
            return false
        }

        // Exact match (after normalization)
        if normalizedPhrase == normalizedBuzzword {
            return true
        }

        // Check if buzzword appears as a substring in the phrase
        // This handles "let's circle back" matching "circle back"
        if normalizedPhrase.contains(normalizedBuzzword) {
            return true
        }

        // Check individual words from the phrase against the buzzword
        let phraseWords = normalizedPhrase.split(separator: " ").map(String.init)
        let buzzwordWords = normalizedBuzzword.split(separator: " ").map(String.init)

        // For multi-word buzzwords, check if all buzzword words appear in phrase
        if buzzwordWords.count > 1 {
            let allWordsMatch = buzzwordWords.allSatisfy { buzzwordWord in
                phraseWords.contains { phraseWord in
                    similarity(phraseWord, buzzwordWord) >= threshold
                }
            }
            if allWordsMatch {
                return true
            }
        }

        // For single-word buzzwords, check each phrase word
        if buzzwordWords.count == 1 {
            for phraseWord in phraseWords {
                if similarity(phraseWord, normalizedBuzzword) >= threshold {
                    return true
                }
            }
        }

        // Calculate overall similarity
        let score = similarity(normalizedPhrase, normalizedBuzzword)
        return score >= threshold
    }

    /// Calculate similarity score between two strings (0.0-1.0)
    /// - Parameters:
    ///   - string1: First string
    ///   - string2: Second string
    /// - Returns: Similarity score where 1.0 is identical
    static func similarity(_ string1: String, _ string2: String) -> Double {
        let s1 = normalize(string1)
        let s2 = normalize(string2)

        // Handle empty strings
        if s1.isEmpty && s2.isEmpty { return 1.0 }
        if s1.isEmpty || s2.isEmpty { return 0.0 }

        // Exact match
        if s1 == s2 { return 1.0 }

        let distance = levenshteinDistance(s1, s2)
        let maxLength = Double(max(s1.count, s2.count))

        return 1.0 - (Double(distance) / maxLength)
    }

    /// Find the best matching buzzword from a list
    /// - Parameters:
    ///   - phrase: The recognized speech phrase
    ///   - buzzwords: List of buzzwords to match against
    ///   - threshold: Minimum similarity score (0.0-1.0)
    /// - Returns: The best matching buzzword and its index, or nil if no match
    static func findBestMatch(
        forPhrase phrase: String,
        in buzzwords: [(index: Int, word: String)],
        threshold: Double = 0.7
    ) -> (index: Int, word: String, score: Double)? {
        let normalizedPhrase = normalize(phrase)

        guard !normalizedPhrase.isEmpty else { return nil }

        var bestMatch: (index: Int, word: String, score: Double)?

        for (index, word) in buzzwords {
            let normalizedWord = normalize(word)

            // Calculate various match scores
            var score: Double = 0.0

            // Exact substring match gets high score
            if normalizedPhrase.contains(normalizedWord) {
                score = max(score, 0.95)
            }

            // Check word-by-word for multi-word buzzwords
            let buzzwordWords = normalizedWord.split(separator: " ").map(String.init)
            let phraseWords = normalizedPhrase.split(separator: " ").map(String.init)

            if buzzwordWords.count > 1 {
                let matchingWords = buzzwordWords.filter { buzzwordWord in
                    phraseWords.contains { phraseWord in
                        similarity(phraseWord, buzzwordWord) >= threshold
                    }
                }
                let wordMatchScore = Double(matchingWords.count) / Double(buzzwordWords.count)
                score = max(score, wordMatchScore)
            }

            // For single words, find best phrase word match
            for phraseWord in phraseWords {
                let wordScore = similarity(phraseWord, normalizedWord)
                score = max(score, wordScore)
            }

            // Overall similarity
            let overallScore = similarity(normalizedPhrase, normalizedWord)
            score = max(score, overallScore)

            // Track best match above threshold
            if score >= threshold {
                if score > (bestMatch?.score ?? 0) {
                    bestMatch = (index, word, score)
                }
            }
        }

        return bestMatch
    }

    // MARK: - Private Methods

    /// Normalize a string for comparison
    /// - Parameter string: The string to normalize
    /// - Returns: Lowercase string with punctuation removed
    private static func normalize(_ string: String) -> String {
        string
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: " ")
            .split(separator: " ")
            .joined(separator: " ")
    }

    /// Calculate Levenshtein distance between two strings
    /// - Parameters:
    ///   - s1: First string
    ///   - s2: Second string
    /// - Returns: The edit distance between the strings
    private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let chars1 = Array(s1)
        let chars2 = Array(s2)
        let len1 = chars1.count
        let len2 = chars2.count

        // Handle edge cases
        if len1 == 0 { return len2 }
        if len2 == 0 { return len1 }

        // Create distance matrix
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: len2 + 1), count: len1 + 1)

        // Initialize first row and column
        for i in 0...len1 {
            matrix[i][0] = i
        }
        for j in 0...len2 {
            matrix[0][j] = j
        }

        // Fill in the matrix
        for i in 1...len1 {
            for j in 1...len2 {
                let cost = chars1[i - 1] == chars2[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return matrix[len1][len2]
    }
}
