//
//  BuzzwordList.swift
//  Buzzword Bingo
//
//  A collection of corporate jargon, curated with love.
//

import Foundation

struct BuzzwordList: Identifiable, Codable {
    var id: UUID
    var name: String
    var words: [String]

    init(id: UUID = UUID(), name: String, words: [String]) {
        self.id = id
        self.name = name
        self.words = words
    }

    /// Fixed UUID for the default list - never changes, can't be deleted
    static let defaultID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    /// Fixed UUID for the Fruit Company list
    static let fruitCompanyID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    /// All built-in list IDs (can't be deleted)
    static let builtInIDs: Set<UUID> = [defaultID, fruitCompanyID]

    /// All built-in lists
    static let builtInLists: [BuzzwordList] = [`default`, fruitCompany]

    /// The default list of corporate nonsense everyone loves to hate
    static let `default` = BuzzwordList(
        id: defaultID,
        name: "Corporate Classics",
        words: [
            "Double-click",
            "KPI",
            "OKR",
            "Circle back",
            "Synergy",
            "Low-hanging fruit",
            "Move the needle",
            "Per my last email",  // passive-aggressive classic
            "Bandwidth", // I don't have time for your stuff tomorrow.
            "Take this offline", // I don't have time for your stuff today.
            "Thought leadership",  // barf
            "Best practices", // The last resort of the weak-minded to justify their inaction.
            "Learnings",  // not a real word
            "Pivot", // We're people, not hardware
            "Value-add", // VARs are a cancer. Why do we wanna be like them?
            "Stakeholders", // If only this was in the Buffy sense. That'd be more fun. Mr. Pointy.
            "Action items", // If these were like Action Figures it would be better.
            "EOD", // "I don't understand the scope so get it done today."
            "Deep dive", // The manager has no clue what you just said. Try again later.
            "Unpack that", // Usually you unpack when you get home. This means you're going for a ride.
            "Align", // Your manager wants to tell you what to do instead of you saying what you've done.
            "Run it up the flagpole", // We have phones now. We don't need signal flags.
            "Boil the ocean", // Theoretically possible. We could do the math but you can't be bothered.
            "Ducks in a row", // The only ducks that line up are babies. Every duck for himself.
            "Ping me", // ICMP is a protocol. This is a nuisance invitation.
            "What's the ask?", // You seem to understand those insane people over there. What do they want?
            "Net-net", // I don't see an upside for me personally here.
            "Hard stop", // I really want to escape from this meeting ten minutes ago.
            "Touch base", // The only kind of appropriate touching in the workplace.
            "Going forward", // You messed up. Let me explain in excruciating detail what you should have done.
            "Let's table this", // I'm bored with this topic.
            "Circle the wagons", // We are so doomed.
            "Leverage", // They are so doomed.
            "Drill down", // If we do what you say, we're really doomed.
            "Take it to the next level", // This doesn't make enough dang money.
            "Think outside the box", // That won't actually work.
            "At the end of the day", // Have some ridiculous reducto ad absurdium.
            "Proactive not reactive", // You don't know what we're doing and I won't tell you.
            "Win-win", // I win. You maybe keep your job.
            "Game changer", // I used AI to help me describe this darn thing.
            "Disrupt", // I'm hoping for a miracle.
            "Scalable", // It's gonna totally fall over.
            "Ecosystem", // We chose an over-saturated market and you're gonna save us.
            "North star", // Simplify the dang story.
            "Swim lane", // Stay out of my dang job.
            "Tiger team", // Your job is now my job. Yikes.
            "War room", // And now we get to sit in a call for 24 hours to do the dang job.
            "Bleeding edge", // Because 'leading edge' is too aeronautical and doesn't bleed.
            "Paradigm shift", // Here's a really weird way to describe something obvious.
            "Core competency", // You're out of your dang swim lane and in mine.
            "Leading Indicator", // I think I can tell the future.
            "Lagging Indicator", // I could not actually tell the future.
            "Success criteria", // I thought we did this dang thing already.
            "Baseline", // I know you were crazy busy when you wrote this, but now you need to measure it.
            "Benchmark", // And then tell me how much better or worse it is.
            "Instrumentation", // Give me a dang dashboard I can share with the CEO.
            "Telemetry", // And make sure your app tells you when it falls over so you get the page, not me.
            "Offline", // Anything not work-related is my own business.
            "Socialize", // You didn't talk to enough people about this before sharing it. Particularly me.
            "Triage", // Fix the darn thing
            "GTM", // go to the dang market
            "Flywheel", // Let's imply there's inertia to mass-less objects
            "Shift left", // Your code is super buggy and now I'm fixing it.
            "Guardrails", // People are using our product in ways we didn't expect.
            "Governance", // And now we're getting fined by the government.
            "Enablement", // A really weird way to say 'feature flags'
            "Agentic", // A really weird way to say "language models talking to themselves"
            "Platform play", // We don't actually want to support paying customers directly.
            "Moat", // A disgusting pond of micro-organisms you hope defends your business?
            "Win-Win", // Win for me. Maybe you if you tag along.
            "Parking lot", // I mean, appropriate for an automotive company maybe.
        ]
    )

