import SwiftUI
import API
import UI
import Backport

struct AuthScreen: View {
    @EnvironmentObject private var dispatch: Dispatcher
    @State private var login = false
    @State private var signup = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AuthSplash()
                
                HStack(spacing: 16) {
                    Button { login = true } label: {
                        Text("Log In").padding(.horizontal).frame(height: 32)
                    }
                        .buttonStyle(Backport.glass)
                    
                    Button { signup = true } label: {
                        Text("Sign up").frame(maxWidth: .infinity).frame(height: 32)
                    }
                        .buttonStyle(Backport.glassProminent)
                }
                    .fontWeight(.medium)
                    #if canImport(UIKit)
                    .buttonBorderShape(.capsule)
                    #else
                    .controlSize(.large)
                    #endif
                    .scenePadding()
                    .scenePadding(.horizontal)
                    .frame(maxWidth: 500)
                
                Text("We keep your [data safe](https://help.raindrop.io/security), never sold.\nNo\u{00a0}limits. Starting from $0.")
                    .openLinksInSafari()
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .scenePadding(.horizontal)
            }
                .scenePadding(.vertical)
                .ignoresSafeArea(edges: .top)
                .navigationTitle("")
                .toolbarBackground(.clear, for: .automatic)
                .backport.toolbarBackgroundVisibility(.hidden, for: .automatic)
                .backport.scrollEdgeEffectStyle(.soft, for: .all)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Image("logo-text")
                    }
                    
                    ToolbarItem {
                        SafariLink(destination: URL(string: "https://help.raindrop.io/")!) {
                            Image(systemName: "questionmark.circle")
                                .imageScale(.large)
                        }
                            #if os(iOS)
                            .tint(.secondary)
                            #endif
                    }
                }
                .sheet(isPresented: $login) {
                    NavigationStack(root: AuthLogIn.init)
                        .modifier(AuthTFA())
                        .modifier(AuthSuccess())
                        .frame(idealWidth: 360)
                }
                .sheet(isPresented: $signup) {
                    NavigationStack(root: AuthSignup.init)
                        .modifier(AuthTFA())
                        .modifier(AuthSuccess())
                        .frame(idealWidth: 360)
                }
        }
    }
}
