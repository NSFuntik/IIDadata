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
extension FioSuggestion {
  public var type: SuggestionType { .fio }
}

extension AddressSuggestion {
  public var type: SuggestionType { .address }
}

public extension Suggestion {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.value == rhs.value
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }

  var id: String {
    value
  }

  var description: String {
    value
  }
}


// MARK: - SuggestionType

public enum SuggestionType {
  case address
  case fio
}

public enum IIDadataError: Error {
  case noSuggestions
}