    /// The Fruit Company has intense jargon
    static let fruitCompany = BuzzwordList(
        id: fruitCompanyID,
        name: "Fruit Company",
        words: [
            "Operationalize", // You mean "throw a bunch of contractors at it."
            "Resourcing", // It's never about resources. It's always about people.
            "Reorg", // If you haven't been reorged this year, you're due.
            "Sunset", // CIE. PIE. No, wait, ACS. ACI? Sunset all the things.
            "Determinative",  // Usually with "factor". I don't actually sound smarter using this word.
            "Blockers", // "I'm sorry, Dave, I can't do that right now."
            "DRI", // Directly Responsible Individual. It's not a fun job.
            "Data-driven", // Better Keynote slides
            "Focus and simplify", // "I didn't really understand what you meant; use smaller words."
            "Sense the moment", // And that moment? Any time but right now.
            "See around corners", // You're not in the meetings I'm in. Guess better.
            "Level set", // That plan was way too optimistic.
            "Intuition", // If you were disclosed, you'd figure this out. But you're not.
            "Demand difference", // Didn't I see a demo on this last week?
            "Status quo", // We don't set standards. We create our own.
            "Fight for excellence", // We're not paying a vendor for this. Figure it out.
            "Wrestle with the premises", // But if you actually wrestle, the People team will get involved.
            "Surprise and delight", // Your demo was certainly surprising. But not the other thing.
            "Embrace ambiguity", // Our secrets have baby secrets you don't know about.
            "Hard call", // I'll take the credit. You take the blame.
            "Foster trust", // Tell me everything while I tell you nothing.
            "Seek expertise", // You're clearly ignorant. Cure that.
            "Lasting impact", // I don't think you'll be with the company next year.
            "Team catalyst", // Your team is still working on that? I thought your demo meant you were done.
            "Make action meaningful", // What you're doing is actually useless but I'm being polite.
            "Candor", // Accept my criticism without complaint.
            "Scale", // I think your app will fall over if I blow on it.
            "Feedback", // You really should have talked to me before demoing this mess.
            "File A Radar", // I can't be bothered right now.
            "Reconvene", // I'm tired. I want food. Come back later.
            "Clarify", // I want you to talk for a few minutes so I can pretend to pay attention and zone out.
            "Leverage", // Go find more people to help you out.
            "Program Office", // You're not disclosed on something you need to know before proceeding.
            "One-pager", // Nobody cares about your 20-page single-spaced report that took months. Use pictures.
            "Milestone", // If you're not done by the end of M2, see you next year.
            "End to end", // I don't think this will survive exposure to real customers.
            "Guidance", // My math says your real-world results are wrong.
            "Live On", // I'm running the strangest stuff you wouldn't believe on my phone.
            "Roadmap", // We don't do that here.
            "Aligned", // Your manager was surprised you actually did a thing.
            "Review", // Oh no, you're not aligned, we gotta argue in private about this.
            "Dev-fused", // Your phone is SWE's playground. Good luck receiving phone calls.
            "Build Train", // Maybe your fix will show up tomorrow.
            "Mid-cycle", // Your manager thinks you're doing great, but the Guidance says someone has to go.
            "Leak", // We hate leaks and they should work elsewhere.
            "Visibility", // You didn't talk to me first.
            "Level set" // I'm totally confused by your demo.
        ]
    )
}
