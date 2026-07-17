import SwiftUI

public struct URLField {
    @State private var temp = ""
    
    var title: String
    @Binding var value: URL?
    var prompt: Text?
    var axis: Axis?
    
    public init(_ title: String = "", value: Binding<URL>, prompt: Text? = nil, axis: Axis? = nil) {
        self.title = title
        self._value = .init(get: {
            value.wrappedValue
        }, set: {
            if let url = $0 {
                value.wrappedValue = url
            }
        })
        self.prompt = prompt
        self.axis = axis
    }
    
    public init(_ title: String = "", value: Binding<URL?>, prompt: Text? = nil, axis: Axis? = nil) {
        self.title = title
        self._value = value
        self.prompt = prompt
        self.axis = axis
    }
}

extension URLField {
    //typed input like "example.com" carries no scheme; give it https:// so the
    //rest of the app receives a real web url instead of a path-only one
    static func url(from string: String) -> URL? {
        guard let url = URL(string: string) else { return nil }
        guard url.scheme == nil else { return url }
        return URL(string: "https://" + string) ?? url
    }
}

extension URLField: View {
    public var body: some View {
        Group {
            if let axis {
                TextField(title, text: $temp, prompt: prompt, axis: axis)
            } else {
                TextField(title, text: $temp, prompt: prompt)
            }
        }
            //sync from value only on an external change, not an echo of typing
            //(else normalization rewrites the text under the caret)
            .task(id: value) {
                if Self.url(from: temp) != value {
                    temp = value?.absoluteString ?? ""
                }
            }
            //empty clears the value (optional binding); the non-optional init keeps the last valid URL
            .task(id: temp) {
                value = temp.isEmpty ? nil : Self.url(from: temp)
            }
            #if canImport(UIKit)
            .keyboardType(.URL)
            .textContentType(.URL)
            .textInputAutocapitalization(.never)
            #endif
            .disableAutocorrection(true)
    }
}
