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
@available(iOS 15.0, *)
public struct IIDadataSuggestsPopover<S: Suggestion>: ViewModifier {
  /// The action to perform when a suggestion is selected.
  /// - Parameter isPresentingPopover: An input parameter that indicates whether the popover is presented.
  public typealias OnSuggestionSelected = (S) -> Void

  // Properties

  /// The action to perform when a suggestion is selected.
  public var onSuggestionSelected: OnSuggestionSelected

  /// The TextField input text.
  @Binding var text: String
  /// The list of suggestions.
  @Binding var suggestions: [S]?

  let viewID = UUID().uuidString

  /// The DadataSuggestions instance for fetching suggestions.
  @ObservedObject private var dadata: DadataSuggestions
  /// A binding to a boolean value that indicates whether the popover is presented.
  @Binding private var isPopoverPresented: Bool
  /// The error message.
  @State private var error: String? = nil

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
    suggestions: Binding<[S]?>,
    isPresented: Binding<Bool>,
    onSuggestionSelected: @escaping (S) -> Void
  ) where S: Suggestion {
    _dadata = ObservedObject(wrappedValue: dadata)
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
    suggestions: Binding<[S]?>,
    isPresented: Binding<Bool>,
    onSuggestionSelected: @escaping (S) -> Void
  ) where S: Suggestion {
    _dadata = ObservedObject(wrappedValue: DadataSuggestions(apiKey: apiKey))
    _text = text
    _suggestions = suggestions
    _isPopoverPresented = isPresented
    self.onSuggestionSelected = onSuggestionSelected
  }

  // Content

  @ViewBuilder
  public func body(content: Content) -> some View {
    if #available(iOS 16.4, *) {
      main(content).popover(isPresented: $isPopoverPresented) {
        content
          .presentationCompactAdaptation(.popover)
          .fixedSize()
      }
    } else {
      main(content).popover(
        isPresented: $isPopoverPresented,
        arrowEdge: .bottom,
        content: popoverContent
      )
    }
  }

  @ViewBuilder
  public func main(_ content: Content) -> some View {
    content

      .onAppear {
        isPopoverPresented = !text.isEmpty
      }
      .onChange(of: text, perform: getSuggestions(for:))
  }

  @ViewBuilder
  func popoverContent() -> some View {
    if let suggestions = suggestions?.compactMap(\.self) {
      SuggestionsPopover(
        with: suggestions,
        onSelect: { suggestion in
          text = suggestion.value
          onSuggestionSelected(suggestion)
          if suggestions.count == 1 {
            isPopoverPresented = false
          }
        }
      ).fixedSize()
    } else {
      VStack {
        ProgressView().progressViewStyle(.circular)
        if let error = error {
          Text("Error fetching suggestions: " + error)
        } else {
          Text("Fetching suggestions...")
        }
      }
      .padding()
      .foregroundColor(.secondary)
      .font(.caption)
    }
  }

  // Functions

  /// Fetches suggestions based on the input text.
  ///
  @MainActor
  private func getSuggestions(for input: String) {
    Task { await getAsyncSuggestions(for: input) }
  }

  /// Fetches suggestions based on the input text.
  ///
  @MainActor @Sendable
  private func getAsyncSuggestions(for input: String) async {
//    let input = text
    isPopoverPresented = !input.isEmpty
    guard !input.isEmpty else {
      suggestions = nil
      error = "Error fetching suggestions: \(IIDadataError.invalidInput)"
      return
    }

    do {
      isPopoverPresented = true
      switch S.self {
      case is AddressSuggestion.Type:
        if let addressSuggestions = try await getAddressSuggestions(for: input) as? [S] {
          suggestions = addressSuggestions
        } else {
          throw IIDadataError.noSuggestions
        }
      case is FioSuggestion.Type:
        if let fioSuggestions = try await getFioSuggestions() as? [S] {
          suggestions = fioSuggestions
        } else {
          throw IIDadataError.noSuggestions
        }
      default:
        throw IIDadataError.unknown(String(describing: S.self))
      }
    } catch {
      self.error = "Error fetching suggestions: \(error)"
      suggestions = nil
    }
  }
}

@available(iOS 15.0, *)
extension IIDadataSuggestsPopover {
  /// Fetches suggestions based on the input text.
  ///
  /// This asynchronous method fetches address or FIO (Full name) suggestions
  /// based on the type of the first element in the `suggestions` array.
  /// Fetches `FIO` (`Full Name`) suggestions based on the current FIO input.
  /// It performs a check to ensure the FIO input is not empty before fetching suggestions.
  ///
  /// - Throws: ``IIDadataError`` if an error occurs while fetching suggestions.
  func getFioSuggestions() async throws(IIDadata.IIDadataError) -> [FioSuggestion] /* where S == IIDadata.FioSuggestion */ {
    guard !text.isEmpty else {
      suggestions = nil
      throw IIDadataError.invalidInput
    }
    do {
      let suggestions = try await dadata.suggestFio(
        text,
        count: 10,
        gender: .male
      )
      dump(suggestions, name: "FIO Suggestion for: \(text)")
      return suggestions as [FioSuggestion]
    } catch let error as IIDadataError {
      self.error = "Error fetching FIO suggestions: \(error)"
      throw error
    } catch {
      self.error = "Error fetching FIO suggestions: \(error)"
      throw IIDadataError.unknown(error.localizedDescription)
    }
  }
}

