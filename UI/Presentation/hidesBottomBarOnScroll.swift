import SwiftUI
import Combine

#if canImport(UIKit)
public extension View {
    func hidesBottomBarOnScroll(enabled: Bool = true) -> some View {
        modifier(HidesBottomBarOnScroll(enabled: enabled))
    }
}

fileprivate struct HidesBottomBarOnScroll: ViewModifier {
    @State private var hidden = false

    var enabled: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if enabled {
                    ScrollObserver(hidden: $hidden).opacity(0)
                }
            }
            .toolbar(enabled && hidden ? .hidden : .automatic, for: .bottomBar)
            .animation(.default, value: enabled && hidden)
    }
}

fileprivate struct ScrollObserver: UIViewControllerRepresentable {
    @Binding var hidden: Bool

    func makeUIViewController(context: Context) -> VC {
        .init()
    }

    func updateUIViewController(_ controller: VC, context: Context) {
        controller.onChange = { hidden = $0 }
    }
}

extension ScrollObserver {
    class VC: UIViewController {
        var onChange: ((Bool) -> Void)?
        private weak var scrollView: UIScrollView?
        private var cancellable: AnyCancellable?
        private var anchor: CGFloat = 0

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)

            guard let found = findScrollView(), found !== scrollView else { return }
            scrollView = found
            anchor = found.contentOffset.y
            cancellable = found.publisher(for: \.contentOffset)
                .sink { [weak self] _ in self?.scrolled() }
        }

        private func findScrollView() -> UIScrollView? {
            guard let root = parent?.view else { return nil }
            var queue = [root]
            while !queue.isEmpty {
                let view = queue.removeFirst()
                if let scrollView = view as? UIScrollView { return scrollView }
                queue += view.subviews
            }
            return nil
        }

        private func scrolled() {
            guard let scrollView else { return }
            //ignores bottom inset, it changes when the bar hides
            let y = min(scrollView.contentOffset.y, scrollView.contentSize.height - scrollView.bounds.height)

            if y + scrollView.adjustedContentInset.top <= 0 {
                anchor = y
                onChange?(false)
            } else if !scrollView.isDragging {
                anchor = y
            } else if abs(y - anchor) >= 20 {
                onChange?(y > anchor)
                anchor = y
            }
        }
    }
}
#endif