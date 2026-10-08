import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: SyncViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                if viewModel.isAuthenticated {
                    statusCard
                    syncButton
                } else {
                    loginCard
                }
            }
            .padding()
            .navigationTitle("VivaSyncApp")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isAuthenticated {
                        Button("Logout") {
                            Task {
                                await viewModel.logout()
                            }
                        }
                    }
                }
            }
        }
        .alert(item: $viewModel.alertItem) { item in
            Alert(
                title: Text(item.title),
                message: Text(item.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var loginCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accesso Classe Viva")
                .font(.title2)
                .bold()

            TextField("Username o email", text: $viewModel.username)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)

            Button {
                Task {
                    await viewModel.login()
                }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Accedi")
                    }
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)

            if let message = viewModel.loginErrorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sincronizzazione")
                .font(.headline)

            Label(viewModel.syncStatusText, systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)

            if let lastSync = viewModel.lastSyncDate {
                Text("Ultimo aggiornamento: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("La sincronizzazione automatica viene eseguita ogni giorno alle 15:00.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var syncButton: some View {
        Button {
            Task {
                await viewModel.syncNow()
            }
        } label: {
            HStack {
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Sincronizza adesso")
                }
                Spacer()
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isLoading)
    }
}
