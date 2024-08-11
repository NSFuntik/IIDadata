//
//  IIDadataSuggestionsView.swift
//  IIDadata
//
//  Created by NSFuntik on 11.08.2024.
//
import IIDadata
import SwiftUI

// MARK: - IIDadataSuggestsPopover

/// A view modifier that provides a text field with suggestions as the user types.
///
/// The `IIDadataSuggestable` fetches suggestions for a `TextField`'s input and displays a list of suggestions, obtained asynchronously. When a suggestion is selected, it triggers an action `onSuggestionSelected`.
///
/// - Parameters:
///   - apiKey: The API key for the `Dadata` API.
///   - text: A binding to the input text.
///   - suggestions: A binding to the list of suggestions.
///   - onSuggestionSelected: A closure to handle the selection of a suggestion.
///
/// - Returns: A `View Modifier` that provides a text field with suggestions as the user types.
///
/// - Note: The `getSuggestions` function is called asynchronously and updates the `suggestions` property.
///
/// - SeeAlso: ``DadataSuggestions``
public struct IIDadataSuggestsPopover<T: Suggestion>: ViewModifier {
  /// The action to perform when a suggestion is selected.
  /// - Parameter isPresentingPopover: An input parameter that indicates whether the popover is presented.
  public typealias OnSuggestionSelected = (String) -> Void

  // Properties

  @Binding var text: String
  @Binding var suggestions: [T]?
  let onSuggestionSelected: OnSuggestionSelected

  @StateObject private var dadata: DadataSuggestions
  @Binding private var isPopoverPresented: Bool

  // Lifecycle

  /// Initializes a new instance of a custom view with input text binding, an instance of `DadataSuggestions`,
  /// suggestions binding, placeholder text, and a closure to handle suggestion selection.
  ///
  /// - Parameters:
  ///   - text: A binding to a text input.
  ///   - dadata: An instance of `DadataSuggestions` for fetching suggestions.
  ///   - suggestions: A binding to an optional array of suggestions of type `[T]`.
  ///   - placeholder: A string placeholder text.
  ///   - isPopoverPresented: A binding to a boolean value that indicates whether the popover is presented.
  ///   - onSuggestionSelected: A closure that gets executed when a suggestion is selected.
  public init(
    input text: Binding<String>,
    dadata: DadataSuggestions,
    suggestions: Binding<[T]?>,
    isPresented: Binding<Bool>,
    onSuggestionSelected: @escaping (String) -> Void
  ) {
    _dadata = StateObject(wrappedValue: dadata)
    _text = text
    _suggestions = suggestions
    _isPopoverPresented = isPresented
    self.onSuggestionSelected = onSuggestionSelected
  }

  /// Initializes a new instance of a custom view with an API key, input text binding,
  /// suggestions binding, and a closure to handle suggestion selection.
  ///
  /// - Parameters:
  ///   - apiKey: A string containing the API key for `DadataSuggestions`.
  ///   - text: A binding to a text input.
  ///   - suggestions: A binding to an optional array of suggestions of type `[T]`.
  ///   - isPresented: A binding to a boolean value that indicates whether the popover is presented.
  ///   - onSuggestionSelected: A closure that gets executed when a suggestion is selected.
  public init(
    apiKey: String,
    input text: Binding<String>,
    suggestions: Binding<[T]?>,
    isPresented: Binding<Bool>,
    onSuggestionSelected: @escaping (String) -> Void
  ) {
    _dadata = StateObject(wrappedValue: DadataSuggestions(apiKey: apiKey))
    _text = text
    _suggestions = suggestions
    _isPopoverPresented = isPresented
    self.onSuggestionSelected = onSuggestionSelected
  }

  // Content

