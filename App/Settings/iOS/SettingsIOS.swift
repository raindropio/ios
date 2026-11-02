#if canImport(UIKit)
import SwiftUI
import UI

struct SettingsIOS: View {
    @State private var stack: [SettingsPath.Screen]

    init(path: SettingsPath) {
        _stack = .init(initialValue: path.screen.map { [$0] } ?? [])
    }

    var body: some View {
        NavigationStack(path: $stack) {
            Sidebar()
                .navigationDestination(for: SettingsPath.Screen.self) { screen in
                    switch screen {
                    case .account:
                        SettingsAccount()
                    case .backups:
                        SettingsWebApp(subpage: .backups)
                    case .import:
                        SettingsWebApp(subpage: .import)
                    case .subscription:
                        SettingsSubscription()
                    case .appIcon:
                        SettingsAppIcon()
                    case .extensions:
                        SettingsExtensions()
                    case .browser:
                        SettingsBrowser()
                    }
                }
        }
    }
}
#endif
