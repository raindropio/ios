import SwiftUI
import UI
import API

extension SubscriptionOffer {
    struct Pro: View {
        @EnvironmentObject private var s: SubscriptionStore
        @EnvironmentObject private var dispatch: Dispatcher

        var body: some View {
            Section {
                VStack(spacing: 12) {
                    Text("Use Raindrop.io for free or upgrade for **extra features**")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineSpacing(3)
                    
                    Text("Starting from \(s.state.lowestDisplayPrice)/month. Enabled on all platforms. Cancel anytime.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                        .safeAnimation(.default, value: s.state.lowestDisplayPrice)
                }
                    .scenePadding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
                .clearSection()
                .reload {
                    try? await dispatch(SubscriptionAction.products)
                }
            
            Section {
                ProFeatures()
            }
            
            Section("FAQ") {
                ProFaq()
            }
                .headerProminence(.increased)
        }
    }
}
