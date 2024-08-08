@testable import IIDadata
import XCTest

final class DadataSuggestionsTests: XCTestCase {
  // Properties

//  let apiKey = "abadf779d0525bebb9e16b72a97eabf4f7143292"

  // Computed Properties

  private var apiToken: String {
    // Replace with your actual Dadata API token
    return "abadf779d0525bebb9e16b72a97eabf4f7143292"
  }

  // Functions

  // Address Suggestion Tests
  func testSuggestAddress_BasicQuery() async throws {
    let suggestions = try await DadataSuggestions(apiKey: apiToken)
      .suggestAddress("Москва, Красная площадь")
    XCTAssertGreaterThan(suggestions.suggestions?.count ?? 0, 0)
  }

  func testSuggestAddress_FilterByRegion() async throws {
    var constraint = AddressQueryConstraint()
    constraint.region = "Москва"
    let suggestions = try await DadataSuggestions(apiKey: apiToken)
      .suggestAddress(
        "Москва, Красная площадь",
        constraints: [constraint]
      )
    XCTAssertGreaterThan(suggestions.suggestions?.count ?? 0, 0)
    XCTAssertEqual(suggestions.suggestions?.first?.data?.region, "Москва")
  }

  func testSuggestAddress_FilterByCity() async throws {
    var constraint = AddressQueryConstraint()
    constraint.city = "Москва"
    let suggestions = try await DadataSuggestions(apiKey: apiToken)
      .suggestAddress(
        "Москва, Красная площадь",
        constraints: [constraint]
      )
    XCTAssertGreaterThan(suggestions.suggestions?.count ?? 0, 0)
    XCTAssertEqual(suggestions.suggestions?.first?.data?.city, "Москва")
  }

  func testSuggestAddress_FindByID() async throws {
    let suggestions = try await DadataSuggestions(apiKey: apiToken)
      .suggestByKLADRFIAS("9120b43f-2fae-4838-a144-85e43c2bfb29")
    XCTAssertGreaterThan(suggestions.suggestions?.count ?? 0, 0)
  }

  func testReverseGeocode_LatLon() async throws {
    let suggestions = try await DadataSuggestions(apiKey: apiToken)
      .reverseGeocode(latitude: 55.755826, longitude: 37.617300)
    XCTAssertGreaterThan(suggestions.suggestions?.count ?? 0, 0)
  }

  func testReverseGeocode_LatLonString() async throws {
    let suggestions = try await DadataSuggestions(apiKey: apiToken)
      .reverseGeocode(query: "55.755826, 37.617300")
    XCTAssertGreaterThan(suggestions.suggestions?.count ?? 0, 0)
  }

  func testReverseGeocode_WithRadius() async throws {
    let suggestions = try await DadataSuggestions(apiKey: apiToken)
      .reverseGeocode(latitude: 55.755826, longitude: 37.617300, searchRadius: 100)
    XCTAssertGreaterThan(suggestions.suggestions?.count ?? 0, 0)
  }

  // FIO Suggestion Tests
  func testSuggestFIO_BasicQuery() async throws {
    do {
      let suggestions = try await DadataSuggestions(apiKey: apiToken).suggestFio("Иванов")
      dump(suggestions, name: "FIO_BasicQuery ")
      XCTAssertGreaterThan(suggestions.count, 0)

    } catch {
      XCTFail(String(describing: error))
    }
  }

  func testSuggestFIO_FilterByGender() async throws {
    do {
      let suggestions = try await DadataSuggestions(apiKey: apiToken)
        .suggestFio("Иванов", gender: .male)
      dump(suggestions, name: "FIO_FilterByGender ")
      XCTAssertGreaterThan(suggestions.count, 0)

    } catch {
      XCTFail(String(describing: error))
    }
  }

  func testSuggestFIO_FilterByParts() async throws {
    do {
      let suggestions = try await DadataSuggestions(apiKey: apiToken)
        .suggestFio("Иванов Иван", parts: [.surname, .name])
      dump(suggestions, name: "FIO_FilterByParts suggestions")
      XCTAssertGreaterThan(suggestions.count, 0)

    } catch {
      XCTFail(String(describing: error))
    }
  }
}
