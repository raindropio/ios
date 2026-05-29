import SwiftUI
import Backport

#if canImport(UIKit)
class KeyboardButtons: UIInputView {
    private let hosting: UIHostingController<Hosting>

    init(_ items: [String], onPress: @escaping (String) -> Void) {
        //init
        self.hosting = .init(rootView: .init(items: items, onPress: onPress))
        super.init(frame: .init(x: 0, y: 0, width: 100, height: 45.0), inputViewStyle: .keyboard)

        //subview
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hosting.view)

        //constraints — pin all edges
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func update(_ items: [String]) {
        if hosting.rootView.items != items {
            hosting.rootView = .init(items: items, onPress: hosting.rootView.onPress)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension KeyboardButtons {
    private struct Hosting: View {
        #if os(iOS)
        @Environment(\.hapticFeedback) private var hapticFeedback
        #endif
        @Environment(\.horizontalSizeClass) private var sizeClass
        
        var items: [String] = []
        var onPress: (String) -> Void
                
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(items, id: \.self) { item in
                        if !item.isEmpty {
                            if item != items.first {
                                Circle().fill(.secondary).frame(width: 6, height: 6).padding(4)
                            }

                            Button(item) {
                                onPress(item)
                                #if os(iOS)
                                hapticFeedback(.rigid)
                                #endif
                            }
                        }
                    }
                }
                    .padding(.top, 5)
            }
                .buttonStyle(KeyboardButtonStyle())
                .safeAnimation(.spring(), value: items.count)
                .scrollBounceBehavior(.basedOnSize, axes: [.horizontal, .vertical])
                .backport.glassEffect()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
    }
}

fileprivate struct KeyboardButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 15)
            .frame(maxHeight: .infinity)
            .foregroundColor(.primary)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(configuration.isPressed ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.clear))
                    .safeAnimation(nil, value: configuration.isPressed)
            )
            .transition(.scale(scale: 0).combined(with: .opacity))
    }
}
#endif
