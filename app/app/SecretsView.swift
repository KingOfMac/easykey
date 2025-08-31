import SwiftUI

struct SecretsView: View {
    @ObservedObject var service: EasyKeyService
    @State private var searchText = ""
    @State private var isSearchFocused = false
    
    private var filteredSecrets: [Secret] {
        if searchText.isEmpty {
            return service.secrets
        } else {
            return service.secrets.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search secrets...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal)
            .padding(.bottom)

            if service.isLoading {
                Spacer()
                ProgressView("Loading Secrets...")
                Spacer()
            } else if filteredSecrets.isEmpty {
                Spacer()
                Text(searchText.isEmpty ? "No secrets found." : "No secrets match your search.")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List(filteredSecrets) { secret in
                    SecretRowView(secret: secret, service: service)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
    }
}

#Preview {
    SecretsView(service: EasyKeyService())
}
