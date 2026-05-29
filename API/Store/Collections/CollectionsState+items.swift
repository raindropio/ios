import Foundation

extension CollectionsState {
    public func childrens(of id: UserCollection.ID) -> [UserCollection] {
        if id <= 0 {
            return []
        }
        
        return user
            .filter { $0.value.parent == id }
            .map { $0.value }
            .sorted(using: KeyPathComparator(\.sort))
    }
    
    public func childrensRecursive(of id: UserCollection.ID) -> [UserCollection] {
        var found: [UserCollection] = []
        //visited guards against a cyclic parent chain (would otherwise recurse forever)
        var visited: Set<UserCollection.ID> = [id]

        func walk(_ parentId: UserCollection.ID) {
            for child in childrens(of: parentId) where visited.insert(child.id).inserted {
                found.append(child)
                walk(child.id)
            }
        }

        walk(id)
        return found
    }

    public func location(of collection: UserCollection) -> [UserCollection] {
        //visited guards against a cyclic parent chain (would otherwise loop forever)
        var chain: [UserCollection] = []
        var visited: Set<UserCollection.ID> = [collection.id]
        var current = collection

        while
            let parentId = current.parent,
            visited.insert(parentId).inserted,
            let parent = user[parentId]
        {
            chain.append(parent)
            current = parent
        }

        return chain.reversed()
    }
    
    public func location(of collection: UserCollection) -> CGroup? {
        let rootId = location(of: collection).last?.id ?? collection.id
                        
        for group in groups {
            if group.collections.contains(rootId) {
                return group
            }
        }
        return nil
    }
    
    public func find(_ search: String) -> [UserCollection] {
        let filter = search.localizedLowercase.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if filter.isEmpty {
            return []
        }
        
        return user
            .filter {
                $0.value.title.localizedLowercase.contains(filter)
            }
            .map {
                $0.value
            }
            .sorted(using: [
                KeyPathComparator(\.parent),
                KeyPathComparator(\.title)
            ])
    }
    
    public func find(_ findBy: FindBy) -> [UserCollection] {
        guard findBy.collectionId == 0 else { return [] }
        
        return find(findBy.search).filter {
            $0.id != findBy.collectionId
        }
    }
    
    public var allCollapsed: Bool {
        user.first { $0.value.expanded } == nil
    }
}