  public func body(content: Content) -> some View {
    content
      .onChange(of: text) { _ in
        guard !text.isEmpty else {
          suggestions = nil
          return
        }
        Task(priority: .userInitiated) {
          await getSuggestions()
          isPopoverPresented = suggestions?.isEmpty == false
        }
      }
      .floatingPopover(isPresented: $isPopoverPresented) {
        if let suggestions = suggestions?.compactMap(\.value) {
          SuggestionsPopover(
            with: suggestions,
            onSelect: { suggestion in
              text = suggestion
              onSuggestionSelected(suggestion)
              if suggestions.count == 1 {
                isPopoverPresented = false
              }
            }
          )
        }
      }
  }

  // Functions

  /// Fetches suggestions based on the input text.
  ///
  /// This asynchronous method fetches address or FIO (Full name) suggestions
  /// based on the type of the first element in the `suggestions` array.
  /// If the text input is empty, it sets `suggestions` to `nil`.
  func getSuggestions() async {
    guard !text.isEmpty else {
      suggestions = nil
      return
    }
    do {
      switch suggestions?.first?.type {
      case .address:
        await getAddressSuggestions(address: text)
      case .fio:
        await getFioSuggestions(fio: text)
      case nil:
        throw IIDadataError.noSuggestions
      }
    } catch {
      debugPrint("Error fetching suggestions: \(error)")
    }
  }

  /// Fetches address suggestions based on the current address input.
  ///
  /// This function is called asynchronously and updates the `addressSuggestions` property.
  /// It performs a check to ensure the address input is not empty before fetching suggestions.
  @MainActor
  func getAddressSuggestions(address: String) async {
    guard !address.isEmpty else { return }
    do {
      suggestions = try await dadata.suggestAddress(
        address,
        queryType: .address,
        resultsCount: 10,
        language: .ru
      ).suggestions?.compactMap { $0 as? T }
    } catch {
      print("Error fetching address suggestions: \(error)")
    }
  }

  /// Fetches FIO (Full Name) suggestions based on the current FIO input.
  ///
  /// This function is called asynchronously and updates the `fioSuggestions` property.
  /// It performs a check to ensure the FIO input is not empty before fetching suggestions.
  @MainActor
  func getFioSuggestions(fio: String) async {
    guard !fio.isEmpty else { return }
    do {
      suggestions = try await dadata.suggestFio(
        fio,
        count: 10,
        gender: .male,
        parts: [.surname, .name, .patronymic]
      ).compactMap { $0 as? T }
    } catch {
      print("Error fetching FIO suggestions: \(error)")
    }
  }
}

// MARK: - SuggestionsPopover

/// A view that displays a list of suggestions.
///
/// The `SuggestionsPopover` displays suggestions in a scrollable list and allows the user to select one.
///
/// - Parameters:
///   - suggestions: An array of `Suggestion.Value` to be displayed.
///   - onSelect: A closure to handle the selection of a suggestion.
public struct SuggestionsPopover: View {
  // Properties

  var suggestions: [Suggestion.Value]
  let onSelect: (String) -> Void

  // Lifecycle

  /// Creates a new `SuggestionsPopover`.
  ///
  /// - Parameters:
  ///   - suggestions: An array of `Suggestion.Value` to be displayed.
  ///   - onSelect: A closure that gets executed when a suggestion is selected.
  init(
    with suggestions: [Suggestion.Value],
    onSelect: @escaping (String) -> Void
  ) {
    self.suggestions = suggestions
    self.onSelect = onSelect
  }

  // Content

  public var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 4) {
        ForEach(suggestions, id: \.self) { suggestion in
          Button(action: {
            onSelect(suggestion)
          }) {
            Text(suggestion)
              .font(
                .system(
                  size: 12,
                  weight: .regular,
                  design: .rounded
                )
              )
              .lineLimit(1)
              .truncationMode(.middle)
              .foregroundColor(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .buttonStyle(.automatic)
          .accentColor(.accentColor)
        }
      }
      .padding(8)
    }
  }
}

// MARK: - View Extension

