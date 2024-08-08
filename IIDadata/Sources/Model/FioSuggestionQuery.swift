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
  public init(
    _ query: String,
    count: Int? = 10,
    parts: [Part]? = nil,
    gender: Gender? = nil
  ) {
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
