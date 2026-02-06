import SwiftUI

struct POHSettingsView: View {
    @State private var showRebuildConfirm = false
    @State private var showRebuildResult = false
    @State private var rebuildMessage = ""

    var body: some View {
        List {
            Section {
                Button {
                    showRebuildConfirm = true
                } label: {
                    Text("Rebuild POH Search Index")
                }
            } footer: {
                Text("Clears the cached POH index and rebuilds it next time POH is opened.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(InstrumentBackground().ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .navigationTitle("POH Settings")
        .alert("Rebuild POH Index?", isPresented: $showRebuildConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Rebuild", role: .destructive) {
                let success = POHIndexCache.clear()
                rebuildMessage = success
                    ? "POH index cleared. It will rebuild next time you open POH."
                    : "Could not clear the POH index. Please try again."
                showRebuildResult = true
            }
        } message: {
            Text("This clears the cached POH index and forces a rebuild.")
        }
        .alert("POH Index", isPresented: $showRebuildResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(rebuildMessage)
        }
    }
}
