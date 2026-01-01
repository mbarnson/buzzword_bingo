<objective>
Enhance SemanticMatcher with three improvements to catch more speech recognition matches:
1. Keyword coverage matching (word order independence)
2. Acronym expansion dictionary
3. Enhanced debugging for single-word misses

These changes address real user testing feedback where valid buzzwords were missed due to word order variations, acronym usage, and insufficient logging to diagnose misses.
</objective>

<context>
@Buzzword Bingo/Services/SemanticMatcher.swift

The SemanticMatcher currently uses keyword-indexed hybrid matching:
- Extracts keywords from buzzwords (filtering stopwords)
- Builds keyword index mapping words to BuzzwordEntry structs
- For single-word buzzwords: exact match = instant accept
- For multi-word buzzwords: extracts window around keyword, does semantic comparison

Problems identified in testing:
- "value-add" on card doesn't match when user says "add value" (same words, different order)
- "EOD" on card doesn't match "end of the day" (acronym vs expansion)
- Single-word buzzword "scalable" was missed but logs don't show why
</context>

<requirements>

<requirement_1 title="Keyword Coverage Matching">
For multi-word buzzwords, if ALL keywords from the buzzword appear ANYWHERE in the phrase (regardless of order), treat as instant match with score 1.0.

Implementation:
1. In BuzzwordEntry, keywords are already extracted
2. When processing a multi-word buzzword candidate, check if ALL its keywords exist in the phrase words
3. If 100% keyword coverage: instant match (skip semantic comparison)
4. If partial coverage: proceed with semantic comparison as before

This check should happen BEFORE the semantic comparison in the matching loop.

Examples:
- Buzzword "value-add" has keywords: [value, add]
- Phrase "let's add some real value here" contains both → instant match
- Phrase "add more features" contains only [add] → semantic comparison
</requirement_1>

<requirement_2 title="Acronym Expansion Dictionary">
Maintain a static dictionary mapping common business acronyms to their expansions. When building the index, if a buzzword matches a known acronym, ALSO index the expansion's keywords pointing to the same BuzzwordEntry.

Dictionary to include:
```swift
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
```

Implementation in buildIndex():
1. After creating BuzzwordEntry, check if normalized buzzword (lowercase, single word) exists in acronymExpansions
2. If yes, extract keywords from the expansion string
3. Index those expansion keywords pointing to the same entry
4. Log when acronym expansion is applied

Example:
- Buzzword "EOD" → normalized "eod" → expansion "end of day"
- Extract keywords: [end, day] (after stopword filtering)
- Index both "eod" AND "end" AND "day" pointing to the EOD entry
</requirement_2>

<requirement_3 title="Enhanced Debug Logging">
Add logging to show keyword lookup results during matching, not just phonetic fallbacks.

Current logging only shows:
- When phonetic matching is tried
- When matches are found

Add logging for:
1. When a phrase word IS found in keywordIndex (exact hit)
2. When a phrase word is NOT found (before phonetic fallback)
3. Summary of which buzzword keywords were/weren't found in phrase (for keyword coverage check)

Format examples:
```
[SemanticMatcher] Exact keyword hit: "scalable" → [Scalable]
[SemanticMatcher] No keyword match for: "the", "meeting", "today"
[SemanticMatcher] Keyword coverage for "Value-add": 2/2 keywords found [value, add] → instant match
[SemanticMatcher] Keyword coverage for "Take this offline": 1/3 keywords found [offline] → semantic check
```

Keep logging concise - batch "no match" words together, don't log each stopword individually.
</requirement_3>

</requirements>

<implementation_order>
1. Add acronymExpansions dictionary (static property)
2. Update buildIndex() to index acronym expansions
3. Add keyword coverage check in findBestMatch() and findAllMatches() BEFORE semantic comparison
4. Add enhanced debug logging throughout
5. Test build compiles
</implementation_order>

<constraints>
- Modify only SemanticMatcher.swift
- Keep semantic comparison as fallback (don't remove it)
- Keyword coverage check must happen BEFORE semantic comparison for multi-word buzzwords
- Maintain backward compatibility with existing API
- Keep stopword filtering as-is (don't change which words are filtered)
</constraints>

<verification>
After implementation:
1. Build the project: `xcodebuild -scheme "Buzzword Bingo" -destination "platform=macOS" -quiet build`
2. Verify no compiler errors
3. Review logs to confirm new logging appears for:
   - Exact keyword hits
   - Keyword coverage calculations
   - Acronym expansion indexing
</verification>

<success_criteria>
- "add value" in speech matches "value-add" on card (keyword coverage)
- "end of the day" in speech matches "EOD" on card (acronym expansion)
- Logs clearly show when keywords are/aren't found in the index
- All existing matching functionality continues to work
- Build succeeds on macOS
</success_criteria>
