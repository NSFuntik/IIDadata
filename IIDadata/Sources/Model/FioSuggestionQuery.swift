//
//  FioSuggestionQuery.swift
//  IIDadata
//
//  Created by NSFuntik on 07.08.2024.
//

// MARK: - FIO Suggestion Query and Response Structures

import Foundation

// MARK: - FioSuggestionQuery

/** Подсказки по ФИО (API)
  # Parameters:
 - query:  да  Запрос, для которого нужно получить подсказки
 - count: Количество возвращаемых подсказок (по умолчанию — 10, максимум — 20).
 - parts:  Подсказки по части ФИО
 - gender:  Пол (UNKNOWN / MALE / FEMALE) (``Gender``)

 # Description:
  Помогает человеку быстро ввести ФИО на веб-форме или в приложении.

   ## Что умеет:
   - Подсказывает ФИО одной строкой или отдельно фамилию, имя, отчество.
   - Исправляет клавиатурную раскладку («fynjy» → «Антон»).
   - Определяет пол.

   ## Не умеет:
  - ❌ Автоматически (без участия человека) обработать ФИО из базы или файла.
  - ❌ Транслитерировать (Juliia Somova → Юлия Сомова).
  - ❌ Склонять по падежам (кого? кому? кем?).

 ## Примечания:
  Подсказки не подходят для автоматической обработки ФИО. Они предлагают варианты, но не гарантируют, что угадали правильно. Поэтому окончательное решение всегда должен принимать человек.

  */
public struct FioSuggestionQuery: Codable, DadataQueryProtocol {
  // Nested Types

  public enum Part: String, RawRepresentable, CodingKey, Codable {
    case name = "NAME", patronymic = "PATRONYMIC", surname = "SURNAME"

    // Computed Properties

    public var rawValue: String {
      switch self {
      case .name: return "NAME"
      case .patronymic: return "PATRONYMIC"
      case .surname: return "SURNAME"
      }
    }

    // Lifecycle

    public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      let value = try container.decode(String.self)
      self = Part(rawValue: value) ?? .name
    }

    public init?(rawValue: String) {
      switch rawValue.uppercased() {
      case "NAME": self = .name
      case "PATRONYMIC": self = .patronymic
      case "SURNAME": self = .surname
      default: return nil
      }
    }

    // Functions

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(rawValue)
    }
  }

  enum CodingKeys: String, CodingKey {
    case query, count, parts, gender
  }

  // Properties

  /// The search query string.
  let query: String

  /// The number of suggestions to return (default is 10).
  let count: IntegerLiteralType?

  /// Indicates if the name parts should be returned separately. Default is `false`.
  let parts: [Part]?

  /// Requested gender for the suggested names.
  let gender: Gender?

  // Lifecycle

  /// Initializes a new `FioSuggestionQuery`.
  ///
  /// - Parameters:
  ///   - query: The search query string.
  ///   - count: The number of suggestions to return (default is 10).
  ///   - parts: Indicates if the name parts should be returned separately (default is `false`).
  ///   - gender: Requested gender for the suggested names.
  public init(_ query: String, count: Int? = 10, parts: [Part]? = nil, gender: Gender? = nil) {
    self.query = query
    self.count = count
    self.parts = parts
    self.gender = gender
  }

  // Functions

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(query, forKey: .query)
    try container.encodeIfPresent(count, forKey: .count)
    try container.encodeIfPresent(gender?.codingKey, forKey: .gender)
    if let parts = parts?.compactMap(\.rawValue), !parts.isEmpty {
      try container.encodeIfPresent(parts, forKey: .parts)
    }
  }

  /// Returns the endpoint for the query.
  ///
  /// - Returns: The endpoint as a string.
  func queryEndpoint() -> String {
    return "suggest/fio"
  }

  /// Encodes the query into a JSON data representation.
  ///
  /// - Returns: A `Data` object containing the JSON representation of the query.
  /// - Throws: An error if the encoding fails.
  func toJSON() throws -> Data {
    try JSONEncoder().encode(self)
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

// MARK: - FioSuggestion

/// A structure representing a single FIO suggestion.
public struct FioSuggestion: Codable {
  // Nested Types

  enum CodingKeys: String, CodingKey {
    case value
    case unrestrictedValue = "unrestricted_value"
    case fio = "data"
  }

  // Properties

  /// Detailed FIO data.
  public let fio: FioData

  /// The suggested FIO value.
  let value: String

  /// The unrestricted suggested FIO value.
  let unrestrictedValue: String

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
    fio = data
  }

  // Functions

  public subscript(_ key: FioData.CodingKeys) -> String? {
    return fio[key]
  }
}

// MARK: - Gender

