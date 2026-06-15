import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        if session.isAuthenticated {
            TabView {
                SearchView()
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }

                PublishTripView()
                    .tabItem { Label("Post", systemImage: "plus.circle.fill") }

                MessagesView()
                    .tabItem { Label("Messages", systemImage: "bubble.left.and.bubble.right.fill") }

                ProfileView()
                    .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
            }
            .tint(Color.tmGreen)
        } else {
            AuthRootView()
        }
    }
}
