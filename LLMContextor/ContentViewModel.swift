import Foundation
import AppKit
import OSLog

/// A view model class that manages the app's state and business logic.
///
/// This class handles monitoring of the system pasteboard and processing GitHub links.
/// It uses structured concurrency and maintains thread safety through Sendable compliance.
///
/// ## Key Features
/// - Pasteboard monitoring with configurable auto-copy
/// - GitHub link processing and context fetching
/// - Thread-safe clipboard operations
///
/// - Important: Uses Sendable-compliant closures for thread safety
@MainActor
final class ContentViewModel: ObservableObject, Sendable {
  private let service = UIThubService()
  private var task: Task<Void, Never>?
  private let logger = Logger(subsystem: "com.llmcontextor.viewmodel", category: "ContentProcessing")
  
  @Published var isAutoCopyEnabled = false
  var lastProcessedString = ""
  
  init() {
    logger.info("Initializing ContentViewModel")
    startMonitoringPasteboard()
  }
  
  /// Starts monitoring the system pasteboard for changes.
  ///
  /// This method sets up a continuous monitoring loop that checks the pasteboard
  /// for new GitHub links every second. It uses structured concurrency through
  /// Task to ensure proper cancellation and memory management.
  ///
  /// - Note: Uses async/await pattern to check the pasteboard for changes periodically
  /// - Important: The monitoring is done in a structured concurrency way using Task
  func startMonitoringPasteboard() {
    logger.info("Starting pasteboard monitoring")
    task?.cancel()
    
    task = Task { [weak self] in
      self?.logger.debug("Initialized pasteboard monitoring task")
      
      // Initialize with current pasteboard content
      let pasteboard = NSPasteboard.general
      var lastChangeCount = pasteboard.changeCount
      
      while !Task.isCancelled {
        // Only process if pasteboard has changed
        if pasteboard.changeCount != lastChangeCount {
          lastChangeCount = pasteboard.changeCount
          
          if let string = pasteboard.string(forType: .string) {
            self?.logger.debug("Found string in pasteboard: \(string)")
            
           // if string != self?.lastProcessedString {
              if string.contains("https://github.com/") {
                self?.logger.info("Detected new GitHub link: \(string)")
                self?.lastProcessedString = string
                await self?.processGitHubLink(string)
              } else {
                self?.logger.debug("String is not a GitHub link, ignoring")
            //  }
            }
          }
        }
        
        do {
          try await Task.sleep(for: .seconds(0.5))
        } catch {
          self?.logger.error("Task sleep interrupted: \(error.localizedDescription)")
        }
      }
    }
  }
  
  /// Processes a GitHub link by fetching its context.
  ///
  /// This method extracts repository information from the link and fetches
  /// the associated context. If auto-copy is enabled, the context is automatically
  /// copied to the clipboard.
  ///
  /// - Parameter link: The GitHub link to process
  private func processGitHubLink(_ link: String) async {
    logger.info("Processing GitHub link: \(link)")
    
    guard let (owner, repo) = service.extractGitHubInfo(from: link) else {
      logger.error("Failed to extract GitHub info from link")
      return
    }
    
    logger.debug("Extracted repo info - owner: \(owner), repo: \(repo)")
    
    do {
      logger.info("Fetching repository contents")
      let context = try await service.fetchRepositoryContents(owner: owner, repo: repo)
      
      if isAutoCopyEnabled {
        logger.info("Auto-copy enabled, copying context to clipboard")
        copyToClipboard(context)
      } else {
        logger.debug("Auto-copy disabled, skipping clipboard operation")
      }
    } catch {
      logger.error("Error fetching context: \(error.localizedDescription)")
      print("Error fetching context: \(error)")
    }
  }
  
  /// Copies the given text to the system clipboard.
  ///
  /// This method clears the current clipboard contents and replaces it
  /// with the provided text.
  ///
  /// - Parameter text: The text to copy to the clipboard
  private func copyToClipboard(_ text: String) {
    logger.info("Copying text to clipboard (\(text.count) characters)")
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
    logger.debug("Successfully copied text to clipboard")
  }
} 
