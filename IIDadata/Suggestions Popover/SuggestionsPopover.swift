//
//  SuggestionsPopover.swift
//  IIDadata
//
//  Created by NSFuntik on 13.08.2024.
//

import IIDadata
import SwiftUI

// MARK: - IIDadataSuggestsPopover.SuggestionsPopover

@available(iOS 15.0, *)
public extension IIDadataSuggestsPopover {
	// MARK: - SuggestionsPopover

	/// A view that displays a list of suggestions.
	///
	/// The `SuggestionsPopover` displays suggestions in a scrollable list and allows the user to select one.
	///
	/// - Parameters:
	///   - suggestions: An array of `Suggestion.Value` to be displayed.
	///   - height: The height of `TextField`'s container for offseting the `popover`.
	///   - inputText: `TextField's` input.
	///   - onSelect: A closure that gets executed when a suggestion is selected.
	/// - Returns: A `View` that displays a list of suggestions.
	@available(iOS 15.0, *)
	struct SuggestionsPopover<S: Suggestion>: View {
		// Properties

		var suggestions: [S]
		let onSelect: (S) -> Void
		let textfieldHeight: CGFloat
		@Namespace var nsNamespace
		let maxWidth: CGFloat = UIScreen.main.bounds.width - 44

		@State private var cachedInput: String = ""
		@State private var cachedResults: [AttributedString] = []
		private var inputText: String

		// Computed Properties

		/// The ideal height for the suggestions popover based on the number of suggestions.
		var idealHeight: CGFloat {
			let suggestions = self.suggestions.count
			return textfieldHeight + (44.0 * CGFloat(suggestions > 1 ? suggestions : 1))
		}

		/// The maximum height for the suggestions popover.
		var maxHeight: CGFloat {
			idealHeight + 111
		}

		/// An array of highlighted suggestions based on the input text.
		///
		/// This computed property caches the input text and its corresponding highlighted suggestions.
		/// If the input text has not changed, it returns the cached results. Otherwise, it updates the cache and returns new results.
		private var highlightedSuggestions: [AttributedString] {
			if inputText == cachedInput {
				return cachedResults
			}
			let newResults = suggestions.map { suggestion in
				highlight(text: suggestion.value, match: inputText)
			}
			cachedInput = inputText
			cachedResults = newResults
			return newResults
		}

		// Lifecycle

		/// Creates a new `SuggestionsPopover`.
		///
		/// - Parameters:
		///   - suggestions: An array of `Suggestion.Value` to be displayed.
		///   - height: The height of `TextField`'s container for offseting the `popover`.
		///   - inputText: `TextField's` input.
		///   - onSelect: A closure that gets executed when a suggestion is selected.
		init(
			for inputText: String,
			with suggestions: [S],
			height textfieldHeight: CGFloat,
			onSelect: @escaping (S) -> Void
		) {
			self.inputText = inputText
			self.suggestions = suggestions
			self.onSelect = onSelect
			self.textfieldHeight = textfieldHeight
			UITableView.appearance().backgroundColor = .clear
			UIScrollView.appearance().backgroundColor = .clear
		}

		// Content

		public var body: some View {
			ScrollView {
				LazyVStack(spacing: 6) {
					ForEach(suggestions, id: \.self, content: SelectedSuggestionView(_:))
				}
				.padding(8)
				.listStyle(.inset)
			}
			.frame(
				minWidth: 100,
				idealWidth: UIScreen.main.bounds.width - 32,
				maxWidth: UIScreen.main.bounds.width - 16,
				minHeight: suggestions.endIndex > 1 ? 111 : 0,
				idealHeight: idealHeight,
				maxHeight: maxHeight,
				alignment: .center
			).ignoresSafeArea(.all).edgesIgnoringSafeArea(.all)
			.animation(.interactiveSpring, value: suggestions)
		}

		@ViewBuilder
		func SelectedSuggestionView(_ suggestion: S) -> some View {
			VStack(alignment: .leading, spacing: 5) {
				ZStack(alignment: .leading, content: {
					Button(action: {
						onSelect(suggestion)
					}) {
						Text(highlight(text: suggestion.value, match: inputText))
							.font(
								.system(.callout, design: .rounded).weight(.light)
							)
							.lineLimit(1).allowsTightening(true)
							.truncationMode(.head)
							.foregroundStyle(.foreground)
							.frame(minWidth: 166, maxWidth: maxWidth, alignment: .leading)
					}
					.buttonStyle(.borderless)
				})
				.accentColor(.accentColor)
				Divider()
			}.clipped(antialiased: true)
		}

		// Functions

		/// Highlights the matching text within the provided text.
		///
		/// This function takes the input text and highlights the portion that matches the provided match string.
		/// The matching part of the text will have a different font weight.
		///
		/// - Parameters:
		///   - text: The text to be highlighted.
		///   - match: The string to match and highlight within the text.
		///
		/// - Returns: An `AttributedString` with the matched portion highlighted.
		private func highlight(text: String, match: String) -> AttributedString {
			var attributedString = AttributedString(text)
			if let stringRange = text.range(of: match, options: .caseInsensitive) {
				// Convert the String.Index range to an AttributedString.Index range
				if let range = Range(stringRange, in: attributedString) {
					attributedString[range].font = .callout.weight(.medium)
				}
			}
			return attributedString
		}
	}
}
