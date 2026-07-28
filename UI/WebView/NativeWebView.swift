import WebKit
import Combine

class NativeWebView: WKWebView {
    private var cancelables = Set<AnyCancellable>()

    #if canImport(UIKit)
    //extra items for text selection edit menu
    var editMenu: (() -> [UIMenuElement])?

    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)

        guard builder.system == .context, let items = editMenu?(), !items.isEmpty else { return }

        let menu = UIMenu(options: .displayInline, children: items)
        if builder.menu(for: .standardEdit) != nil {
            builder.insertSibling(menu, afterMenu: .standardEdit)
        } else {
            builder.insertChild(menu, atEndOfMenu: .root)
        }
    }
    #endif

    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        //init
        super.init(frame: frame, configuration: configuration)
        
        //pull to refresh
        #if canImport(UIKit)
        scrollView.refreshControl = .init()
        scrollView.refreshControl?.addTarget(self, action: #selector(self.reload), for: .valueChanged)
        
        //fix refresh control color-scheme
        publisher(for: \.underPageBackgroundColor)
            .sink { [weak self] in self?.scrollView.refreshControl?.overrideUserInterfaceStyle = ($0?.isLight ?? true) ? .light : .dark }
            .store(in: &cancelables)
        #endif
        
//        scrollView.contentInsetAdjustmentBehavior = .never
//        scrollView.automaticallyAdjustsScrollIndicatorInsets = false
//        scrollView.contentInset = .init(top: 0, left: 0, bottom: 0, right: 0)
//        scrollView.scrollIndicatorInsets = .init(top: 128, left: 0, bottom: 0, right: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        cancelables.forEach { $0.cancel() }
    }
}
