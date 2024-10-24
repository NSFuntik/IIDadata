import protocol Combine.ObservableObject
import Foundation

@available(iOS 14.0, *)
public actor DadataSuggestions: ObservableObject {
	// Static Properties

	private static var sharedInstance: DadataSuggestions?

	// Properties

	/// API key for [Dadata](https://dadata.ru/profile/#info).
	private let apiKey: String

	/// Base URL of suggestions API
	private var suggestionsAPIURL: URL

	// Lifecycle

	/// New instance of DadataSuggestions.
	///
	///
	/// Required API key is read from Info.plist. Each init creates new instance using same token.
	/// If DadataSuggestions is used havily consider `DadataSuggestions.shared()` instead.
	/// - Precondition: Token set with "IIDadataAPIToken"  key in Info.plist.
	/// - Throws: Call may throw if there isn't a value for key "IIDadataAPIToken" set in Info.plist.
	public init() throws {
		let key = try DadataSuggestions.readAPIKeyFromPlist()
		self.init(apiKey: key)
		Self.sharedInstance = self
	}

	/// This init checks connectivity once the class instance is set.
	///
	/// This init should not be called on main thread as it may take up long time as it makes request to server in a blocking manner.
	/// Throws if connection is impossible or request is timed out.
	/// ```
	/// DispatchQueue.global(qos: .background).async {
	///    let dadata = try DadataSuggestions(apiKey: " ", checkWithTimeout: 15)
	/// }
	/// ```
	/// - Parameter apiKey: Dadata API token. Check it in account settings at dadata.ru.
	/// - Parameter checkWithTimeout: Time in seconds to wait for response.
	///
	/// - Throws: May throw on connectivity problems, missing or wrong API token, limits exeeded, wrong endpoint.
	/// May throw if request is timed out.
	public init(api: String /* , checkWithTimeout timeout: Int */ ) throws {
		self.init(apiKey: api)
		Task { try await checkAPIConnectivity() }
		Self.sharedInstance = self
	}

	/// New instance of DadataSuggestions.
	/// - Parameter apiKey: Dadata API token. Check it in account settings at dadata.ru.
	public /* required */ init(apiKey: String) {
		self.init(apiKey: apiKey, url: Constants.suggestionsAPIURL)
		Self.sharedInstance = self
	}

	private init(apiKey: String, url: String) {
		self.apiKey = apiKey
		suggestionsAPIURL = URL(string: url)!
	}

	// Static Functions

	/// Get shared instance of DadataSuggestions class.
	///
	/// Call may throw if neither apiKey parameter is provided
	/// nor a value for key "IIDadataAPIToken" is set in Info.plist
	/// whenever shared instance weren't instantiated earlier.
	/// If another apiKey provided new shared instance of DadataSuggestions recreated with the provided API token.
	/// - Parameter apiKey: Dadata API token. Check it in account settings at dadata.ru.
	public static func shared(apiKey: String? = nil) throws -> DadataSuggestions {
		if let instance = sharedInstance, instance.apiKey == apiKey || apiKey == nil { return instance }

		if let key = apiKey {
			sharedInstance = DadataSuggestions(apiKey: key)
			return sharedInstance!
		}

		let key = try readAPIKeyFromPlist()
		sharedInstance = DadataSuggestions(apiKey: key)
		return sharedInstance!
	}

	private static func readAPIKeyFromPlist() throws -> String {
		var dictionary: NSDictionary?
		if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
			dictionary = NSDictionary(contentsOfFile: path)
		}
		guard let key = dictionary?.value(forKey: Constants.infoPlistTokenKey) as? String else {
			throw NSError(domain: "Dadata API key missing in Info.plist", code: 1, userInfo: nil)
		}
		return key
	}

	// Functions

	/// Basic address suggestions request with only rquired data.
	///
	/// - Parameter query: Query string to send to API. String of a free-form e.g. address part.
	/// - Returns:``AddressSuggestionResponse`` - result of address suggestion query.
	public func suggestAddress(_ query: String) async throws -> AddressSuggestionResponse {
		try await suggestAddress(AddressSuggestionQuery(query))
	}

	/// Address suggestions request.
	///
	/// Limitations, filters and constraints may be applied to query.
	///
	/// - Parameter query: Query string to send to API. String of a free-form e.g. address part.
	/// - Parameter queryType: Lets select whether the request type. There are 3 query types available:
	/// `address` — standart address suggestion query;
	/// `fiasOnly` — query to only search in FIAS database: less matches, state provided address data only;
	/// `findByID` — takes KLADR or FIAS ID as a query parameter to lookup additional data.
	/// - Parameter resultsCount: How many suggestions to return. `1` provides more data on a single object
	/// including latitude and longitude. `20` is a maximum value.
	/// - Parameter language: Suggested results may be in Russian or English.
	/// - Parameter constraints: List of `AddressQueryConstraint` objects to filter results.
	/// - Parameter regionPriority: List of RegionPriority objects to prefer in lookup.
	/// - Parameter upperScaleLimit: Bigger `ScaleLevel` object in pair of scale limits.
	/// - Parameter lowerScaleLimit: Smaller `ScaleLevel` object in pair of scale limits.
	/// - Parameter trimRegionResult: Remove region and city names from suggestion top level.
	/// - Returns:``AddressSuggestionResponse`` - result of address suggestion query.
	@Sendable public func suggestAddress(
		_ query: String,
		queryType: AddressQueryType = .address,
		resultsCount: Int? = 10,
		language: QueryResultLanguage? = nil,
		constraints: [AddressQueryConstraint]? = nil,
		regionPriority: [RegionPriority]? = nil,
		upperScaleLimit: ScaleLevel? = nil,
		lowerScaleLimit: ScaleLevel? = nil,
		trimRegionResult: Bool = false
	) async throws -> AddressSuggestionResponse {
		let suggestionQuery = AddressSuggestionQuery(query, ofType: queryType)

		suggestionQuery.resultsCount = resultsCount
		suggestionQuery.language = language
		suggestionQuery.constraints = constraints
		suggestionQuery.regionPriority = regionPriority
		suggestionQuery.upperScaleLimit = upperScaleLimit != nil ? ScaleBound(value: upperScaleLimit) : nil
		suggestionQuery.lowerScaleLimit = lowerScaleLimit != nil ? ScaleBound(value: lowerScaleLimit) : nil
		suggestionQuery.trimRegionResult = trimRegionResult

		return try await suggestAddress(suggestionQuery)
	}

	/// Address suggestions request.
	///
	/// Allows to pass most of arguments as a strings converting to internally used classes.
	///
	/// - Parameter query: Query string to send to API. String of a free-form e.g. address part.
	/// - Parameter queryType: Lets select whether the request type. There are 3 query types available:
	/// `address` — standart address suggestion query;
	/// `fiasOnly` — query to only search in FIAS database: less matches, state provided address data only;
	/// `findByID` — takes KLADR or FIAS ID as a query parameter to lookup additional data.
	/// - Parameter resultsCount: How many suggestions to return. `1` provides more data on a single object
	/// including latitude and longitude. `20` is a maximum value.
	/// - Parameter language: Suggested results in "ru" — Russian or "en" — English.
	/// - Parameter constraints: Literal JSON string formated according to
	/// [Dadata online API documentation](https://confluence.hflabs.ru/pages/viewpage.action?pageId=204669108).
	/// - Parameter regionPriority: List of regions' KLADR IDs to prefer in lookup as shown in
	/// [Dadata online API documentation](https://confluence.hflabs.ru/pages/viewpage.action?pageId=285343795).
	/// - Parameter upperScaleLimit: Bigger sized object in pair of scale limits.
	/// - Parameter lowerScaleLimit: Smaller sized object in pair of scale limits. Both can take following values:
	/// `country` — Страна,
	/// `region` — Регион,
	/// `area` — Район,
	/// `city` — Город,
	/// `settlement` — Населенный пункт,
	/// `street` — Улица,
	/// `house` — Дом,
	/// `country` — Страна,
	/// - Parameter trimRegionResult: Remove region and city names from suggestion top level.
	/// - Returns:``AddressSuggestionResponse`` - result of address suggestion query.
	/// - Throws: ``DadataError`` if something went wrong.
	public func suggestAddress(
		_ query: String,
		queryType: AddressQueryType = .address,
		resultsCount: Int? = 10,
		language: String? = nil,
		constraints: [String]? = nil,
		regionPriority: [String]? = nil,
		upperScaleLimit: String? = nil,
		lowerScaleLimit: String? = nil,
		trimRegionResult: Bool = false
	) async throws -> AddressSuggestionResponse {
		let queryConstraints: [AddressQueryConstraint]? = try constraints?.compactMap {
			if let data = $0.data(using: .utf8) {
				return try JSONDecoder().decode(AddressQueryConstraint.self, from: data)
			}
			return nil
		}
		let preferredRegions: [RegionPriority]? = regionPriority?.compactMap { RegionPriority(kladr_id: $0) }

		return try await suggestAddress(
			query,
			queryType: queryType,
			resultsCount: resultsCount,
			language: QueryResultLanguage(rawValue: language ?? "ru"),
			constraints: queryConstraints,
			regionPriority: preferredRegions,
			upperScaleLimit: ScaleLevel(rawValue: upperScaleLimit ?? "*"),
			lowerScaleLimit: ScaleLevel(rawValue: lowerScaleLimit ?? "*"),
			trimRegionResult: trimRegionResult
		)
	}

	/// Basic address suggestions request to only search in FIAS database: less matches, state provided address data only.
	///
	/// - Parameter query: Query string to send to API. String of a free-form e.g. address part.
	/// - Returns:``AddressSuggestionResponse`` - result: result of address suggestion query.
	public func suggestAddressFromFIAS(_ query: String) async throws -> AddressSuggestionResponse {
		try await suggestAddress(AddressSuggestionQuery(query, ofType: .fiasOnly))
	}

	/// Basic address suggestions request takes KLADR or FIAS ID as a query parameter to lookup additional data.
	///
	/// - Parameter query: KLADR or FIAS ID.
	/// - Returns:``AddressSuggestionResponse`` - result: result of address suggestion query.
	public func suggestByKLADRFIAS(_ query: String) async throws -> AddressSuggestionResponse {
		try await suggestAddress(AddressSuggestionQuery(query, ofType: .findByID))
	}

	/// Address suggestion request with custom `AddressSuggestionQuery`.
	///
	/// - Parameter query: Query object.
	/// - Returns:``AddressSuggestionResponse`` - result of address suggestion query.
	public func suggestAddress(_ query: AddressSuggestionQuery) async throws -> AddressSuggestionResponse {
		try await fetchResponse(withQuery: query)
	}

	/// Reverse Geocode request with latitude and longitude as a single string.
	///
	/// - Throws: May throw if query is malformed.
	///
	/// - Parameter query: Latitude and longitude as a string. Should have single character separator.
	/// - Parameter delimeter: Character to separate latitude and longitude. Defaults to '`,`'
	/// - Parameter resultsCount: How many suggestions to return. `1` provides more data on a single object
	/// including latitude and longitude. `20` is a maximum value.
	/// - Parameter language: Suggested results in "ru" — Russian or "en" — English.
	/// - Parameter searchRadius: Radius to suggest objects nearest to coordinates point.
	/// - Returns:``AddressSuggestionResponse`` - result of address suggestion query.
	public func reverseGeocode(
		query: String,
		delimiter: Character = ",",
		resultsCount: Int? = 10,
		language: String? = "ru",
		searchRadius: Int? = nil
	) async throws -> AddressSuggestionResponse {
		let geoquery = try ReverseGeocodeQuery(query: query, delimeter: delimiter)
		geoquery.resultsCount = resultsCount
		geoquery.language = QueryResultLanguage(rawValue: language ?? "ru")
		geoquery.searchRadius = searchRadius

		return try await reverseGeocode(geoquery)
	}

	/// Reverse Geocode request with latitude and longitude as a single string.
	///
	/// - Parameter latitude: Latitude.
	/// - Parameter longitude: Longitude.
	/// - Parameter resultsCount: How many suggestions to return. `1` provides more data on a single object
	/// including latitude and longitude. `20` is a maximum value.
	/// - Parameter language: Suggested results may be in Russian or English.
	/// - Parameter searchRadius: Radius to suggest objects nearest to coordinates point.
	/// - Returns:``AddressSuggestionResponse`` - result of address suggestion query.
	public func reverseGeocode(
		latitude: Double,
		longitude: Double,
		resultsCount: Int? = 10,
		language: QueryResultLanguage? = nil,
		searchRadius: Int? = nil
	) async throws -> AddressSuggestionResponse {
		let geoquery = ReverseGeocodeQuery(latitude: latitude, longitude: longitude)
		geoquery.resultsCount = resultsCount
		geoquery.language = language
		geoquery.searchRadius = searchRadius

		return try await fetchResponse(withQuery: geoquery)
	}

	/// Reverse geocode request with custom `ReverseGeocodeQuery`.
	///
	/// - Parameter query: Query object.
	/// - Returns:``AddressSuggestionResponse`` - result of address suggestion query.
	public func reverseGeocode(_ query: ReverseGeocodeQuery) async throws -> AddressSuggestionResponse {
		try await fetchResponse(withQuery: query)
	}

	/// Suggests a list of FIO (Family, Given, and Middle Names) based on the provided query.
	///
	/// This asynchronous method fetches suggestions for FIO (Family, Given, and Middle Names) from a remote server.
	///
	///
	///   - Parameter query: A string containing the name or partial name for which suggestions are required.
	///   - Parameter count: The maximum number of suggestions to return. Defaults to 10 if not specified.
	///   - Parameter gender: The `gender` of the person. Defaults to `nil` if not specified.
	///   - Parameter parts: Indicates if the `fullname parts` should be returned separately. Defaults to `nil` if not specified.
	/// - Returns: An array of `FioSuggestion` objects matching the query.
	/// - Throws: An error if the request fails or the server returns an error.
	///
	/// This method constructs a `FioSuggestionQuery` object with the given query and count, then fetches the response
	/// using the `fetchResponse(withQuery:)` method.
	public func suggestFio(
		_ query: String,
		count: Int = 10,
		gender: Gender? = nil,
		parts: [FioSuggestionQuery.Part]? = nil
	) async throws -> [FioSuggestion] {
		let fioSuggestionQuery = FioSuggestionQuery(
			query,
			count: count,
			parts: parts,
			gender: gender
		)
		debugPrint("FioSuggestionQuery: \n \(fioSuggestionQuery)")
		let fioSuggestionResponse: FioSuggestionResponse = try await fetchResponse(withQuery: fioSuggestionQuery)
		debugPrint(fioSuggestionResponse)
		return fioSuggestionResponse.suggestions
	}

	func checkAPIConnectivity() async throws {
		let request = createRequest(url: suggestionsAPIURL.appendingPathComponent(Constants.addressEndpoint))

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse,
					(200 ... 299).contains(httpResponse.statusCode)
		else {
			dump(response, name: "API Connectivity Response")
			throw nonOKResponseToError(response: (response as? HTTPURLResponse) ?? .init(), body: data)
		}
	}

	// MARK: - Private

	private func createRequest(url: URL) -> URLRequest {
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.addValue("Token " + apiKey, forHTTPHeaderField: "Authorization")

		dump(request, name: "Request \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "Unable to decode request body")")
		return request
	}

	private func nonOKResponseToError(response: HTTPURLResponse, body data: Data?) -> Error {
		let code = response.statusCode
		var info: [String: Any] = [:]
		response.allHeaderFields.forEach { if let k = $0.key as? String { info[k] = $0.value } }
		if let data = data {
			let object = try? JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any]
			object?.forEach { if let k = $0.key as? String { info[k] = $0.value } }
		}
		return NSError(domain: "HTTP Status \(HTTPURLResponse.localizedString(forStatusCode: code))", code: code, userInfo: info)
	}

	private func fetchResponse<T: Decodable>(withQuery query: DadataQueryProtocol) async throws -> T {
		var request = createRequest(url: suggestionsAPIURL.appendingPathComponent(query.queryEndpoint()))
		request.httpBody = try query.toJSON()
		dump(String(data: request.httpBody ?? Data(), encoding: .utf8), name: "Request \(T.self)")
		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw NSError(domain: "Invalid response", code: 0, userInfo: nil)
		}

		guard (200 ... 299).contains(httpResponse.statusCode) else {
			throw NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: ["description": httpResponse.description])
		}

		return try JSONDecoder().decode(T.self, from: data)
	}
}