/**
  An enumeration representing gender with support for encoding and decoding,
  equatability, and hashability.
  The `Gender` enum has cases for male, female, and unknown genders, with
  corresponding Russian strings for each case.
  It also has an inner `CodingKeys` enumeration for mapping JSON keys to
  enum cases and an initializer for decoding from a decoder.

 # Parameters:
  - male: The case representing the `male` gender
  - female: The case representing the `female` gender
  - unknown: The case representing an `unknown` gender

 - SeeAlso: ``FioSuggestionResponse``, ``FioSuggestionQuery``

  */
public enum Gender: String, Codable, Equatable, Hashable {
  /// The case representing the `male` gender with a Russian string value.
  case male = "Мужской"
  /// The case representing the `female` gender with a Russian string value.
  case female = "Женский"
  /// The case representing an `unknown` gender with a Russian string value.
  case unknown = "–"

  // Nested Types

  /// An enumeration for defining the coding keys used for decoding.
  public enum CodingKeys: String, CodingKey {
    case male = "MALE"
    case female = "FEMALE"
    case unknown = "UNKNOWN"
  }

  // Computed Properties

  /// The string value corresponding to the `Gender` case.
  public var codingKey: String {
    switch self {
    case .male: return CodingKeys.male.rawValue
    case .female: return CodingKeys.female.rawValue
    case .unknown: return CodingKeys.unknown.rawValue
    }
  }

  // Lifecycle

  /// The `Gender` case corresponding to the given string value.
  public init(rawValue: String) {
    switch rawValue {
    case "Мужской", "MALE": self = .male
    case "Женский", "FEMALE": self = .female
    default: self = .unknown
    }
  }

  /**
   Initializes a `Gender` instance from the given decoder.
   This initializer attempts to decode a string from the specified container
   using the `unknown` coding key. Based on the decoded string, it sets
   the appropriate `Gender` case.

   - Parameter decoder: The decoder to initialize the instance from.
   - Throws: An error if decoding fails.
   */
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(String.self, forKey: .unknown) {
    case "MALE": self = .male
    case "FEMALE": self = .female
    default: self = .unknown
    }
  }
}

// MARK: - FioData

/// A structure representing detailed FIO data.
///
/// - Parameters:
///   - value` :   ФИОодной строкой
///   - unrestricted_value` : value
///   - surname:   Фамилия
///   - name:   Имя
///   - patronymic:    Отчество
///   - gender:   Пол
///   - qc:  Код качества
///   - source: Не заполняется
public struct FioData: Codable, Equatable, Hashable {
  // Nested Types

  public enum CodingKeys: String, CodingKey {
    case surname, name, patronymic, gender, qc

    // Computed Properties

    public var partQueryValue: String {
      switch self {
      case .surname: return "SURNAME"
      case .name: return "NAME"
      case .patronymic: return "PATRONYMIC"
      default: return ""
      }
    }
  }

  // Properties

  /// The surname (last name).
  let surname: String?

  /// The given name (first name).
  let name: String?

  /// The patronymic (middle name).
  let patronymic: String?

  /// The gender of the individual.
  let gender: Gender?

  /// The quality code.
  ///
  ///   - `0`: если все части ФИО найдены в справочниках.
  ///   - `1`: если в ФИО есть часть не из справочника
  /// - `null`: если нет части ФИО в справочниках.
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
    gender: Gender?,
    qc: String?
  ) {
    self.surname = surname
    self.name = name
    self.patronymic = patronymic
    self.gender = gender
    self.qc = qc
  }

  // MARK: - Codable

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    surname = try container.decodeIfPresent(String.self, forKey: .surname)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    patronymic = try container.decodeIfPresent(String.self, forKey: .patronymic)
    gender = try Gender(rawValue: container.decodeIfPresent(Gender.RawValue.self, forKey: .gender) ?? Gender.unknown.rawValue)
    qc = try container.decodeIfPresent(String.self, forKey: .qc)
  }

  // Static Functions

  // MARK: - Comparable

  public static func < (lhs: FioData, rhs: FioData) -> Bool {
    return (lhs.qc ?? "0") < (rhs.qc ?? "0") && lhs.qc != rhs.qc
  }

  // Functions

  /// Returns the full name of the `FioData`.
  public func fullName() -> String {
    return [surname, name, patronymic].compactMap { $0 }.joined(separator: " ")
  }

  // MARK: - Hashable

  public func hash(into hasher: inout Hasher) {
    hasher.combine(surname)
    hasher.combine(name)
    hasher.combine(patronymic)
    hasher.combine(gender)
    hasher.combine(qc)
  }

  public subscript(_ key: CodingKeys) -> String? {
    switch key {
    case .surname:
      return surname
    case .name:
      return name
    case .patronymic:
      return patronymic
    case .gender:
      return gender?.rawValue
    case .qc:
      return qc.map { String($0) }
    }
  }
}
