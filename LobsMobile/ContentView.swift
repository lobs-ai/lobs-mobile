import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    init() {
        // Configure dark tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.nexusCharcoal)
        
        // Normal state
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.nexusMuted)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.nexusMuted)
        ]
        
        // Selected state
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.nexusTeal)
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.nexusTeal)
        ]
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure dark navigation bar
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(Color.nexusNavy)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color.nexusText)]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.nexusText)]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(Color.nexusTeal)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(1)
            
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(2)
            
            InboxView()
                .tabItem {
                    Label("Inbox", systemImage: "tray.fill")
                }
                .tag(3)
            
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
                .tag(4)
        }
        .preferredColorScheme(.dark)
    }
}
