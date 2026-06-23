import SwiftUI

struct MessagesView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(SampleData.messages) { thread in
                    HStack(spacing: 12) {
                        Avatar(initials: initials(for: thread.name))
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(thread.name)
                                    .font(.headline)
                                Spacer()
                                Text(thread.time)
                                    .font(.caption)
                                    .foregroundStyle(Color.tmSlate)
                            }
                            Text(thread.route)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.tmGreen)
                            Text(thread.message)
                                .font(.subheadline)
                                .foregroundStyle(Color.tmSlate)
                                .lineLimit(1)
                        }
                        if thread.unread {
                            Circle()
                                .fill(Color.tmGreen)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Messages")
        }
    }

    private func initials(for name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
    }
}
