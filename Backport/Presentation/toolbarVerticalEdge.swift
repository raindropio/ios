import SwiftUI

public extension EnvironmentValues {
    var backportToolbarVerticalEdge: HorizontalEdge? {
        #if os(iOS)
        if #available(iOS 27.1, *) {
            return toolbarVerticalEdge
        }
        #endif
        return nil
    }
}