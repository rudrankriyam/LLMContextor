//
//  ContentView.swift
//  LLMContextor
//
//  Created by Rudrank Riyam on 11/23/24.
//

import SwiftUI

struct ContentView: View {
  @State private var viewModel = ContentViewModel()

  var body: some View {
    VStack(spacing: 12) {
      Text("LLM Contextor")
        .font(.headline)

      Toggle("Auto Copy Context", isOn: $viewModel.isAutoCopyEnabled)
        .toggleStyle(.switch)

      Divider()

      Button("Quit") {
        NSApplication.shared.terminate(nil)
      }
    }
    .padding()
  }
}

#Preview {
  ContentView()
}
