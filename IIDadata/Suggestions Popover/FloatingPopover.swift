import SwiftUI

#if canImport(UIKit)
  /// A view modifier for displaying a floating popover over a given anchor view.
  ///
  /// This view modifier provides the ability to present a popover view as a floating overlay
  /// over an anchor view when the `isPresented` binding is `true`.
  ///
  /// - Parameters:
  ///   - isPresented: A binding that controls whether the popover should be presented.
  ///   - contentBlock: A closure returning the content of the popover, which conforms to the `View` protocol.
  ///
  /// This view modifier is designed to work as a part of a view hierarchy and should be applied to a view to enable popover presentation.
  ///
  /// For iOS 15 compatibility, it includes a workaround for the missing `@StateObject` property wrapper, which uses an internal `Root` to manage the anchor view.
  public struct FloatingPopover<Item, PopoverContent>: ViewModifier where Item: Identifiable, PopoverContent: View {
    // Workaround for missing @StateObject in iOS 15.
    private struct Parent {
      var anchorView = UIView()
    }

    /// A private struct that represents an internal anchor view.
    private struct InternalAnchorView: UIViewRepresentable {
      typealias UIViewType = UIView

      // Properties

      @State var uiView: UIView

      // Functions

      /// Creates and returns the view for the anchor.
      ///
      /// - Parameter context: The context of the UIViewRepresentable.
      /// - Returns: A UIView with a background color of white.
      func makeUIView(context _: Self.Context) -> Self.UIViewType {
        uiView.backgroundColor = UIColor.white
        return uiView
      }

      /// Updates the anchor view with the latest state.
      ///
      /// - Parameters:
      ///   - uiView: The UIView instance to be updated.
      ///   - context: The context of the UIViewRepresentable.
      func updateUIView(_ uiView: Self.UIViewType, context _: Self.Context) {
        self.uiView = uiView
      }
    }

    // Nested Types

    /// A nested class that represents a content view controller for the popover.
    private class ContentViewController<V>: UIHostingController<V>, UIPopoverPresentationControllerDelegate where V: View {
      // Properties

      @Binding var isPresented: Bool
      var size: CGSize = .init(width: 300, height: 400)

      // Lifecycle

      /// Initializes the view controller with a root view and binding to `isPresented`.
      ///
      /// - Parameters:
      ///   - rootView: The root view to be hosted.
      ///   - isPresented: A binding that indicates whether the popover is presented.
      init(rootView: V, isPresented: Binding<Bool>) {
        _isPresented = isPresented
        super.init(rootView: rootView)
      }

      @available(*, unavailable)
      @MainActor @objc dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
      }

      // Overridden Functions

      /// Called after the controller's view is loaded into memory. Sets the view's background color and preferred content size.
      override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        size = sizeThatFits(in: UIView.layoutFittingExpandedSize)
        preferredContentSize = size
      }

      // Functions

      /// Specifies the presentation style for the view controller.
      ///
      /// - Parameters:
      ///   - controller: The presentation controller.
      ///   - traitCollection: The trait collection of the interface environment.
      /// - Returns: The modal presentation style, which is `.popover` for this implementation.
      func adaptivePresentationStyle(for _: UIPresentationController, traitCollection _: UITraitCollection) -> UIModalPresentationStyle {
        return .popover
      }

      /// Notifies that the popover presentation controller was dismissed.
      ///
      /// - Parameter controller: The presentation controller that was dismissed.
      func presentationControllerDidDismiss(_: UIPresentationController) {
        $isPresented.animation(.bouncy).wrappedValue = false
      }
    }

    // Properties

    /// A binding that controls whether the popover should be presented.
    @Binding var item: Item?
    /// A closure returning the content of the popover.
    @State var contentBlock: ((Item) -> PopoverContent)?
    /// A closure returning the content of the popover.
    @State var contentOptional: (() -> PopoverContent)?

    /// A private property that represents the anchor view.
    @State private var perent = Parent()

    // Lifecycle

    /// Initializes the FloatingPopover with a binding to an item and a content block.
    ///
    /// - Parameters:
    ///   - item: A binding to the item that controls the presentation of the popover.
    ///   - contentBlock: A closure that returns the content of the popover based on the item.
    init(
      item: Binding<Item?>,
      @ViewBuilder contentBlock: @escaping (Item) -> PopoverContent
    ) {
      _item = item
      self.contentBlock = contentBlock
      contentOptional = nil
    }

    /// Initializes the FloatingPopover with a boolean binding and a content block.
    ///
    /// - Parameters:
    ///   - isPresented: A binding that indicates whether the popover should be presented.
    ///   - contentBlock: A closure that returns the content of the popover.
    init(
      isPresented: Binding<Bool>,
      @ViewBuilder contentBlock: @escaping () -> PopoverContent
    ) where Item == Bool {
      _item = .init(get: {
        let bool: Bool? = isPresented.wrappedValue
        return bool
      }, set: {
        guard let _ = $0 else { isPresented.wrappedValue = false; return }
        isPresented.wrappedValue = true
      })
      contentOptional = contentBlock
    }

    // Content

    /// Modifies the content view by adding popover presentation logic.
    ///
    /// If `isPresented` is `true`, this modifier presents the popover containing the provided content.
    ///
    /// - Parameter content: The content view to be modified.
    /// - Returns: A view with popover presentation capabilities.
    public func body(content: Content) -> some View {
      if let item = item {
        withAnimation(.bouncy) {
          presentPopover(with: item)
        }
      }
      return Button(action: {
        withAnimation(.bouncy) {
          if let item = item {
            withAnimation(.bouncy) {
              presentPopover(with: item)
            }
          }
        }
      }, label: {
        content
          .background(InternalAnchorView(uiView: perent.anchorView).background(Color.black))
      })
    }

    // Functions

    /// Presents the popover with the provided item.
    ///
    /// - Parameter item: The item that triggers the popover presentation.
    /// - Returns: The presented popover view controller.
    /// - Note: This function is called by the `body` modifier and should not be called directly.
    private func presentPopover(with item: Item) {
      var contentController: ContentViewController<PopoverContent>
      if let contentBlock = contentBlock {
        contentController = ContentViewController(
          rootView: contentBlock(item),
          isPresented: .init(get: {
            $item.wrappedValue != nil
          }, set: { newState in
            self.item = newState ? $item.wrappedValue : nil
          })
        )
      } else {
        guard let contentOptional = contentOptional else { return }
        contentController = ContentViewController(
          rootView: contentOptional(),
          isPresented: .init(get: {
            $item.wrappedValue != nil
          }, set: { newState in
            self.item = newState ? $item.wrappedValue : nil
          })
        )
      }
      contentController.modalPresentationStyle = .popover
      let view = perent.anchorView
      view.backgroundColor = .black
      guard let popover = contentController.popoverPresentationController else { return }
      popover.sourceView = view
      popover.sourceRect = view.bounds
      popover.delegate = contentController
      popover.backgroundColor = UIColor.black
      guard let sourceVC = view.closestVC() else { return }
      if let presentedVC = sourceVC.presentedViewController {
        presentedVC.dismiss(animated: true) {
          sourceVC.present(contentController, animated: true)
        }
      } else {
        sourceVC.present(contentController, animated: true)
      }
    }
  }

  extension Bool: @retroactive Identifiable { public var id: Bool { self } }

  public extension UIView {
    func closestVC() -> UIViewController? {
      var responder: UIResponder? = self
      while responder != nil {
        if let vc = responder as? UIViewController {
          return vc
        }
        responder = responder?.next
      }
      return nil
    }
  }

  public extension View {
    /**
     Adds a floating popover to the current view that is presented when the given identifiable item is non-nil.

     - Parameters:
     - item: A binding to an optional identifiable item that controls the presentation of the popover. When the item becomes non-nil, the popover is presented.
     - content: A view builder that creates the content of the popover using the provided item.

     - Returns: A view that conditionally presents a popover when the item is non-nil. On iOS 16.4 and later, it uses the native `popover` modifier with a fixed size. For earlier OS, it applies a custom `FloatingPopover` modifier.

     - Note: On iOS 16.4 and later, the popover is presented using the native popover modifier with a fixed size and `.popover` adaptation. On earlier versions, a custom `FloatingPopover` modifier is used.
     */
    @ViewBuilder
    func floatingPopover<Item: Identifiable>(
      item: Binding<Item?>,
      @ViewBuilder content: @escaping (Item) -> some View
    ) -> some View {
//      if #available(iOS 16.4, *) {
//        popover(item: item) { item in
//          content(item)
//            .presentationCompactAdaptation(.popover)
//            .fixedSize()
//        }
//      } else {
      modifier(FloatingPopover(item: item, contentBlock: content))
//      }
    }

    /**
     Adds a floating popover to the current view that is presented when the given boolean binding is true.

     - Parameters:
     - isPresented: A binding to a boolean value that controls the presentation of the popover. When the value becomes true, the popover is presented.
     - content: A view builder that creates the content of the popover.

     - Returns: A view that conditionally presents a popover when the boolean value is true. On iOS 16.4 and later, it uses the native `popover` modifier with a fixed size. For earlier OS, it applies a custom `FloatingPopover` modifier.

     - Note: On iOS 16.4 and later, the popover is presented using the native popover modifier with a fixed size and `.popover` adaptation. On earlier versions, a custom `FloatingPopover` modifier is used.
     */
    @ViewBuilder
    func floatingPopover(
      isPresented: Binding<Bool>,
      @ViewBuilder content: @escaping () -> some View
    ) -> some View {
      if #available(iOS 16.4, *) {
        popover(isPresented: isPresented) {
          content()
            .presentationCompactAdaptation(.popover)
            .fixedSize()
        }
      } else {
        modifier(FloatingPopover(isPresented: isPresented, contentBlock: content))
      }
    }
  }
#endif
