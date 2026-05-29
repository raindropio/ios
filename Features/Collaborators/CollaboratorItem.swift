import SwiftUI
import API
import UI

struct CollaboratorItem: View {
    var collection: UserCollection
    var collaborator: Collaborator
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            UserAvatar(collaborator, width: 32)
                .font(.system(size: 32))
                .frame(width: 32)
                .fixedSize()
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(collaborator.name)
                    Spacer()
                    if collaborator.me {
                        Text("Me")
                    }
                }
                
                Group {
                    Text(collaborator.email)
                    ChangeLevel(collection: collection, collaborator: collaborator)
                }
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
