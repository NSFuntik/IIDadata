//
//  FioData.swift
//  IIDadata
//
//  Created by NSFuntik on 09.08.2024.
//

import Foundation

public extension FioSuggestion {
  // MARK: - FioData

  /// A structure representing detailed FIO data.
  ///
  /// - Parameters:
  ///   - surname:   Фамилия
  ///   - name:   Имя
  ///   - patronymic:    Отчество
  ///   - gender:   Пол
  ///   - qc:  Код качества
  ///   - source: Не заполняется
  struct FioData: Codable, Equatable, Hashable {
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
    public let surname: String?

    /// The given name (first name).
    public let name: String?

    /// The patronymic (middle name).
    public let patronymic: String?

    /// The gender of the individual.
    public let gender: Gender?

    /// The quality code.
    ///
    ///   - `0`: если все части ФИО найдены в справочниках.
    ///   - `1`: если в ФИО есть часть не из справочника
    /// - `null`: если нет части ФИО в справочниках.
    public let qc: String?

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
      gender: Gender? = nil,
      qc: String? = nil
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
}