public extension View {
  /// A view modifier to display suggestions for the given input using `Dadata`  API.
  ///
  /// This extension provides an easy way to apply the `IIDadataSuggestsPopover` view modifier to any `View`.
  ///
  /// - Parameters:
  ///   - apiKey: The API key for the `Dadata` API.
  ///   - text: A binding to the input text.
  ///   - suggestions: A binding to the list of suggestions.
  ///   - onSuggestionSelected: A closure to handle the selection of a suggestion.
  ///
  /// - Returns: A view with the `IIDadataSuggestsPopover` modifier applied.
  @ViewBuilder @available(iOS 14.0, *)
  func iidadataSuggestions<T: Suggestion>(
    apiKey: String,
    input text: Binding<String>,
    suggestions: Binding<[T]?>,
    isPresented: Binding<Bool>,
    onSuggestionSelected: @escaping (String) -> Void
  ) -> some View {
    modifier(
      IIDadataSuggestsPopover(
        apiKey: apiKey,
        input: text,
        suggestions: suggestions,
        isPresented: isPresented,
        onSuggestionSelected: onSuggestionSelected
      )
    )
  }

  /// A view modifier to display suggestions for the given input using `Dadata`  API.
  ///
  /// This extension provides an easy way to apply the `IIDadataSuggestsPopover` view modifier to any `View`.
  ///
  /// - Parameters:
  ///   - apiKey: The API key for the `Dadata` API.
  ///   - text: A binding to the input text.
  ///   - suggestions: A binding to the list of suggestions.
  ///   - isPresented: A binding to a boolean value that indicates whether the  popover is presented.
  ///   - onSuggestionSelected: A closure to handle the selection of a suggestion.
  ///
  /// - Returns: A view with the `IIDadataSuggestsPopover` modifier applied.
  @ViewBuilder func iidadataSuggestions<T: Suggestion>(
    dadata: DadataSuggestions,
    input text: Binding<String>,
    suggestions: Binding<[T]?>,
    isPresented: Binding<Bool>,
    onSuggestionSelected: @escaping (String) -> Void
  ) -> some View {
    modifier(
      IIDadataSuggestsPopover(
        input: text,
        dadata: dadata,
        suggestions: suggestions,
        isPresented: isPresented,
        onSuggestionSelected: onSuggestionSelected
      )
    )
  }
}

// #if DEBUG

// MARK: - ContentView

/// A sample view demonstrating the usage of `IIDadataSuggestionsView`.
//  struct ContentView: View {
//    // Nested Types
//
//    // MARK: - IIDadataViewModel
//
//    /// The view model for managing address and FIO suggestions.
//    class IIDadataViewModel: ObservableObject {
//      // Properties
//
//      @Published var address = ""
//      @Published var fio = ""
//      @Published var addressSuggestions: [AddressSuggestion]?
//      @Published var fioSuggestions: [FioSuggestion]?
//
//      private let dadata: DadataSuggestions
//
//      // Lifecycle
//
//      /// Initializes the `IIDadataViewModel` with the appropriate API key.
//      ///
//      /// The API key is fetched from the environment variables.
//      init() {
//        let apiKey = ProcessInfo.processInfo.environment["IIDadataAPIToken"] ?? ""
//        dadata = DadataSuggestions(apiKey: apiKey)
//      }
//
//      // Functions
//
//
//
//    // Properties
//
//    @StateObject private var viewModel = IIDadataViewModel()
//
//    // Content
//
//    var body: some View {
//      VStack(spacing: 16) {
//        IIDadataSuggestionsView(
//          inputText: $viewModel.address,
//          suggestions: $viewModel.addressSuggestions,
//          placeholder: "Enter address",
//          onSuggestionSelected: { _ in },
//          getSuggestions: viewModel.getAddressSuggestions
//        )
//        IIDadataSuggestionsView(
//          inputText: $viewModel.fio,
//          suggestions: $viewModel.fioSuggestions,
//          placeholder: "Enter Full Name",
//          onSuggestionSelected: { _ in },
//          getSuggestions: viewModel.getFioSuggestions
//        )
//      }
//      .padding()
//    }
//  }
//
//  struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//      ContentView()
//    }
//  }
// #endif
