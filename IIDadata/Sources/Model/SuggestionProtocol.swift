//
//  Suggestion.swift
//  IIDadata
//
//  Created by NSFuntik on 09.08.2024.
//

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
public protocol Suggestion: Decodable {
  associatedtype SuggestionData: Decodable
  var unrestrictedValue: String? { get }
  var value: String? { get }
  var data: SuggestionData? { get }
}
