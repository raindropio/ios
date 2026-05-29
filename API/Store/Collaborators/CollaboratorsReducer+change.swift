extension CollaboratorsReducer {
    func change(state: S, collectionId: UserCollection.ID, userId: Collaborator.ID, level: CollectionAccess.Level) async throws -> ReduxAction? {
        try await rest.collaboratorChange(collectionId, userId: userId, level: level)
        return A.changed(collectionId, userId: userId, level: level)
    }
    
    func changed(state: inout S, collectionId: UserCollection.ID, userId: Collaborator.ID, level: CollectionAccess.Level) {
        //unshare removes the row; otherwise it lingers as a ghost "No access" entry
        if level == .noAccess {
            state.users[collectionId]?.removeAll { $0.id == userId }
            return
        }

        let index = state.users[collectionId]?.firstIndex { $0.id == userId }
        if let index {
            state.users[collectionId]?[index].level = level
        }
    }
}
