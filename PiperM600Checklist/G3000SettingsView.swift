import SwiftUI

struct G3000SettingsView: View {
    @State private var showRebuildConfirm = false
    @State private var showRebuildResult = false
    @State private var rebuildMessage = ""

    var body: some View {
        List {
            Section {
                Button {
                    showRebuildConfirm = true
                } label: {
                    Text("Rebuild G3000 Guide Index")
                }
            } footer: {
                Text("Clears the cached G3000 guide index and rebuilds it next time the guide is opened.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(InstrumentBackground().ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .navigationTitle("G3000 Guide Settings")
        .alert("Rebuild G3000 Index?", isPresented: $showRebuildConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Rebuild", role: .destructive) {
                let success = G3000IndexCache.clear()
                rebuildMessage = success
                    ? "G3000 guide index cleared. It will rebuild next time you open G3000."
                    : "Could not clear the G3000 guide index. Please try again."
                showRebuildResult = true
            }
        } message: {
            Text("This clears the cached G3000 guide index and forces a rebuild.")
        }
        .alert("G3000 Index", isPresented: $showRebuildResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(rebuildMessage)
        }
    }
}
