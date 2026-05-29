import Foundation

extension UserCollection: Codable, EncodableWithConfiguration {
    enum CodingKeys: CodingKey {
        case _id
        case title
        case slug
        case description
        case count
        case cover
        case color
        case parent
        case created
        case lastUpdate
        case `public`
        case expanded
        case view
        case sort
        case access
        case collaborators
        case creatorRef
    }
    
    public enum EncodeConfiguration {
        case all
        case modified(from: UserCollection)
        case new
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(type(of: id), forKey: ._id)
        title = try container.decode(type(of: title), forKey: .title)
        slug = (try? container.decode(type(of: slug), forKey: .slug)) ?? ""
        description = try container.decodeIfPresent(type(of: description), forKey: .description) ?? ""
        count = (try? container.decode(type(of: count), forKey: .count)) ?? 0
        color = try? container.decode(type(of: color), forKey: .color)
        created = try? container.decode(type(of: created), forKey: .created)
        lastUpdate = try? container.decode(type(of: lastUpdate), forKey: .lastUpdate)
        `public` = (try? container.decode(type(of: `public`), forKey: .public)) ?? false
        expanded = (try? container.decode(type(of: expanded), forKey: .expanded)) ?? false
        view = (try? container.decode(type(of: view), forKey: .view)) ?? .list
        sort = try? container.decode(type(of: sort), forKey: .sort)
        access = (try? container.decode(type(of: access), forKey: .access)) ?? .init()
        creatorRef = try? container.decode(type(of: creatorRef), forKey: .creatorRef)
        cover = (try? container.decodeIfPresent([URL].self, forKey: .cover))?.first
        parent = (try? container.decode(MongoRef<UserCollection.ID>.self, forKey: .parent))?.id
        collaborators = (try? container.decode(MongoRef<String>.self, forKey: .parent))?.id
    }
    
    public func encode(to encoder: Encoder) throws {
        try encode(to: encoder, configuration: .all)
    }
    
    public func encode(to encoder: Encoder, configuration: EncodeConfiguration) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        //all
        if case .all = configuration {
            try container.encode(id, forKey: ._id)
            try container.encode(slug, forKey: .slug)
            try container.encode(count, forKey: .count)
            try container.encodeIfPresent(color, forKey: .color)
            try container.encode(access, forKey: .access)
            try container.encode(creatorRef, forKey: .creatorRef)
        }
        
        //all or new
        switch configuration {
        case .all, .new:
            try container.encodeIfPresent(created, forKey: .created)
            try container.encodeIfPresent(lastUpdate, forKey: .lastUpdate)
        default: break
        }
        
        //new or modified
        var compare: UserCollection?
        if case .modified(let from) = configuration {
            compare = from
        }
        
        if compare?.title != title {
            try container.encode(title, forKey: .title)
        }
        
        if compare?.description != description {
            try container.encode(description, forKey: .description)
        }
        
        if compare?.public != `public` {
            try container.encode(`public`, forKey: .public)
        }
        
        if compare?.expanded != expanded {
            try container.encode(expanded, forKey: .expanded)
        }
        
        if compare?.view != view {
            try container.encode(view, forKey: .view)
        }
        
        //always send sort!
        try container.encode(sort, forKey: .sort)
        
        if compare?.cover != cover {
            try container.encode(cover != nil ? [cover] : [], forKey: .cover)
        }
        
        if compare?.parent != parent {
            try container.encode(parent != nil ? MongoRef<UserCollection.ID>(parent!) : nil, forKey: .parent)
        }
        
        if compare?.collaborators != collaborators {
            try container.encodeIfPresent(collaborators != nil ? MongoRef<String>(collaborators!) : nil, forKey: .collaborators)
        }
    }
}
