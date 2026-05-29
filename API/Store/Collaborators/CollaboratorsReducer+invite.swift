import SwiftUI

extension CollaboratorsReducer {
    func invite(state: S, collectionId: UserCollection.ID, request: InviteCollaboratorRequest, link: Binding<URL?>) async throws {
        let result = try await rest.collaboratorInvite(collectionId, request: request)
        //`link` is @State (main-actor); this resumes off-main
        await MainActor.run {
            link.wrappedValue = result
        }
    }
}
