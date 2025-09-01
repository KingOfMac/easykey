import SwiftUI

struct StatusView: View {
    @ObservedObject var service: EasyKeyService

    var body: some View {
        HStack(spacing: 0) {
            StatusItem(
                icon: "key.fill",
                label: "Total Secrets",
                value: "\(service.status?.secrets ?? 0)",
                color: .blue,
                gradientColors: [.blue.opacity(0.8), .cyan.opacity(0.6)]
            )
            
            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(width: 1, height: 40)
                .padding(.horizontal, 20)
            
            StatusItem(
                icon: "clock.fill",
                label: "Last Access",
                value: service.status?.displayLastAccess ?? "N/A",
                color: .green,
                gradientColors: [.green.opacity(0.8), .mint.opacity(0.6)]
            )
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

struct StatusItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let gradientColors: [Color]

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 2)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            Spacer()
        }
    }
}

#Preview {
    StatusView(service: EasyKeyService())
}
