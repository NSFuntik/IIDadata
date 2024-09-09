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

  /// The DadataSuggestions instance for fetching suggestions.
  @Environment(\.dadataSuggestions) private var dadata

  // Properties

  /// The action to perform when a suggestion is selected.
  public var onSuggestionSelected: OnSuggestionSelected

  /// The TextField input text.
  @Binding var text: String
  /// The list of suggestions.
  @Binding var suggestions: [S]?

  let textfieldHeight: CGFloat

  /// A binding to a boolean value that indicates whether the popover is presented.
  @Binding var isPopoverPresented: Bool

  private let viewID = UUID().uuidString

  /// The error message.
  @State private var error: String? = nil

  @Namespace private var nsPopover

  @FocusState private var isFocused: Bool

  // Computed Properties

  var idealHeight: CGFloat {
    let suggestions = Double(self.suggestions?.endIndex ?? 1)
    return textfieldHeight
      + (UIFont.preferredFont(forTextStyle: .callout).lineHeight.scaled(by: suggestions))
  }

  var maxHeight: CGFloat {
    idealHeight + 111
  }

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
    isPresented: Binding<Bool> = .constant(true),
    input text: Binding<String>,
    suggestions: Binding<[S]?>,
    textfieldHeight: CGFloat,
    onSuggestionSelected: @escaping (S) -> Void
  ) where S: Suggestion {
    _isPopoverPresented = isPresented
    _text = text
    _suggestions = suggestions
    self.textfieldHeight = textfieldHeight
    self.onSuggestionSelected = onSuggestionSelected
    guard (try? DadataSuggestions.shared()) != nil else {
      debugPrint("DaData service shared instanvce didn't configurated properly")
      return
    }
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
    isPresented: Binding<Bool> = .constant(true),
    apiKey _: String,
    input text: Binding<String>,
    suggestions: Binding<[S]?>,
    textfieldHeight: CGFloat,
    onSuggestionSelected: @escaping (S) -> Void
  ) where S: Suggestion {
    _isPopoverPresented = isPresented
    _text = text
    _suggestions = suggestions
    self.textfieldHeight = textfieldHeight + 6
    self.onSuggestionSelected = onSuggestionSelected
  }

  // Content

  @ViewBuilder
  public func body(content: Content) -> some View {
    content
      .coordinateSpace(name: nsPopover)
      .autocorrectionDisabled()
      .textInputAutocapitalization(.never)
      .layoutPriority(1)
      .zIndex(1)
      .compositingGroup()
      .padding(.bottom, isPopoverPresented && !(suggestions?.isEmpty ?? true) ? idealHeight : 0)
      .background {
        Color.clear
          .matchedGeometryEffect(
            id: viewID, in: nsPopover, properties: .frame, anchor: .top, isSource: true
          )
          .offset(x: 0, y: textfieldHeight / 2)
          .frame(height: idealHeight)
      }
      .overlay(alignment: .top) {
        if isPopoverPresented {
          popover().compositingGroup().matchedGeometryEffect(
            id: viewID, in: nsPopover, properties: .frame, anchor: .top, isSource: false
          )
          .fixedSize()
          .layoutPriority(1)
          .zIndex(1)
          .transaction { view in
            view.animation = .interactiveSpring
            view.isContinuous = true
            view.disablesAnimations = true
          }
          .opacity(suggestions?.isEmpty == true ? 0 : 1)
        }
      }
      .onChange(of: text, perform: getSuggestions(for:))
      .task(id: text) {
        isPopoverPresented = true
        getSuggestions(for: text)
      }
      .focused($isFocused).animation(.interactiveSpring, value: isFocused)
      .onChange(of: isFocused) { isPopoverPresented = $0 }
      .animation(.spring, value: isPopoverPresented)
      .animation(.smooth, value: suggestions)
  }

  @ViewBuilder
  func popover() -> some View {
    if isPopoverPresented, let suggestions = suggestions?.compactMap(\.self), !suggestions.isEmpty {
      SuggestionsPopover(for: text, with: suggestions, height: textfieldHeight) { suggestion in
        text = suggestion.value
        onSuggestionSelected(suggestion)

        isPopoverPresented = suggestions.count != 1
      }
      .background(.bar, in: .rect(cornerRadius: 10))
      .frame(
        minHeight: suggestions.endIndex > 1 ? 111 : 0,
        idealHeight: idealHeight,
        maxHeight: maxHeight,
        alignment: .bottom
      )
      .tag(viewID, includeOptional: false)
      .fixedSize().edgesIgnoringSafeArea(.all).ignoresSafeArea(.all)
      .transition(.offset(x: 0, y: -idealHeight).animation(.spring))
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

    guard !input.isEmpty else {
      error = "Error fetching suggestions: \(IIDadataError.invalidInput)"
      return
    }

    do {
      switch S.self {
      case is AddressSuggestion.Type:
        debugPrint("AddressSuggestion – Fetching address suggestions for: \(input)")

        let addressSuggestions = try await getAddressSuggestions(for: input) as! [S]
        suggestions = addressSuggestions

      case is FioSuggestion.Type:
        debugPrint("FioSuggestion – Fetching Fio suggestions for: \(input)")

        let fioSuggestions = try await getFioSuggestions() as! [S]
        suggestions = fioSuggestions

      default:
        debugPrint("Unknown Suggestion – Fetching suggestions for: \(input)")
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
  func getFioSuggestions() async throws(IIDadata.IIDadataError)
    -> [FioSuggestion] /* where S == IIDadata.FioSuggestion */
  {
    guard !text.isEmpty else {
      suggestions = nil
      throw IIDadataError.invalidInput
    }
    do {
      let suggestions = try await DadataSuggestions.shared().suggestFio(
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
  func getAddressSuggestions(for text: String) async throws(IIDadata.IIDadataError)
    -> [AddressSuggestion]
  {
    guard !text.isEmpty else {
      suggestions = nil
      throw IIDadataError.invalidInput
    }
    do {
      guard
        let suggestions = try await DadataSuggestions.shared().suggestAddress(
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

// MARK: - Previews

#if DEBUG

  // MARK: - ContentView

  /// A sample view demonstrating the usage of `IIDadataSuggestionsView`.
  @available(iOS 15.0, *)
  struct ContentView: View {
    // Static Computed Properties

    static var addressMock: AddressSuggestion {
      .init(
        value: "г. Санкт-Петербург, улица Грибалёвой, 7 к4 с1, кв. \(Int.random(in: 1 ... 333))",
        data: .init(),
        unrestrictedValue:
        "г. Санкт-Петербург, улица Грибалёвой, 7 к4 с1, кв. \(Int.random(in: 1 ... 333))"
      )
    }

    // Properties

    @State var address = "Грибал"
    @State var fio = "Михайл"
    @State var addressSuggestions: [AddressSuggestion]? = [
      addressMock, addressMock, addressMock, addressMock, addressMock, addressMock,
    ]
    @State var fioSuggestions: [FioSuggestion]? = nil
    @State var error: String?

    @StateObject private var dadata: DadataSuggestions

    @FocusState private var isAddressFocused: Bool
    @FocusState private var isFIOFocused: Bool

    @State private var isAddressSuggestionsPresented = true
    @State private var isFIOSuggestionsPresented = true

    // Lifecycle

    /// Initializes the `IIDadataViewModel` with the appropriate API key.
    ///
    /// The API key is fetched from the environment variables.
    init() {
      let apiKey = ProcessInfo.processInfo.environment["IIDadataAPIkey"] ?? ""
      _dadata = StateObject(wrappedValue: try! DadataSuggestions.shared(apiKey: apiKey))
    }

    // Content

    var body: some View {
      ScrollView {
        VStack(spacing: 44) {
          Spacer()
          TextField(
            "Enter address",
            text: $address
          )

          .font(.body)
          .textFieldStyle(.roundedBorder)
          .tint(.blue).frame(height: 44)
          
          .withDadataSuggestions(
            isPresented: .constant(true),
            dadata: dadata,
            input: $address,
            suggestions: $addressSuggestions,
            textfieldHeight: 44,
            onSuggestionSelected: {
              address = $0.value
              if let index = addressSuggestions?.firstIndex(where: { $0.value == address }) {
                addressSuggestions?.remove(at: index)
              } else {
                addressSuggestions = nil
              }
            }
          )
          Spacer()
          TextField(
            "Enter Full Name",
            text: $fio
          )
          .font(.body)
          .textFieldStyle(.roundedBorder)
          .tint(.blue).background(.white).frame(height: 56).clipped()
          
          .withDadataSuggestions(
            isPresented: .constant(true),
            dadata: dadata,
            input: $fio,
            suggestions: $fioSuggestions,
            textfieldHeight: 56,
            onSuggestionSelected: {
              fio = $0.value.appending(" ")
            }
          )

          Spacer()
        }
        .padding()
      }
      .onAppear {
        
        dump(dadata)
      }
      .background(
        .conicGradient(
          colors: [Color.pink, .accentColor, .teal, .purple, .brown, .mint, .indigo],
          center: .center, angle: .degrees(.pi)
        )
      )
      .ignoresSafeArea()
    }
  }

  @available(iOS 15.0, *)
  struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
      ContentView()
    }
  }

#endif
