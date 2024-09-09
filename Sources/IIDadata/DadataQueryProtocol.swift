//
//  DadataQueryProtocol.swift
//  IIDadata
//
//  Created by Yachin Ilya on 12.05.2020.
//

import Foundation

/// Conformance to this protocol requires implementing methods to return a query endpoint string and to convert the entity to JSON.
/// Protocol that defines the blueprint for generating a query endpoint and converting data to JSON.
protocol DadataQueryProtocol {
  /// Generates and returns the endpoint string for the query.
  ///
  /// The implementation should provide the specific endpoint required for the Dadata API request.
  ///
  /// - Returns: A `String` representing the query endpoint.
  func queryEndpoint() -> String

  /// Converts the implementing entity to JSON format.
  /// If the object cannot be serialized, this method throws an error.
  /// This method should provide a way to serialize the entity's data into a JSON `Data` object.
  ///
  /// - Returns: A `Data` object containing the JSON representation of the entity.
  /// - Throws: An error if the serialization fails.
  func toJSON() throws -> Data
}
