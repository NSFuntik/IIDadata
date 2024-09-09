//
//  FioSuggestion.swift
//  IIDadata
//
//  Created by NSFuntik on 09.08.2024.
//

// MARK: - FioSuggestion

/// Every single suggestion is represented as `FioSuggestion`.
/// - Parameters:
///   - value` :   ФИО одной строкой
///   - unrestricted_value` : == value
///   - data: Detailed FIO data structure.
///
///
/// All the data returned in response to suggestion query.
///
/// - SeeAlso: ``FioData``
/// 
public struct FioSuggestion: Encodable, Suggestion {
  // Nested Types

  enum CodingKeys: String, CodingKey {
    case value
    case unrestrictedValue = "unrestricted_value"
    case data
  }

  // Properties

  /// Detailed FIO data.
  public let data: FioData?

  /// The suggested FIO value.
  public let value: String

  /// The unrestricted suggested FIO value. (` == value `)
  public let unrestrictedValue: String?

  // Lifecycle

  /// Initializes a new FioSuggestion.
  ///
  /// - Parameters:
  ///   - value: The suggested FIO value.
  ///   - unrestrictedValue: The unrestricted suggested FIO value.
  ///   - data: Detailed FIO data.
  public init(
    _ value: String,
    unrestrictedValue: String,
    data: FioData
  ) {
    self.value = value
    self.unrestrictedValue = unrestrictedValue
    self.data = data
  }

  public init(from decoder: Decoder) throws {
    do {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      value = try values.decode(String.self, forKey: .value)
      unrestrictedValue = try values.decodeIfPresent(String.self, forKey: .unrestrictedValue)
      data = try values.decodeIfPresent(FioData.self, forKey: .data)
    } catch {
      dump(error, name: "FioSuggestion Decoding Error")
      throw error
    }
  }

  // Functions

  public subscript(_ key: FioData.CodingKeys) -> String? {
    return data?[key]
  }
}
