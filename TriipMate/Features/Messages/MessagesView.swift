import SwiftUI

struct MessagesView: View {
    @EnvironmentObject private var session: AppSession
    @State private var selectedFilter: MessageFilter = .all

    private var visibleConversations: [RideConversation] {
        guard let uid = session.authUser?.uid else { return [] }
        switch selectedFilter {
        case .all:
            return session.conversations
        case .unread:
            return session.conversations.filter { $0.unreadCountsByUid[uid, default: 0] > 0 }
        case .rides:
            return session.conversations.filter { $0.rideId != nil }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tmMist.ignoresSafeArea()

                VStack(spacing: 16) {
                    messageFilter

                    if session.isConversationsLoading && session.conversations.isEmpty {
                        MessageLoadingView()
                    } else if visibleConversations.isEmpty {
                        MessageEmptyState(filter: selectedFilter) {
                            Task { await session.loadConversations() }
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(visibleConversations) { conversation in
                                    NavigationLink(value: conversation) {
                                        ConversationCard(conversation: conversation, currentUid: session.authUser?.uid)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 18)
                        }
                        .refreshable {
                            await session.loadConversations()
                        }
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                RoleSwitchHeader()
            }
            .navigationDestination(for: RideConversation.self) { conversation in
                ConversationDetailView(conversation: conversation)
            }
            .task {
                await session.loadConversations()
                await refreshInboxWhileVisible()
            }
        }
    }

    private var messageFilter: some View {
        Picker("Messages filter", selection: $selectedFilter) {
            ForEach(MessageFilter.allCases) { filter in
                Label(filter.title, systemImage: filter.icon).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private func refreshInboxWhileVisible() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(4))
            await session.refreshConversationsSilently()
        }
    }
}

private enum MessageFilter: String, CaseIterable, Identifiable {
    case all
    case unread
    case rides

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "All"
        case .unread: "Unread"
        case .rides: "Rides"
        }
    }

    var icon: String {
        switch self {
        case .all: "bubble.left.and.bubble.right.fill"
        case .unread: "circle.fill"
        case .rides: "car.fill"
        }
    }
}

private struct ConversationCard: View {
    let conversation: RideConversation
    let currentUid: String?

    private var otherName: String {
        guard let currentUid else { return "TriipMate rider" }
        return conversation.otherParticipantName(for: currentUid)
    }

    private var unreadCount: Int {
        guard let currentUid else { return 0 }
        return conversation.unreadCountsByUid[currentUid, default: 0]
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Avatar(initials: otherName.initials)
                    .frame(width: 48, height: 48)

                if unreadCount > 0 {
                    Circle()
                        .fill(Color.tmGreen)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(otherName)
                        .font(.headline)
                        .foregroundStyle(Color.tmInk)
                        .lineLimit(1)
                    Spacer()
                    Text(conversation.lastMessageAt?.date.messageTimeLabel ?? conversation.updatedAt.date.messageTimeLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.tmSlate)
                }

                HStack(spacing: 6) {
                    Image(systemName: "car.fill")
                        .font(.caption)
                        .foregroundStyle(Color.tmGreen)
                    Text(conversation.routeTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.tmGreen)
                        .lineLimit(1)
                }

                HStack(spacing: 10) {
                    Text(conversation.lastMessagePreview ?? "No messages yet. Start the conversation.")
                        .font(.subheadline)
                        .foregroundStyle(unreadCount > 0 ? Color.tmInk : Color.tmSlate)
                        .fontWeight(unreadCount > 0 ? .semibold : .regular)
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 22, minHeight: 22)
                            .background(Color.tmGreen)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(unreadCount > 0 ? Color.tmGreen.opacity(0.3) : Color.tmLine, lineWidth: 1)
        }
    }
}

private struct ConversationDetailView: View {
    @EnvironmentObject private var session: AppSession
    let conversation: RideConversation
    @State private var draft = ""

    private var currentUid: String {
        session.authUser?.uid ?? ""
    }

    private var liveConversation: RideConversation {
        session.conversations.first(where: { $0.id == conversation.id }) ?? conversation
    }

    private var messages: [RideMessage] {
        session.messagesByConversationId[conversation.id] ?? []
    }

    private var otherName: String {
        liveConversation.otherParticipantName(for: currentUid)
    }

