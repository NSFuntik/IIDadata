//
//  has.swift
//  IIDadata
//
//  Created by NSFuntik on 09.08.2024.
//

import Foundation
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
public enum Gender: String, Codable, Equatable, Hashable, CaseIterable {
  public static let allCases: [Gender] = [.male, .female]
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

