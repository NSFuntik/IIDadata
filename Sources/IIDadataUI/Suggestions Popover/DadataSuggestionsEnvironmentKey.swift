//
//  DadataSuggestionsKey.swift
//  IIDadata
//
//  Created by NSFuntik on 13.08.2024.
//
import IIDadata
import SwiftUI

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
	@available(iOS 15.0, *) @ViewBuilder
	func withDadataSuggestions<S: Suggestion>(
    isPresented: Binding<Bool> = .constant(true),
		apiKey: String,
		input text: Binding<String>,
		suggestions: Binding<[S]?>,
		textfieldHeight: CGFloat,
		onSuggestionSelected: @escaping (S) -> Void
	) -> some View {
		 modifier(
			IIDadataSuggestsPopover(
				apiKey: apiKey,
				input: text,
				suggestions: suggestions,
				textfieldHeight: textfieldHeight,
				onSuggestionSelected: onSuggestionSelected
			)
		).environment(\.dadataSuggestions, try? DadataSuggestions.shared(apiKey: apiKey))
	}

	/// A view modifier to display suggestions for the given input using `Dadata`  API.
	///
	/// This extension provides an easy way to apply the `IIDadataSuggestsPopover` view modifier to any `View`.
	///
	/// - Parameters:
	///   - apiKey: The API key for the `Dadata` API.
	///   - text: A binding to the input text.
	///   - suggestions: A binding to the list of suggestions.
	///   - textfieldHeight: The height of the text field.
	///   - onSuggestionSelected: A closure to handle the selection of a suggestion.
	///
	/// - Returns: A view with the `IIDadataSuggestsPopover` modifier applied.
	@available(iOS 15.0, *) @ViewBuilder
	func withDadataSuggestions<S: Suggestion>(
    isPresented: Binding<Bool> = .constant(true),
		dadata: DadataSuggestions,
		input text: Binding<String>,
		suggestions: Binding<[S]?>,
		textfieldHeight: CGFloat,
		onSuggestionSelected: @escaping (S) -> Void
	) -> some View {
		modifier(
			IIDadataSuggestsPopover(
				input: text,
				suggestions: suggestions,
				textfieldHeight: textfieldHeight,
				onSuggestionSelected: onSuggestionSelected
			)
		).environment(\.dadataSuggestions, dadata)
	}
}

extension EnvironmentValues {
	/// The current `DadataSuggestions` instance.
	@available(iOS 15.0, *)
	var dadataSuggestions: DadataSuggestions? {
		get { self[DadataSuggestionsKey.self] }
		set { self[DadataSuggestionsKey.self] = newValue }
	}
}

// MARK: - DadataSuggestionsKey

/// An environment key that provides access to the current `DadataSuggestions` instance.
struct DadataSuggestionsKey: EnvironmentKey {
	static let defaultValue: DadataSuggestions? = nil
}
