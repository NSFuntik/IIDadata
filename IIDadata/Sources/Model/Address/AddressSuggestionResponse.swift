//
//  Models Generated using http://www.jsoncafe.com/
//  Created on May 11, 2020

import Foundation

// MARK: - AddressSuggestionResponse

/// AddressSuggestionResponse represents a deserializable object used to hold API response.
public struct AddressSuggestionResponse: Decodable, Sendable {
  public let suggestions: [AddressSuggestion]?
}

// MARK: - Metro

/// Structure holding metro station name, name of a line and distance to suggested address.
/// If there aren't metro stations nearby or API token used not subscribed to "Maximal" package
/// `nil` is returned instead.
public struct Metro: Decodable, Sendable {
  // Nested Types

  enum CodingKeys: String, CodingKey {
    case name, line, distance
  }

  // Properties

  public let name: String?
  public let line: String?
  public let distance: String?

  // Lifecycle

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    name = try values.decodeIfPresent(String.self, forKey: .name)
    line = try values.decodeIfPresent(String.self, forKey: .line)

    distance = values.decodeJSONNumber(forKey: CodingKeys.distance)
  }
}
