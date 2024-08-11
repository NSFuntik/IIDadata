import SwiftUI
import IIDadata
import IIDadataUI

struct ExampleView: View {
  // Properties

  let apiKey: String // = ProcessInfo.processInfo.environment["IIDadataAPIToken"] ?? ""

  @StateObject private var dadata: DadataSuggestions
  @State private var error: String? = nil
  @State private var fio = ""
  @State private var address = "Грибал"

  @State private var fioSuggestions: [FioSuggestion]? = [
    FioSuggestion(
      "Иванов Иван Иванович",
      unrestrictedValue: "Иванов Иван Иванович",
      data: .init(surname: "Иванов", name: "Иван", patronymic: "Иванович", gender: .male, qc: nil)
    )]
  @State private var addressSuggestions: [AddressSuggestion]? = [
    AddressSuggestion(
      value: "Санкт-Петербург",
      data: .init(city: "Санкт-Петербург"),
      unrestrictedValue: "Санкт-Петербург"
    ),
  ]

  @State private var isFioSuggestionsPresented = false
  @State private var isAddressSuggestionsSuggestionsPresented = true

  // Lifecycle

  init() {
    let apiKey = ProcessInfo.processInfo.environment["IIDadataAPIToken"] ?? ""
    self.apiKey = apiKey
    _dadata = StateObject(wrappedValue: DadataSuggestions(apiKey: apiKey))
  }

