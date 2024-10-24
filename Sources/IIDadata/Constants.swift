//
//  Constants.swift
//  IIDadata
//
//  Created by Yachin Ilya on 11.05.2020.
//

import Foundation

// MARK: - Constants

enum Constants {
  static let suggestionsAPIURL = "http://suggestions.dadata.ru/suggestions/api/4_1/rs/"
  static let fioSuggestionsAPIURL = "http://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/fio"
  static let addressEndpoint = AddressQueryType.address.rawValue
  static let addressFIASOnlyEndpoint = AddressQueryType.fiasOnly.rawValue
  static let addressByIDEndpoint = AddressQueryType.findByID.rawValue
  static let revGeocodeEndpoint = "geolocate/address"
  static let infoPlistTokenKey = "IIDadataAPIToken"
}

// MARK: - AddressQueryType

/// API endpoints for different request types.
public enum AddressQueryType: String {
  case address = "suggest/address"
  case fiasOnly = "suggest/fias"
  case findByID = "findById/address"
}

// MARK: - QueryResultLanguage

/// Language of response.
public enum QueryResultLanguage: String, Encodable {
  case ru
  case en
}
