#if canImport(UIKit)
import SwiftUI
import API
import UI

/// Steps to add new icon
/// 1. Add iOS icon asset to `Assets/AppIcon` in format `Name` (App Icon) and `NameThumb` (Image Set)
/// 2. Add `Name` to `available` array
///
/// Why two copies of image? In production build Xcode cloud removes or renames original app icon's, so we need additional thumbnail image
struct SettingsAppIcon: View {
    static let supported = UIApplication.shared.supportsAlternateIcons
    
    private static let primary = "AppIcon"
    private static let available = [nil, "Flow", "Holo", "Blue", "Black", "Zen", "Pinky"]
    @State private var selection = UIApplication.shared.alternateIconName
    
    @MainActor
    private func update() async {
        guard Self.supported else { return }
        guard selection != UIApplication.shared.alternateIconName else { return }
        try? await UIApplication.shared.setAlternateIconName(selection)
    }
    
    var body: some View {
        List {
            Picker(selection: $selection) {
                ForEach(Self.available, id: \.self) { name in
                    HStack(spacing: 16) {
                        if let uiImage = UIImage(named: "\(name ?? Self.primary)Thumb") {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .strokeBorder(.primary.opacity(0.2), lineWidth: 0.5)
                                )
                        }
                        
                        Text(name ?? "Default")
                    }
                    .padding(.vertical, 4)
                    .tag(name)
                }
            } label: {}
                .pickerStyle(.inline)
                .task(id: selection) { await update() }
                .listSectionSeparator(.hidden)
        }
            .listStyle(.plain)
            .navigationBarTitle("App Icon")
    }
}
#endif
