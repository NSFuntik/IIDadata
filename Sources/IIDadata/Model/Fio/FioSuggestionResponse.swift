//
//  FioSuggestionResponse.swift
//  IIDadata
//
//  Created by NSFuntik on 09.08.2024.
//

import Foundation

// MARK: - FioSuggestionResponse

/// A structure representing the response of a FIO suggestion query.
public struct FioSuggestionResponse: Codable {
  // Nested Types

  enum CodingKeys: String, CodingKey {
    case suggestions
  }

  // Properties

  /// An array of FIO suggestions.
  let suggestions: [FioSuggestion]

  // Lifecycle

  /// Initializes a new FioSuggestionResponse.
  ///
  /// - Parameters:
  ///   - suggestions: An array of FIO suggestions.
  public init(suggestions: [FioSuggestion]) {
    self.suggestions = suggestions
  }

  /// Initializes a new instance from the given decoder.
  ///
  /// - Parameter decoder: The decoder to read data from.
  /// - Throws: An error if the decoding fails.
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    suggestions = try values.decode([FioSuggestion].self, forKey: .suggestions)
  }

  // Functions

  /// Encodes the current instance into the given encoder.
  ///
  /// - Parameter encoder: The encoder to write data to.
  /// - Throws: An error if the encoding fails.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(suggestions, forKey: .suggestions)
  }

  /// Encodes the response into a JSON data representation.
  ///
  /// - Returns: A `Data` object containing the JSON representation of the response.
  /// - Throws: An error if the encoding fails.
  func toJSON() throws -> Data {
    return try JSONEncoder().encode(self)
  }

  /// Returns the endpoint for querying.
  ///
  /// - Returns: The endpoint as a string.
  func queryEndpoint() -> String {
    return "suggest/fio"
  }

  /// Returns the type of the query.
  ///
  /// - Returns: The query type as a string.
  func queryType() -> String {
    return "fio"
  }

  /// Returns the number of suggestions in the response.
  ///
  /// - Returns: The count of suggestions.
  func resultsCount() -> Int {
    return suggestions.count
  }
}
