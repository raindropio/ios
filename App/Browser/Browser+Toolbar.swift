import SwiftUI
import API
import UI
import Features
import Backport

extension Browser {
    struct Toolbar {
        @Environment(\.containerHorizontalSizeClass) private var horizontalSizeClass
        @Environment(\.verticalSizeClass) private var verticalSizeClass
        @EnvironmentObject private var dispatch: Dispatcher
        @EnvironmentObject private var cfg: ConfigStore
        @Environment(\.dismiss) private var dismiss
        @Environment(\.openURL) private var openURL
        @Environment(\.openDeepLink) private var openDeepLink
        @Environment(\.colorScheme) private var colorScheme
        @Environment(\.backportToolbarVerticalEdge) private var verticalEdge

        @State private var collection = false
        @State private var tags = false
        @State private var highlights = false
        @State private var form = false

        @ObservedObject var page: WebPage
        @Binding var raindrop: Raindrop
    }
}

extension Browser.Toolbar {
    private var portrait: Bool {
        verticalSizeClass == .regular && horizontalSizeClass == .compact
    }
            
    private var placement: ToolbarItemPlacement {
        #if canImport(UIKit)
        portrait ? .bottomBar : .automatic
        #else
        .automatic
        #endif
    }
}

extension Browser.Toolbar: ViewModifier {
    func body(content: Content) -> some View {
        content
        //overall
        .toolbarRole(.editor)
        #if canImport(UIKit)
        .backport.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)
        .hidesBottomBarOnScroll(enabled: horizontalSizeClass != .regular && verticalEdge == nil)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarBackground(raindrop.type.readable ? .clear : page.toolbarBackground ?? .clear, for: .bottomBar)
        .toolbarColorScheme(page.toolbarColorScheme == colorScheme ? nil : page.toolbarColorScheme, for: .navigationBar, .bottomBar)
        .backport.toolbarBackgroundVisibility(raindrop.type.readable ? .automatic : .visible, for: .navigationBar)
        .backport.toolbarBackgroundVisibility(raindrop.type.readable ? .automatic : .visible, for: .bottomBar)
        .overlay(alignment: .top) {
            if !raindrop.type.readable, let color = page.toolbarBackground {
                Color.clear
                    .frame(height: 0)
                    .background(color.ignoresSafeArea(edges: [.top, .horizontal]))
                    .allowsHitTesting(false)
            }
        }
        #endif
        //buttons
        .toolbar {
            //highlights
            ToolbarItem {
                Button { highlights.toggle() } label: {
                    Label(Filter.Kind.highlights.title, systemImage: Filter.Kind.highlights.systemImage)
                }
                .badge(raindrop.highlights.count)
                .sheet(isPresented: $highlights) {
                    RaindropStack($raindrop, content: RaindropHighlights.init)
                        .frame(idealWidth: 600, idealHeight: 600)
                        #if canImport(AppKit)
                        .fixedSize()
                        #endif
                }
            }
            .backport.visibilityPriority(.low)
            
            //share
            ToolbarItem {
                if raindrop.isNew, let url = page.url {
                    ShareLink(item: url)
                } else {
                    ShareRaindropLink(raindrop)
                        .equatable()
                }
            }
            .backport.visibilityPriority(.low)
            
            Group {
                if cfg.state.ai.assistant {
                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.flexible, placement: placement)
                    }

                    ToolbarItemGroup(placement: placement) {
                        Button("Ask", systemImage: "sparkle") {
                            openDeepLink?(.ask)
                        }
                            .tint(.pink)

                        if #unavailable(iOS 26.0) {
                            Spacer()
                        }
                    }
                }
                
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.flexible, placement: placement)
                }
                
                //move
                ToolbarItemGroup(placement: placement) {
                    Button { collection.toggle() } label: {
                        Label("Collection", systemImage: "folder")
                    }
                        .sheet(isPresented: $collection) {
                            RaindropStack($raindrop, content: RaindropCollection.init)
                                .frame(idealWidth: 600, idealHeight: 600)
                                #if canImport(AppKit)
                                .fixedSize()
                                #endif
                        }
                        .disabled(raindrop.isNew)
                    
                    if #unavailable(iOS 26.0) {
                        Spacer()
                    }
                }
                
                //add tags
                ToolbarItemGroup(placement: placement) {
                    Button { tags.toggle() } label: {
                        Label {
                            Text("Tags")
                        } icon: {
                            Image(systemName: "number")
                                .overlay(alignment: .topTrailing) {
                                    NumberInCircle(raindrop.tags.count)
                                        .offset(x: 11, y: -11)
                                }
                        }
                    }
                        .sheet(isPresented: $tags) {
                            RaindropStack($raindrop, content: RaindropTags.init)
                                .frame(idealWidth: 600, idealHeight: 600)
                                #if canImport(AppKit)
                                .fixedSize()
                                #endif
                        }
                        .disabled(raindrop.isNew)
                    
                    if #unavailable(iOS 26.0) {
                        Spacer()
                    }
                }
                
                //edit/add
                ToolbarItemGroup(placement: placement) {
                    Button { form.toggle() } label: {
                        Label(raindrop.isNew ? "Add" : "Edit", systemImage: raindrop.isNew ? "plus.circle" : "info.circle")
                    }
                        .sheet(isPresented: $form) {
                            RaindropStack($raindrop, content: RaindropForm.init)
                                #if canImport(AppKit)
                                .frame(idealWidth: 400)
                                .fixedSize()
                                #else
                                .frame(idealWidth: 600, idealHeight: 600)
                                #endif
                        }
                    
                    if #unavailable(iOS 26.0) {
                        Spacer()
                    }
                }
                .backport.visibilityPriority(.high)
                
                //delete
                ToolbarItemGroup(placement: placement) {
                    ActionButton {
                        try await dispatch(RaindropsAction.delete(raindrop.id))
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                        .disabled(raindrop.isNew)
                    
                    if #unavailable(iOS 26.0) {
                        Spacer()
                    }
                }
                
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.flexible, placement: placement)
                }
                
                //open
                ToolbarItemGroup(placement: placement) {
                    Button {
                        if let url = page.url {
                            openURL(url)
                        }
                    } label: {
                        Label("Open", systemImage: "safari")
                    }
                        .disabled(page.url == nil)
                }
                .backport.visibilityPriority(.high)
            }
        }
        
    }
}