    var body: some View {
        ZStack {
            Color.tmMist.ignoresSafeArea()

            VStack(spacing: 0) {
                chatHeader

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if session.isMessagesLoading && messages.isEmpty {
                                MessageLoadingView()
                                    .padding(.top, 28)
                            } else if messages.isEmpty {
                                ChatEmptyState(otherName: otherName)
                                    .padding(.top, 28)
                            } else {
                                ForEach(messages) { message in
                                    MessageBubble(message: message, isMine: message.senderUid == currentUid)
                                        .id(message.id)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .onChange(of: messages.count) { _ in
                        scrollToLatest(proxy: proxy)
                    }
                    .onAppear {
                        scrollToLatest(proxy: proxy)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            composer
        }
        .navigationTitle(otherName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await session.loadMessages(for: liveConversation)
            await refreshChatWhileVisible()
        }
    }

    private var chatHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Avatar(initials: otherName.initials)
                    .frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(liveConversation.routeTitle)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.tmInk)
                        .lineLimit(1)
                    Text("Ride chat")
                        .font(.caption)
                        .foregroundStyle(Color.tmSlate)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color.tmGreen)
            }
        }
        .padding(14)
        .background(.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.tmLine)
                .frame(height: 1)
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message \(otherName)", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.tmLine, lineWidth: 1)
                }

            Button {
                send()
            } label: {
                if session.isMessageSending {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 44, height: 44)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
            }
            .buttonStyle(.plain)
            .background(draft.trimmed.isEmpty ? Color.tmSlate.opacity(0.4) : Color.tmGreen)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .disabled(draft.trimmed.isEmpty || session.isMessageSending)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.tmMist.opacity(0.98).ignoresSafeArea())
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.tmLine)
                .frame(height: 1)
        }
    }

    private func send() {
        let message = draft
        draft = ""
        Task {
            let didSend = await session.sendMessage(message, in: liveConversation)
            if !didSend {
                draft = message
            }
        }
    }

    private func refreshChatWhileVisible() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(3))
            await session.refreshMessagesSilently(for: liveConversation)
        }
    }

    private func scrollToLatest(proxy: ScrollViewProxy) {
        guard let id = messages.last?.id else { return }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.22)) {
                proxy.scrollTo(id, anchor: .bottom)
            }
        }
    }
}

private struct MessageBubble: View {
    let message: RideMessage
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine {
                Spacer(minLength: 42)
            }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 5) {
                Text(message.body)
                    .font(.body)
                    .foregroundStyle(isMine ? .white : Color.tmInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message.createdAt.date.messageTimeLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isMine ? .white.opacity(0.78) : Color.tmSlate)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(isMine ? Color.tmGreen : .white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isMine ? Color.clear : Color.tmLine, lineWidth: 1)
            }

            if !isMine {
                Spacer(minLength: 42)
            }
        }
    }
}

private struct MessageLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color.tmGreen)
            Text("Loading messages")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.tmSlate)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}

private struct MessageEmptyState: View {
    let filter: MessageFilter
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: filter == .unread ? "checkmark.bubble.fill" : "bubble.left.and.bubble.right.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.tmGreen)
                .frame(width: 66, height: 66)
                .background(Color.tmGreen.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(filter == .unread ? "No unread messages" : "No ride messages yet")
                .font(.headline)
                .foregroundStyle(Color.tmInk)

            Text(filter == .unread ? "New replies will appear here as soon as they arrive." : "Chats open after a driver accepts a ride request.")
                .font(.subheadline)
                .foregroundStyle(Color.tmSlate)
                .multilineTextAlignment(.center)

            Button(action: retry) {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.tmGreen)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ChatEmptyState: View {
    let otherName: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.tmGreen)
                .frame(width: 58, height: 58)
                .background(Color.tmGreen.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text("Start with \(otherName)")
                .font(.headline)
                .foregroundStyle(Color.tmInk)
            Text("Confirm pickup details, timing, luggage, or anything important before the ride.")
                .font(.subheadline)
                .foregroundStyle(Color.tmSlate)
                .multilineTextAlignment(.center)
        }
        .padding(22)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.tmLine, lineWidth: 1)
        }
    }
}

private extension Date {
    var messageTimeLabel: String {
        if Calendar.current.isDateInToday(self) {
            return formatted(date: .omitted, time: .shortened)
        }
        if Calendar.current.isDateInYesterday(self) {
            return "Yesterday"
        }
        return formatted(.dateTime.month(.abbreviated).day())
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var initials: String {
        split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }
}
