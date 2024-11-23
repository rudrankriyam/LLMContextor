import Foundation
import AppKit

/// A view model class that manages the app's state and business logic
@Observable
class ContentViewModel {
  private let service = UIThubService()
  private var pasteboardTimer: Timer?
  
  var isAutoCopyEnabled = false
  var lastProcessedString = ""
  
  init() {
    startMonitoringPasteboard()
  }
  
  /// Starts monitoring the system pasteboard for changes
  func startMonitoringPasteboard() {
    pasteboardTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.checkPasteboard()
    }
  }
  
  /// Checks the pasteboard for GitHub links and processes them
  private func checkPasteboard() {
    guard let string = NSPasteboard.general.string(forType: .string),
          string != lastProcessedString,
          string.contains("github.com") else {
      return
    }
    
    lastProcessedString = string
    
    Task {
      await processGitHubLink(string)
    }
  }
  
  /// Processes a GitHub link by fetching its context
  /// - Parameter link: The GitHub link to process
  private func processGitHubLink(_ link: String) async {
    guard let (owner, repo) = service.extractGitHubInfo(from: link) else { return }
    
    do {
      let context = try await service.fetchRepositoryContents(owner: owner, repo: repo)
      if isAutoCopyEnabled {
        copyToClipboard(context)
      }
      // You could also implement a notification here to inform the user
    } catch {
      print("Error fetching context: \(error)")
    }
  }
  
  /// Copies the given text to the system clipboard
  /// - Parameter text: The text to copy
  private func copyToClipboard(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
  }
} 