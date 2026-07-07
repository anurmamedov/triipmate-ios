import SwiftUI

struct MessagesView: View {
    @EnvironmentObject private var session: AppSession
    @State private var selectedFilter = "All"
    private let filters = ["All", "Requests", "Confirmed"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Messages filter", selection: $selectedFilter) {
                    ForEach(filters, id: \.self) { filter in
                        Text(filter).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top], 16)

                List {
                    ForEach(SampleData.messages) { thread in
                        HStack(spacing: 12) {
                            Avatar(initials: initials(for: thread.name))
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(thread.name)
                                        .font(.headline)
                                    Spacer()
                                    Text(thread.time)
                                        .font(.caption)
                                        .foregroundStyle(Color.tmSlate)
                                }
                                HStack(spacing: 6) {
                                    Text(thread.route)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.tmGreen)
                                    Text(status(for: thread))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(statusColor(for: thread))
                                }
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
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                RoleSwitchHeader(activeRole: $session.activeRole)
            }
        }
    }

    private func initials(for name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
    }

    private func status(for thread: MessageThread) -> String {
        thread.unread ? "Request" : "Confirmed"
    }

    private func statusColor(for thread: MessageThread) -> Color {
        thread.unread ? Color.tmAmber : Color.tmSlate
    }
}
