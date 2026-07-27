extension ConfigReducer {
    func logout(state: inout S) {
        state.ai = .init()
        state.collections = .init()
        state.raindrops = .init()
    }
}
