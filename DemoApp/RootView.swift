import SwiftUI

enum CaseStudy: String, CaseIterable, Identifiable {
    case padding = "padding"
    case background = "background"
    case fixedSize = "fixedSize"
    case hStack = "HStack"

    var id: Self {
        self
    }

    var label: String {
        rawValue
    }
}

struct RootView: View {
    @State private var selection: CaseStudy?
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Sidebar(selection: $selection)
        } detail: {
            if let caseStudy = selection {
                MainContent(caseStudy: caseStudy)
            } else {
                Text("Select an item in the sidebar")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct Sidebar: View {
    @Binding var selection: CaseStudy?

    var body: some View {
        List(CaseStudy.allCases, selection: $selection) { caseStudy in
            Text(caseStudy.label)
        }
        .navigationTitle("Layout Inspector")
    }
}

struct MainContent: View {
    var caseStudy: CaseStudy

    var body: some View {
        ZStack {
            switch caseStudy {
            case .padding:
                PaddingExample()
            case .background:
                BackgroundExample()
            case .fixedSize:
                FixedSizeExample()
            case .hStack:
                HStackExample()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle(caseStudy.label)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
