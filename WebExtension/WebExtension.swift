import SafariServices

class WebExtension: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems.first as? NSExtensionItem

        //created profiles send their uuid, the default profile sends nothing
        var profile: String? = nil
        if #available(macOS 14.0, iOS 17.0, *) {
            profile = (item?.userInfo?[SFExtensionProfileKey] as? UUID)?.uuidString
        }

        let response = NSExtensionItem()
        response.userInfo = [ SFExtensionMessageKey: [ "profile_id": profile != nil ? profile! as Any : NSNull() ] ]

        context.completeRequest(returningItems: [response], completionHandler: nil)
    }
}
