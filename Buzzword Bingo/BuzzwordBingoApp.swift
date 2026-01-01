//
//  BuzzwordBingoApp.swift
//  Buzzword Bingo
//
//  Converted from SpriteKit garbage to SwiftUI glory
//

import SwiftUI

@main
struct BuzzwordBingoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        #endif
    }
}
