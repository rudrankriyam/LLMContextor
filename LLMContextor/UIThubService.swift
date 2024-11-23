import Foundation
import OSLog

/// A service actor responsible for interacting with the UIThub API.
///
/// UIThubService provides a thread-safe interface for fetching repository contents
/// and parsing GitHub URLs. It handles all network communication with the UIThub API
/// and includes comprehensive logging for debugging and monitoring purposes.
///
/// ## Usage Example
/// ```swift
/// let service = UIThubService()
/// 
/// // Fetch repository contents
/// let contents = try await service.fetchRepositoryContents(
///   owner: "apple",
///   repo: "swift",
///   path: "docs"
/// )
/// 
/// // Parse GitHub URL
/// if let (owner, repo) = service.extractGitHubInfo(from: "https://github.com/apple/swift") {
///   print("Owner: \(owner), Repo: \(repo)")
/// }
/// ```
///
/// - Important: All methods in this actor are thread-safe by default unless marked as `nonisolated`.
actor UIThubService {
  
  /// A logger instance for tracking service operations.
  /// The subsystem identifier follows reverse DNS notation and the category
  /// reflects the primary responsibility of this service.
  private let logger = Logger(subsystem: "com.uithub.service", category: "Repository")
  
  /// Fetches repository contents from the UIThub API.
  ///
  /// This method performs an asynchronous network request to fetch the contents of a specified
  /// repository path. It automatically handles URL construction and response parsing.
  ///
  /// - Parameters:
  ///   - owner: The GitHub repository owner's username or organization name.
  ///   - repo: The name of the GitHub repository.
  ///   - path: Optional path within the repository. Defaults to empty string for root directory.
  ///
  /// - Returns: A string containing the repository contents in markdown format.
  ///
  /// - Throws: `URLError` in the following cases:
  ///   - `.badURL`: If the constructed URL is invalid
  ///   - `.badServerResponse`: If the server response is invalid
  ///   - `.cannotDecodeContentData`: If the response data cannot be decoded as UTF-8
  ///   - Other `URLError` cases for network-related failures
  ///
  /// - Note: This method requires actor isolation due to its use of shared networking resources.
  func fetchRepositoryContents(owner: String, repo: String, path: String = "") async throws -> String {
    logger.info("Fetching repository contents - owner: \(owner), repo: \(repo), path: \(path)")
    
    let urlString = "https://uithub.com/\(owner)/\(repo)/tree/main/\(path)"
    guard let url = URL(string: urlString) else {
      logger.error("Invalid URL constructed: \(urlString)")
      throw URLError(.badURL)
    }
    
    var request = URLRequest(url: url)
    request.setValue("text/markdown", forHTTPHeaderField: "Accept")
    
    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      
      guard let httpResponse = response as? HTTPURLResponse else {
        logger.error("Invalid response type received")
        throw URLError(.badServerResponse)
      }
      
      logger.debug("Received response with status code: \(httpResponse.statusCode)")
      
      guard let content = String(data: data, encoding: .utf8) else {
        logger.error("Failed to decode response data as UTF-8")
        throw URLError(.cannotDecodeContentData)
      }
      
      logger.info("Successfully fetched repository contents (\(data.count) bytes)")
      return content
    } catch {
      logger.error("Repository fetch failed: \(error.localizedDescription)")
      throw error
    }
  }
  
  /// Extracts owner and repository information from a GitHub URL.
  ///
  /// This method parses a GitHub URL and extracts the owner and repository names.
  /// It can handle both HTTPS and SSH URLs in the following formats:
  /// - https://github.com/owner/repo
  /// - https://github.com/owner/repo.git
  /// - https://github.com/owner/repo/tree/main
  ///
  /// - Parameter urlString: The GitHub URL to parse.
  ///
  /// - Returns: A tuple containing the owner and repository names if successful,
  ///           or `nil` if the URL cannot be parsed.
  ///
  /// - Note: This method is marked as `nonisolated` because it performs pure string parsing
  ///         and doesn't access any actor state. It can be called without `await`.
  ///
  /// ## Example Usage
  /// ```swift
  /// let info = service.extractGitHubInfo(from: "https://github.com/apple/swift")
  /// if let (owner, repo) = info {
  ///   print("Owner: \(owner), Repo: \(repo)")
  /// }
  /// ```
  nonisolated func extractGitHubInfo(from urlString: String) -> (owner: String, repo: String)? {
    logger.debug("Attempting to extract GitHub info from URL: \(urlString)")
    
    guard let url = URL(string: urlString),
          url.host == "github.com",
          let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
          let pathComponents = components.path.split(separator: "/").map(String.init) as? [String],
          pathComponents.count >= 2 else {
      logger.notice("Failed to parse GitHub URL: \(urlString)")
      return nil
    }
    
    logger.info("Successfully extracted GitHub info - owner: \(pathComponents[0]), repo: \(pathComponents[1])")
    return (owner: pathComponents[0], repo: pathComponents[1])
  }
} 