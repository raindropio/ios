#if canImport(UIKit)
import SwiftUI
import API
import UI
import Features

extension SettingsIOS {
    struct Sidebar: View {
        @EnvironmentObject private var dispatch: Dispatcher
        @EnvironmentObject private var s: SubscriptionStore
        @Environment(\.dismiss) private var dismiss
        @AppStorage(PreferredBrowser.key) private var browser: PreferredBrowser = .default

        var body: some View {
            List {
                Group {
                    Section {
                        NavigationLink(value: SettingsPath.Screen.account) {
                            MeLabel()
                        }
                        
                        NavigationLink(value: SettingsPath.Screen.subscription) {
                            Label("Subscription", systemImage: "bolt")
                                .badge(s.state.current?.plan.title ?? "Free")
                                .tint(.primary)
                        }
                            .listItemTint(.red)
                            .reload {
                                try? await dispatch(SubscriptionAction.load)
                            }
                    }
                    
                    Section {
                        NavigationLink(value: SettingsPath.Screen.extensions) {
                            Label("Extensions", systemImage: "puzzlepiece.extension").tint(.primary)
                        }
                            .listItemTint(.purple)
                        
                        #if os(iOS)
                        NavigationLink(value: SettingsPath.Screen.appIcon) {
                            Label("App Icon", systemImage: "square.on.circle").tint(.primary)
                        }
                            .listItemTint(.indigo)
                        #endif
                        
                        NavigationLink(value: SettingsPath.Screen.browser) {
                            Label("Browser", systemImage: "safari").tint(.primary)
                                .badge(browser.title)
                        }
                            .listItemTint(.cyan)

                        Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                            Label("Language", systemImage: "globe").tint(.primary)
                        }
                            .listItemTint(.green)
                    }
                    
                    Section {
                        Link(destination: URL(string: "https://ifttt.com/raindrop")!) {
                            Label("Integrations", systemImage: "puzzlepiece.extension").badge("+2,000").tint(.primary)
                        }
                        
                        NavigationLink(value: SettingsPath.Screen.import) {
                            Label("Import", systemImage: "square.and.arrow.down").tint(.primary)
                        }
                        
                        NavigationLink(value: SettingsPath.Screen.backups) {
                            Label("Backups", systemImage: "clock.arrow.circlepath").tint(.primary)
                        }
                        
//                        SafariLink(destination: URL(string: "https://raindrop.io/download")!) {
//                            Label("Desktop app", systemImage: "desktopcomputer").tint(.primary)
//                        }
                        
                        SafariLink(destination: URL(string: "https://help.raindrop.io/")!) {
                            Label("Help", systemImage: "questionmark.circle").tint(.primary)
                        }
                    } footer: {
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))")
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .scenePadding(.top)
                    }
                        .listItemTint(.monochrome)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .labelStyle(.sidebar)
            .toolbar {
                DoneToolbarItem()
            }
        }
    }
}
#endif
