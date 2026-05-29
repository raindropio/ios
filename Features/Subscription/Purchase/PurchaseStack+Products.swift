import SwiftUI
import UI
import API
import StoreKit

extension PurchaseStack {
    struct Products: View {
        @Environment(\.dismiss) private var dismiss
        @EnvironmentObject private var s: SubscriptionStore
        @EnvironmentObject private var u: UserStore
        @EnvironmentObject private var dispatch: Dispatcher
        
        private var products: [Product] {
            s.state.products
        }
        
        var body: some View {
            List {
                Section {
                    ForEach(products) { product in
                        ActionButton {
                            //me can be nil after a background logout
                            guard let meId = u.state.me?.id else { return }
                            try await dispatch(SubscriptionAction.purchase(meId, product))
                            dismiss()
                        } label: {
                            Label(product.displayName, systemImage: "bolt.fill").tint(.primary)
                        }
                            .badge(product.displayPrice)
                    }
                } header: {
                    Text("Select billing cycle")
                } footer: {
                    (
                        Text("\nAuto-renewable. You will get access to all features in all supported platforms.\n\n") +
                        Text("All content you made in PRO remains available in free when subscription is canceled.")
                    )
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                }
            }
        }
    }
}
