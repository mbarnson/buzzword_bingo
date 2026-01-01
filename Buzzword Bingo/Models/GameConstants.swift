//
//  GameConstants.swift
//  Buzzword Bingo
//
//  Because even corporate suffering deserves well-organized constants.
//

import Foundation

enum GameConstants {

    // MARK: - Default Player Names

    /// Vaguely insulting corporate names for players who can't be bothered to enter their name.
    /// Think "eye-roll worthy" corporate humor, not actually offensive.
    static let defaultPlayerNames = [
        "Corporate Shill",
        "Replaceable Drone",
        "No-Promotion Barry",
        "Synergy Enthusiast",
        "Meeting Filler",
        "PowerPoint Puppet",
        "Cubicle Dweller",
        "Yes-Person Prime",
        "Buzzword Regurgitator",
        "KPI Worshipper",
        "Quarterly Report Karen",
        "Action Item Andy",
        "Stakeholder Steve",
        "Bandwidth Bill",
        "Circle-Back Cheryl",
        "Low-Hanging Fruit Larry",
        "Pivot Patricia",
        "Deliverable Derek",
        "Touch-Base Tammy",
        "Deep-Dive Dave",
        "Value-Add Vince",
        "Best Practice Brenda",
        "Core Competency Carl",
        "Thought Leader Theo",
        "Disruptor Doug",
        "Scalable Sally",
        "Agile Alan",
        "Sprint Zero Sam",
        "Backlog Barbara",
        "Standup Stan",
        "Retro Rachel",
        "Velocity Victor",
        "Blocker Bob",
        "Scope Creep Susan",
        "Technical Debt Ted",
        "Legacy Code Linda",
        "Refactor Randy",
        "Code Review Chris",
        "Merge Conflict Mike",
        "Production Bug Pete",
        "Hotfix Hannah",
        "Deploy Friday Frank",
        "Rollback Rita",
        "Downtime Dan",
        "Incident Ivan",
        "Postmortem Paula",
        "Root Cause Ron",
        "Blameless Brad",
        "Learning Opportunity Lou",
        "Growth Mindset Greg"
    ]

    /// Returns a random default player name from the pool
    static func randomDefaultPlayerName() -> String {
        defaultPlayerNames.randomElement() ?? "Anonymous Drone"
    }

    // MARK: - Solo Player Quips

    /// Vaguely self-deprecating humor about playing bingo alone.
    /// Shown instead of "Pass to [Player]" when there's only one player.
    static let soloPlayerQuips = [
        "Table for one, party of you.",
        "Playing with yourself again?",
        "Solitaire Bingo Champion",
        "The loneliest buzzword hunter",
        "Solo queue activated",
        "Party of one, your bingo is ready",
        "Just you and your buzzwords",
        "Self-care includes solo bingo",
        "Introvert mode: engaged",
        "No witnesses to your victory",
        "Playing both sides so you always win",
        "Your only competition is yourself",
        "Awkward meeting, party of one",
        "Flying solo through the synergy",
        "One-person brainstorm session",
        "Me, myself, and bingo",
        "Social distancing champion",
        "The sound of one hand dabbing",
        "Lone wolf of corporate meetings",
        "Self-partnered bingo enthusiast",
        "Playing with yourself is still playing",
        "Your own best teammate",
        "Solo mission: accepted",
        "Table for one at the buzzword buffet",
        "Independent bingo contractor",
        "Self-employed bingo player",
        "Freelance buzzword hunter",
        "Going it alone (as usual)",
        "Your imaginary friends couldn't make it",
        "All the buzzwords, none of the sharing",
        "Competing against your own high score",
        "Self-rivalry activated",
        "The hermit's guide to bingo",
        "Solitary confinement bingo",
        "Just you versus the jargon",
        "No one to blame but yourself",
        "Winner by default (still counts)",
        "Every square is yours alone",
        "Hoarding all the buzzwords",
        "Greedy bingo: keeping it all",
        "No sharing required",
        "All the glory, none of the splitting",
        "Undisputed champion (of one)",
        "Undefeated against yourself",
        "Playing favorites with #1",
        "VIP seating: just you",
        "Exclusive one-player tournament",
        "Premium solo experience",
        "First place guaranteed*",
        "(*only participant)"
    ]

    /// Returns a random solo player quip from the pool
    static func randomSoloPlayerQuip() -> String {
        soloPlayerQuips.randomElement() ?? "Solo mode activated"
    }
}
