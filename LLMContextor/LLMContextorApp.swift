//
//  LLMContextorApp.swift
//  LLMContextor
//
//  Created by Rudrank Riyam on 11/23/24.
//

import SwiftUI

@main
struct LLMContextorApp: App {
    var body: some Scene {
        MenuBarExtra("LLM", systemImage: "brain") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
