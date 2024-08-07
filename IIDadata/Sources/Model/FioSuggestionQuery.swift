//
//  FioSuggestionQuery.swift
//  IIDadata
//
//  Created by NSFuntik on 07.08.2024.
//

// MARK: - FIO Suggestion Query and Response Structures

import Foundation

// MARK: - FioSuggestionQuery

/// A structure representing a query for suggesting FIO (Full Name) data.
public struct FioSuggestionQuery: Codable, DadataQueryProtocol {
  // Nested Types

  enum CodingKeys: String, CodingKey {
    case query, count, parts, gender
  }

  // Properties

  /// The search query string.
  let query: String

  /// The number of suggestions to return (default is 10).
  let count: Int?

  /// Indicates if the name parts should be returned separately. Default is `false`.
  let parts: Bool?

  /// Requested gender for the suggested names.
  let gender: String?

  // Lifecycle

  /// Initializes a new `FioSuggestionQuery`.
  ///
  /// - Parameters:
  ///   - query: The search query string.
  ///   - count: The number of suggestions to return (default is 10).
  ///   - parts: Indicates if the name parts should be returned separately (default is `false`).
  ///   - gender: Requested gender for the suggested names.
  public init(_ query: String, count: Int? = 10, parts: Bool? = false, gender: String? = nil) {
    self.query = query
    self.count = count
    self.parts = parts
    self.gender = gender
  }

  // Functions

  /// Returns the endpoint for the query.
  ///
  /// - Returns: The endpoint as a string.
  func queryEndpoint() -> String {
    return "/suggest/fio"
  }

  /// Encodes the query into a JSON data representation.
  ///
  /// - Returns: A `Data` object containing the JSON representation of the query.
  /// - Throws: An error if the encoding fails.
  func toJSON() throws -> Data {
    return try JSONEncoder().encode(self)
  }
}

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
    return "/suggest/fio"
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

// MARK: - FioSuggestion

/// A structure representing a single FIO suggestion.
public struct FioSuggestion: Codable {
  // Nested Types

  enum CodingKeys: String, CodingKey {
    case value
    case unrestrictedValue = "unrestricted_value"
    case data
  }

  // Properties

  /// The suggested FIO value.
  let value: String

  /// The unrestricted suggested FIO value.
  let unrestrictedValue: String

  /// Detailed FIO data.
  let data: FioData

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
}

// MARK: - FioData

/// A structure representing detailed FIO data.
public struct FioData: Codable {
  // Nested Types

  enum CodingKeys: String, CodingKey {
    case surname, name, patronymic, gender, qc
  }

  // Properties

  /// The surname (last name).
  let surname: String?

  /// The given name (first name).
  let name: String?

  /// The patronymic (middle name).
  let patronymic: String?

  /// The gender of the individual.
  let gender: String?

  /// The quality code.
  let qc: String?

  // Lifecycle

  /// Initializes a new FioData.
  ///
  /// - Parameters:
  ///   - surname: The surname (last name).
  ///   - name: The given name (first name).
  ///   - patronymic: The patronymic (middle name).
  ///   - gender: The gender of the individual.
  ///   - qc: The quality code.
  public init(
    surname: String?,
    name: String?,
    patronymic: String?,
    gender: String?,
    qc: String?
  ) {
    self.surname = surname
    self.name = name
    self.patronymic = patronymic
    self.gender = gender
    self.qc = qc
  }
}