@available(iOS 15.0, *)
extension IIDadataSuggestsPopover {
  /// Fetches suggestions based on the input text.
  ///
  /// This asynchronous method fetches address or FIO (Full name) suggestions
  /// based on the type of the first element in the `suggestions` array.
  /// If the text input is empty, it sets `suggestions` to `nil`.
  ///
  /// This function is called asynchronously and updates the `addressSuggestions` property.
  /// It performs a check to ensure the address input is not empty before fetching suggestions.
  /// - Throws: ``IIDadataError`` – an error object that indicates the type of error that occurred during the fetch process.
  /// - Returns: An array of `AddressSuggestion` objects representing the fetched suggestions.
  /// - SeeAlso: ``DadataSuggestions``
  func getAddressSuggestions(for text: String) async throws(IIDadata.IIDadataError) -> [AddressSuggestion] {
    guard !text.isEmpty else {
      suggestions = nil
      throw IIDadataError.invalidInput
    }
    do {
      guard let suggestions = try await dadata.suggestAddress(
        text,
        queryType: .address,
        resultsCount: 10,
        language: .ru
      ).suggestions
      else {
        throw IIDadataError.noSuggestions
      }

      dump(suggestions, name: "Address Suggestion for: \(text)")
      return suggestions as [AddressSuggestion]

    } catch let error as IIDadataError {
      self.error = "Error fetching Address Suggestions: \(error)"
      throw error
    } catch {
      self.error = "Error fetching Address Suggestions: \(error)"
      throw IIDadataError.unknown(error.localizedDescription)
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
///
/// - Returns: A `View` that displays a list of suggestions.
@available(iOS 15.0, *)
public struct SuggestionsPopover<S: Suggestion>: View {
  // Properties

  var suggestions: [S]
  let onSelect: (S) -> Void

  let maxWidth: CGFloat = UIScreen.main.bounds.width - 44

  // Lifecycle

  /// Creates a new `SuggestionsPopover`.
  ///
  /// - Parameters:
  ///   - suggestions: An array of `Suggestion.Value` to be displayed.
  ///   - onSelect: A closure that gets executed when a suggestion is selected.
  init(
    with suggestions: [S],
    onSelect: @escaping (S) -> Void
  ) {
    self.suggestions = suggestions
    self.onSelect = onSelect
  }

  // Content

  public var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 4) {
        ForEach(suggestions, id: \.self, content: SelectedSuggestionView(_:))
      }
      .padding(8)
      .background(.regularMaterial)
      .animation(.interactiveSpring, value: suggestions)
    }
  }

  @ViewBuilder
  func SelectedSuggestionView(_ suggestion: S) -> some View {
    Button(action: {
      onSelect(suggestion)
    }) {
      Text(suggestion.value)
        .font(
          .system(.subheadline, design: .rounded)
        )
        .lineLimit(1)
        .truncationMode(.middle)
        .foregroundColor(.secondary)
        .frame(minWidth: 166, maxWidth: maxWidth, alignment: .leading)
    }
    .buttonStyle(.borderless)
    .accentColor(.accentColor)
    .frame(maxWidth: maxWidth)
    .safeAreaInset(edge: .bottom) {
      Divider()
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
  @ViewBuilder @available(iOS 15.0, *)
  func iidadataSuggestions<S: Suggestion>(
    apiKey: String,
    input text: Binding<String>,
    suggestions: Binding<[S]?>,
    isPresented: Binding<Bool>,
    onSuggestionSelected: @escaping (S) -> Void
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
  @available(iOS 15.0, *)
  @ViewBuilder func iidadataSuggestions<S: Suggestion>(
    dadata: DadataSuggestions,
    input text: Binding<String>,
    suggestions: Binding<[S]?>,
    isPresented: Binding<Bool>,
    onSuggestionSelected: @escaping (S) -> Void
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

#if DEBUG

  // MARK: - ContentView

  /// A sample view demonstrating the usage of `IIDadataSuggestionsView`.
  @available(iOS 15.0, *)
  struct ContentView: View {
    // Properties

    // MARK: - IIDadataViewModel

    /// The view model for managing address and FIO suggestions.

    @State var address = "Грибал"
    @State var fio = "Михайл"
    @State var addressSuggestions: [AddressSuggestion]? = nil
    @State var fioSuggestions: [FioSuggestion]? = nil
    @State var error: String?
    @State var isFioSuggestionsPresented = true
    @State var isAddressSuggestionsPresented = true

    @StateObject private var dadata: DadataSuggestions = DadataSuggestions.sharedInstance.unsafelyUnwrapped

    // Lifecycle

    /// Initializes the `IIDadataViewModel` with the appropriate API key.
    ///
    /// The API key is fetched from the environment variables.
    init() {
      let apiKey = ProcessInfo.processInfo.environment["IIDadataAPIToken"] ?? ""
      DadataSuggestions.sharedInstance = DadataSuggestions(apiKey: apiKey)
    }

    // Content

    var body: some View {
      VStack(spacing: 16) {
        TextField(
          "Enter address",
          text: $address
        )
        .font(.body)
        .textFieldStyle(.roundedBorder)
        .tint(.blue).clipped()
        .iidadataSuggestions(
          dadata: dadata,
          input: $address,
          suggestions: $addressSuggestions,
          isPresented: $isAddressSuggestionsPresented,
          onSuggestionSelected: { address = $0.value }
        )

        TextField(
          "Enter Full Name",
          text: $fio
        )
        .font(.body)
        .textFieldStyle(.roundedBorder)
        .tint(.blue)
        .iidadataSuggestions(
          dadata: dadata,
          input: $fio,
          suggestions: $fioSuggestions,
          isPresented: $isFioSuggestionsPresented,
          onSuggestionSelected: { fio = $0.value }
        )
      }
      .padding()
    }
  }

  @available(iOS 15.0, *)
  struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
      ContentView()
    }
  }
#endif
