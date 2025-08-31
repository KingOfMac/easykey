import SwiftUI

struct StatusView: View {
    @ObservedObject var service: EasyKeyService

    var body: some View {
        HStack(spacing: 24) {
            StatusItem(
                icon: "key.fill",
                label: "Total Secrets",
                value: "\(service.status?.secrets ?? 0)",
                color: .blue
            )
            
            Divider().frame(height: 30)
            
            StatusItem(
                icon: "clock.fill",
                label: "Last Access",
                value: service.status?.displayLastAccess ?? "N/A",
                color: .green
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding()
    }
}

struct StatusItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    StatusView(service: EasyKeyService())
}
