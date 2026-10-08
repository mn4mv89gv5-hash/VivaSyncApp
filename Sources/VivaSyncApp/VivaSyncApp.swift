import SwiftUI

@main
struct VivaSyncAppApp: App {
    @StateObject private var viewModel = SyncViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .task {
                    await viewModel.onAppear()
                }
        }
    }
}
