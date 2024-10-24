//
//  ContentView.swift
//  IIDadata
//
//  Created by NSFuntik on 11.08.2024.
//

import IIDadata
import IIDadataUI
import SwiftUI

// MARK: - IIDadataDemo

@available(iOS 15.0, *)
struct IIDadataDemo: View {
  // Properties

  @State var text = "Миха"
  @State var suggestions: [FioSuggestion]? {
    willSet {
      debugPrint(suggestions ?? [], separator: "\n ● ")
    }
  }
  @State var isPresented = false
  let apiKey: String //  = ProcessInfo.processInfo.environment["IIDadataAPIToken"]

  // Lifecycle

  init() {
    apiKey = ProcessInfo.processInfo.environment["IIDadataAPIToken"] ?? ""

    _suggestions = State(initialValue: [])
  }

  // Content

  var body: some View {
    TextField("ФИО", text: $text, prompt: Text("ФИО"))
      .textFieldStyle(RoundedBorderTextFieldStyle())
      .padding()
      .font(.body)
      .withDadataSuggestions(
        apiKey: apiKey,
        input: $text,
        suggestions: $suggestions,
				textfieldHeight: 44		
      ) { s in
        debugPrint(s)
        text = s.value
        if suggestions?.count == 1 {
          isPresented = false
        }
      }
  }
}

// MARK: - PreviewProvider
@available(iOS 15.0, *)
struct IIDadataDemo_Previews: PreviewProvider {
  static var previews: some View {
    IIDadataDemo()
  }
}
