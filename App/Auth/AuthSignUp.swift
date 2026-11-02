import SwiftUI
import API
import UI
import Backport

struct AuthSignup: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var dispatch: Dispatcher
    @State private var form = AuthSignupRequest()
    
    enum Focus: CaseIterable { case name, email, password }
    @FocusState private var focus: Focus?
    
    private func submit() async throws {
        if form.name.isEmpty {
            focus = .name
        } else if form.email.isEmpty {
            focus = .email
        } else if form.password.isEmpty {
            focus = .password
        } else if form.isValid {
            try await dispatch(AuthAction.signup(form))
        }
    }

    var body: some View {
        Form {
            Section {
                TextField("Username", text: $form.name)
                    #if canImport(UIKit)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .keyboardType(.asciiCapable)
                    .submitLabel(.next)
                    #endif
                    .backport.focused($focus, equals: .name)
                
                TextField("Email", text: $form.email)
                    #if canImport(UIKit)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .submitLabel(.next)
                    #endif
                    .backport.focused($focus, equals: .email)
                
                SecureField("Password", text: $form.password)
                    .submitLabel(.done)
                    .backport.focused($focus, equals: .password)
            } footer: {
                Text("By clicking **Sign up** above, you are agreeing to the [Terms of Service](https://help.raindrop.io/terms) and [Privacy Policy](https://help.raindrop.io/privacy)")
                    .openLinksInSafari()
                    .frame(maxHeight: .infinity)
            }
            
            SubmitButton("Sign up")
                .disabled(!form.isValid)
            
            AuthContinueWith()
        }
            .backport.defaultFocus($focus, .name)
            .onSubmit { try await submit() }
            #if canImport(UIKit)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Create an account")
            #else
            .formStyle(.columns)
            .textFieldStyle(.roundedBorder)
            .controlSize(.large)
            .scenePadding()
            #endif
            .toolbar {
                CancelToolbarItem()
            }
    }
}
