import Foundation

/// A service class responsible for interacting with the UIThub API
class UIThubService {
  /// Fetches repository contents from the UIThub API
  /// - Parameters:
  ///   - owner: The GitHub repository owner
  ///   - repo: The GitHub repository name
  ///   - path: Optional path within the repository
  /// - Returns: The fetched content response
  func fetchRepositoryContents(owner: String, repo: String, path: String = "") async throws -> String {
    let urlString = "https://uithub.com/\(owner)/\(repo)/tree/main/\(path)"
    guard let url = URL(string: urlString) else {
      throw URLError(.badURL)
    }
    
    var request = URLRequest(url: url)
    request.setValue("text/markdown", forHTTPHeaderField: "Accept")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    return String(data: data, encoding: .utf8) ?? ""
  }
  
  /// Extracts owner and repo from a GitHub URL
  /// - Parameter urlString: The GitHub URL string
  /// - Returns: A tuple containing the owner and repo
  func extractGitHubInfo(from urlString: String) -> (owner: String, repo: String)? {
    guard let url = URL(string: urlString),
          url.host == "github.com",
          let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
          let pathComponents = components.path.split(separator: "/").map(String.init) as? [String],
          pathComponents.count >= 2 else {
      return nil
    }
    
    return (owner: pathComponents[0], repo: pathComponents[1])
  }
} 