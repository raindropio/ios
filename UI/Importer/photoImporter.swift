import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

public extension View {
    func photoImporter(isPresented: Binding<Bool>, onCompletion: @escaping ([NSItemProvider]) -> Void) -> some View {
        modifier(PI(isPresented: isPresented, onCompletion: onCompletion))
    }
}

fileprivate struct PI: ViewModifier {
    @Binding var isPresented: Bool
    var onCompletion: ([NSItemProvider]) -> Void

    @State private var picked = [NSItemProvider]()

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, onDismiss: deliver) {
                PlatformPhotoPicker {
                    picked = $0
                    isPresented = false
                }
            }
    }

    //deliver only after the sheet is fully gone: the receiver presents its own
    //sheet right away, and presenting while this one is still dismissing wedges
    //presentation for the whole window (every later sheet silently fails)
    private func deliver() {
        guard !picked.isEmpty else { return }
        onCompletion(picked)
        picked = []
    }
}

fileprivate struct PlatformPhotoPicker {
    var filter: PHPickerFilter?
    var onCompletion: ([NSItemProvider]) -> Void
    
    func makeViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = filter
        configuration.selectionLimit = 999
        
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateViewController(_ picker: PHPickerViewController, context: Context) {
        context.coordinator.update(self)
    }
}

#if canImport(AppKit)
extension PlatformPhotoPicker: NSViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        .init(self)
    }
    
    func makeNSViewController(context: Context) -> PHPickerViewController {
        makeViewController(context: context)
    }
    
    func updateNSViewController(_ picker: PHPickerViewController, context: Context) {
        updateViewController(picker, context: context)
    }
}
#else
extension PlatformPhotoPicker: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        .init(self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        makeViewController(context: context)
    }
    
    func updateUIViewController(_ picker: PHPickerViewController, context: Context) {
        updateViewController(picker, context: context)
    }
}
#endif

extension PlatformPhotoPicker {
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private var base: PlatformPhotoPicker
        
        init(_ base: PlatformPhotoPicker) {
            self.base = base
        }
        
        func update(_ base: PlatformPhotoPicker) {
            self.base = base
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            //no picker.dismiss here: the sheet is SwiftUI-presented, dismissing
            //its hosted controller through UIKit desyncs the sheet binding
            base.onCompletion(results.map { $0.itemProvider })
        }
    }
}