  // Content

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("**API key:** \(apiKey)").font(.subheadline)
      if let error {
        Text("**Error:** \(error)").font(.footnote)
          .fontWeight(.medium).multilineTextAlignment(.center)
          .foregroundStyle(.red)
      }
      Spacer()
      TextField("Address", text: $address, prompt: Text("Enter address"))
        .textFieldStyle(.roundedBorder)
        .textContentType(.fullStreetAddress).tint(.blue)
        .multilineTextAlignment(.leading)
        .lineLimit(3)
        .task(id: address, priority: .utility, getAddressSuggesttions)
        .iidadataSuggestions(
          apiKey: apiKey,
          input: $address,
          suggestions: $addressSuggestions,
          isPresented: $isAddressSuggestionsSuggestionsPresented,
          onSuggestionSelected: {
          address = $0
          if addressSuggestions?.count == 1 {
            isFioSuggestionsPresented = false
            isAddressSuggestionsSuggestionsPresented = false
          }
        })
      TextField("FullName", text: $fio, prompt: Text("Enter FullName"))
        .textFieldStyle(.roundedBorder)
        .textContentType(.familyName).tint(.blue)
        .multilineTextAlignment(.leading)
        .lineLimit(3)
        .task(id: fio, priority: .utility, getFioSuggesttions)
        .iidadataSuggestions(
          apiKey: apiKey,
          input: $fio,
          suggestions: $fioSuggestions,
          isPresented: $isFioSuggestionsPresented,
          onSuggestionSelected: {
          fio = $0
          if fioSuggestions?.count == 1 {
            isFioSuggestionsPresented = false
            isAddressSuggestionsSuggestionsPresented = false
          }
        })
      Spacer()
    }
    .padding()
  }

  @ViewBuilder
  func SuggestionsList(_ suggestions: [String], value: Binding<String>) -> some View {
    if !suggestions.isEmpty {
      ScrollView {
        VStack(alignment: .leading, spacing: 4) {
          ForEach(suggestions, id: \.self) { suggestion in
            Button(suggestion) {
              value.wrappedValue = suggestion
              if suggestions.count == 1 {
                isFioSuggestionsPresented = false
                isAddressSuggestionsSuggestionsPresented = false
              }
            }
            .font(.body)
            .lineLimit(1)
            .truncationMode(.middle)
            .frame(maxWidth: UIScreen.main.bounds.width - 44, alignment: .leading)
            .tint(.secondary)
            .multilineTextAlignment(.leading)
            .safeAreaInset(edge: .top) {
              Divider()
            }
          }
        }.padding().fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  // Functions

  @Sendable @MainActor func getFioSuggesttions() async {
    guard !fio.isEmpty else { return }
    do {
      error = nil
      let suggestedFioResponce = try await dadata.suggestFio(
        fio,
        count: 10,
        gender: .male, parts: [FioSuggestionQuery.Part.surname, .name, .patronymic]
      )
      guard
        !suggestedFioResponce.isEmpty
      else {
        throw DecodingError.dataCorrupted(
          .init(codingPath: [],
                debugDescription: "Suggested FIO Responce is Empty")
        )
      }
      fioSuggestions = suggestedFioResponce
      isFioSuggestionsPresented = true
    } catch {
      isFioSuggestionsPresented = false
      self.error = String(reflecting: error)
    }
  }

  @Sendable @MainActor func getAddressSuggesttions() async {
    guard !address.isEmpty else { return }
    do {
      error = nil
      let suggestedAddressResponce = try await dadata.suggestAddress(
        address,
        queryType: .address,
        resultsCount: 10,
        language: .ru,
        upperScaleLimit: .city,
        lowerScaleLimit: .flat,
        trimRegionResult: true
      )
      guard let addressSuggestions = suggestedAddressResponce.suggestions,
            !addressSuggestions.isEmpty
      else {
        throw DecodingError.dataCorrupted(
          .init(
            codingPath: [],
            debugDescription: "Suggested Address Responce is Empty or Nil"
          )
        )
      }
      self.addressSuggestions = addressSuggestions
      isAddressSuggestionsSuggestionsPresented = true
    } catch {
      isAddressSuggestionsSuggestionsPresented = false
      self.error = String(reflecting: error)
    }
  }
}

#Preview {
  ExampleView()
}

//// MARK: - ContentView
//
///// A sample view demonstrating the usage of `IIDadataSuggestionsView`.
//struct ContentView: View {
//  // Nested Types
//
//  // MARK: - IIDadataViewModel
//
//  /// The view model for managing address and FIO suggestions.
//  class IIDadataViewModel: ObservableObject {
//    // Properties
//
//    @Published var address = ""
//    @Published var fio = ""
//    @Published var addressSuggestions: [AddressSuggestion]?
//    @Published var fioSuggestions: [FioSuggestion]?
//
//    private let dadata: DadataSuggestions
//
//    // Lifecycle
//
//    /// Initializes the `IIDadataViewModel` with the appropriate API key.
//    ///
//    /// The API key is fetched from the environment variables.
//    init() {
//      let apiKey = ProcessInfo.processInfo.environment["IIDadataAPIToken"] ?? ""
//      dadata = DadataSuggestions(apiKey: apiKey)
//    }
//
//    // Functions
//
//    /// Fetches address suggestions based on the current address input.
//    ///
//    /// This function is called asynchronously and updates the `addressSuggestions` property.
//    /// It performs a check to ensure the address input is not empty before fetching suggestions.
//    @MainActor
//    func getAddressSuggestions() async {
//      guard !address.isEmpty else { return }
//      do {
//        addressSuggestions = try await dadata.suggestAddress(
//          address,
//          queryType: .address,
//          resultsCount: 10,
//          language: .ru
//        ).suggestions
//      } catch {
//        print("Error fetching address suggestions: \(error)")
//      }
//    }
//
//    /// Fetches FIO (Full Name) suggestions based on the current FIO input.
//    ///
//    /// This function is called asynchronously and updates the `fioSuggestions` property.
//    /// It performs a check to ensure the FIO input is not empty before fetching suggestions.
//    @MainActor
//    func getFioSuggestions() async {
//      guard !fio.isEmpty else { return }
//      do {
//        fioSuggestions = try await dadata.suggestFio(
//          fio,
//          count: 10,
//          gender: .male,
//          parts: [.surname, .name, .patronymic]
//        )
//      } catch {
//        print("Error fetching FIO suggestions: \(error)")
//      }
//    }
//  }
//
//  // Properties
//
//  @StateObject private var viewModel = IIDadataViewModel()
//
//  // Content
//
//  var body: some View {
//    VStack(spacing: 16) {
//      IIDadataSuggestionsView(
//        inputText: $viewModel.address,
//        suggestions: $viewModel.addressSuggestions,
//        placeholder: "Enter address",
//        onSuggestionSelected: { _ in },
//        getSuggestions: viewModel.getAddressSuggestions
//      )
//      IIDadataSuggestionsView(
//        inputText: $viewModel.fio,
//        suggestions: $viewModel.fioSuggestions,
//        placeholder: "Enter Full Name",
//        onSuggestionSelected: { _ in },
//        getSuggestions: viewModel.getFioSuggestions
//      )
//    }
//    .padding()
//  }
//}
//
//struct ContentView_Previews: PreviewProvider {
//  static var previews: some View {
//    ContentView()
//  }
//}
