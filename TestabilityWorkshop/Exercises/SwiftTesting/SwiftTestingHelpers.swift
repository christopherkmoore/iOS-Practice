import SwiftUI

// MARK: - Shared Helper Views for Swift Testing Section

struct CodeBlock: View {
    let code: String

    init(_ code: String) {
        self.code = code
    }

    var body: some View {
        Text(code)
            .font(.system(.caption, design: .monospaced))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(8)
    }
}

struct CalloutBox: View {
    let message: String
    let type: CalloutType

    enum CalloutType {
        case tip, warning, info

        var color: Color {
            switch self {
            case .tip: return .green
            case .warning: return .orange
            case .info: return .blue
            }
        }

        var icon: String {
            switch self {
            case .tip: return "lightbulb"
            case .warning: return "exclamationmark.triangle"
            case .info: return "info.circle"
            }
        }
    }

    init(_ message: String, type: CalloutType) {
        self.message = message
        self.type = type
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            Text(message)
                .font(.caption)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(type.color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ComparisonRow: View {
    let xctest: String
    let swift: String

    var body: some View {
        HStack(spacing: 8) {
            Text(xctest)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(swift)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
