//
//  Suggestion.swift
//  IIDadata
//
//  Created by NSFuntik on 09.08.2024.
//
import SwiftUI

// MARK: - Suggestion

/**
   Автодополнение при вводе («подсказки»)\
   Протокол, которыйпредставляет собой десериализуемый объект, используемый для хранения ответа [DaData ](https://dadata.ru/) API

   - Parameter value: текст подсказки одной строкой.
   - Parameter unrestrictedValue: дополнительное поле для текста подсказки.
   - Important: Поля не предназначены для автоматических интеграций, потому что их формат может со временем измениться

 >  Пример как заполняются поля для разных справочников:
 > - ``AddressSuggestion``:  Помогает человеку быстро ввести корректный адрес на веб-форме или в приложении.
 > - ``FioSuggestion``: Помогает человеку быстро ввести ФИО на веб-форме или в приложении
   - SeeAlso: [DaData API documentation](https://dadata.ru/api/suggest/)
 */
public protocol Suggestion: Decodable, Equatable, Hashable, Identifiable, Sendable {
  typealias Value = String
  associatedtype Data: Decodable
  var unrestrictedValue: Value? { get }
  var value: Value { get }
  var data: Data? { get }
  var type: SuggestionType { get }
}

public extension Suggestion where Self == FioSuggestion {
  /// A computed property that returns the suggestion type for Fio suggestion, which is `.fio`
  var type: SuggestionType { .fio }
}

public extension Suggestion where Self == AddressSuggestion {
  /// A computed property that returns the suggestion type for Address suggestion, which is `.address`
  var type: SuggestionType { .address }
}

public extension Suggestion {
  /// Compares two Suggestion instances for equality based on their `value` property.
  ///
  /// - Parameters:
  ///   - lhs: The left-hand side `Suggestion` instance.
  ///   - rhs: The right-hand side `Suggestion` instance.
  /// - Returns: A Boolean value indicating whether the two instances are equal.
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.value == rhs.value
  }

  /// Hashes the essential components of the `Suggestion` instance by combining the `value` property.
  ///
  /// - Parameter hasher: The hasher to use when combining the components of this instance.
  func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }

  /// A computed property that returns the ID of the `Suggestion` instance, which is the `value` property.
  var id: String {
    value
  }

  /// A computed property that returns a description of the `Suggestion` instance, which is the `value` property.
  var description: String {
    value
  }
}

// MARK: - SuggestionType

/**
 An enumeration representing the types of suggestions available.
 - `address`: Suggestion for an address.
 - `fio`: Suggestion for a full name (first name, last name, etc.).
 */
public enum SuggestionType {
  case address
  case fio
}

// MARK: - IIDadataError

/**
 An enumeration representing possible errors that can occur while fetching suggestions.
 - `noSuggestions`: Indicates that no suggestions were found.
 */
public enum IIDadataError: Error {
  case noSuggestions
  case invalidInput
  case invalidResponse
  case unknown(String)
}
