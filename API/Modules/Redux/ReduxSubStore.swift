import SwiftUI

actor ReduxEngine<R: Reducer> {
    let reducer = R()
    private(set) var state: R.S = R.S()
    //reduce order (actor-serialized) — lets the publish drop stale snapshots
    private var version: UInt64 = 0

    func reduce(_ action: ReduxAction) throws -> (R.S, UInt64, ReduxAction?, R, Bool) {
        let oldState = state
        let next = try reducer.reduce(state: &state, action: action)
        version &+= 1
        return (state, version, next, reducer, oldState != state)
    }

    func current() -> (R.S, R) {
        (state, reducer)
    }
}

@MainActor
public class ReduxSubStore<R: Reducer>: ObservableObject {
    let engine = ReduxEngine<R>()
    @Published public private(set) var state = R.S()
    //highest version already published — never overwrite it with an older snapshot
    private var publishedVersion: UInt64 = 0

    nonisolated func process(_ some: Any) async throws -> [ReduxAction] {
        var nextActions: [ReduxAction] = []

        if let action = some as? ReduxAction {
            let (newState, version, nextFromReduce, reducer, stateChanged) = try await engine.reduce(action)

            if stateChanged {
                await MainActor.run {
                    if version > self.publishedVersion {
                        self.publishedVersion = version
                        self.state = newState
                    }
                }
            }

            if let next = nextFromReduce {
                nextActions.append(next)
            }

            if let nextFromMiddleware = try await reducer.middleware(state: newState, action: action) {
                nextActions.append(nextFromMiddleware)
            }
        }
        else if let error = some as? Error {
            let (state, reducer) = await engine.current()
            if let nextFromMiddleware = try await reducer.middleware(state: state, error: error) {
                nextActions.append(nextFromMiddleware)
            }
        }

        return nextActions
    }
}