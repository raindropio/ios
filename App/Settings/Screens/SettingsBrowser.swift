import SwiftUI
import API
import UI

struct SettingsBrowser: View {
    @AppStorage(PreferredBrowser.key) private var browser: PreferredBrowser = .default
    @AppStorage(UniversalLinks.key) private var universalLinks: UniversalLinks = .default

    var body: some View {
        Form {
            Picker("Open links in", selection: $browser) {
                ForEach(PreferredBrowser.allCases, id: \.self) { option in
                    Label {
                        Text(option.title)
                        Text(option.description)
                    } icon: {
                        Image(systemName: option.systemImage)
                    }
                }
            }
                .pickerStyle(.inline)
            
            if browser != .system {
                Section {
                    Toggle(
                        "Universal links",
                        isOn: .init(
                            get: {universalLinks == .enabled},
                            set: {universalLinks = $0 ? .enabled : .disabled}
                        )
                    )
                } footer: {
                    Text("Enabling Universal Links will open some URLs in specific apps installed on your device. For example, an Instagram URL will open up in the Instagram app and take you directly to the specific post.")
                }
            }
        }
            .navigationTitle("Browser")
    }
}
