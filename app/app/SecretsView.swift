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
            // Enhanced Search Bar
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                TextField("Search your secrets...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium))
                    .onSubmit {
                        // Handle search submit if needed
                    }
                
                if !searchText.isEmpty {
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            searchText = "" 
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(.secondary.opacity(0.2))
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            if service.isLoading {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.blue)
                    Text("Loading Secrets...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else if filteredSecrets.isEmpty {
                EmptyStateView(searchText: searchText)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredSecrets) { secret in
                            SecretRowView(secret: secret, service: service)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let searchText: String
    
    var body: some View {
        Spacer()
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                
                Image(systemName: searchText.isEmpty ? "key.horizontal" : "magnifyingglass")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Secrets Yet" : "No Results Found")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(searchText.isEmpty ? 
                     "Add your first secret to get started with EasyKey." : 
                     "Try adjusting your search terms or add a new secret.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        Spacer()
    }
}

#Preview {
    SecretsView(service: EasyKeyService())
}
