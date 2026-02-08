import SwiftUI
import PDFKit

struct DocumentsView: View {
    @StateObject private var store = DocumentsStore()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isPadLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ZStack {
            InstrumentBackground()
                .ignoresSafeArea()

            VStack(spacing: isPadLayout ? 16 : 12) {
                headerView

                ScrollView {
                    VStack(spacing: isPadLayout ? 18 : 14) {
                        ForEach(DocumentCategory.allCases) { category in
                            documentSection(for: category)
                        }
                    }
                    .padding(.horizontal, isPadLayout ? 22 : 16)
                    .padding(.bottom, isPadLayout ? 24 : 18)
                }
            }
            .padding(.top, isPadLayout ? 16 : 8)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    DocumentsSettingsView(store: store)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: isPadLayout ? 10 : 6) {
            BrandLogoView()
                .frame(maxWidth: isPadLayout ? 140 : 110)
                .padding(.bottom, 4)

            Text("Documents")
                .font(.custom("Avenir Next Condensed Demi Bold", size: isPadLayout ? 26 : 20))
                .foregroundColor(AppTheme.text)

            Text("Personal, aircraft, insurance, company, and operator references")
                .font(.custom("Avenir Next Regular", size: isPadLayout ? 14 : 12))
                .foregroundColor(AppTheme.muted)
        }
        .padding(.horizontal, isPadLayout ? 28 : 16)
    }

    private func documentSection(for category: DocumentCategory) -> some View {
        let items = store.documents(in: category)

        return VStack(alignment: .leading, spacing: isPadLayout ? 10 : 8) {
            Text(category.title)
                .font(.custom("Avenir Next Condensed Demi Bold", size: isPadLayout ? 18 : 15))
                .foregroundColor(AppTheme.text)
                .padding(.horizontal, 4)

            if items.isEmpty {
                Text("No \(category.title.lowercased()) documents yet.")
                    .font(.custom("Avenir Next Regular", size: isPadLayout ? 13 : 11))
                    .foregroundColor(AppTheme.muted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBackground)
            } else {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        NavigationLink {
                            DocumentDetailView(item: item, store: store)
                        } label: {
                            DocumentRowView(title: item.name)
                        }
                        .buttonStyle(.plain)

                        if item.id != items.last?.id {
                            Divider()
                                .background(AppTheme.gridLine)
                                .padding(.leading, 44)
                        }
                    }
                }
                .background(cardBackground)
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [AppTheme.card, AppTheme.cardHighlight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.bezelDark, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .inset(by: 1)
                    .stroke(AppTheme.bezelLight, lineWidth: 1)
            )
    }
}

struct DocumentRowView: View {
    let title: String
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isPadLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: isPadLayout ? 18 : 16, weight: .semibold))
                .foregroundColor(AppTheme.accent)

            Text(title)
                .font(.custom("Avenir Next Regular", size: isPadLayout ? 15 : 13))
                .foregroundColor(AppTheme.text)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: isPadLayout ? 14 : 12, weight: .semibold))
                .foregroundColor(AppTheme.muted)
        }
        .padding(.vertical, isPadLayout ? 12 : 10)
        .padding(.horizontal, 14)
    }
}

struct DocumentDetailView: View {
    let item: DocumentItem
    @ObservedObject var store: DocumentsStore
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            InstrumentBackground()
                .ignoresSafeArea()

            if let document = PDFDocument(url: store.url(for: item)) {
                DocumentPDFView(document: document)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 12)
            } else {
                VStack(spacing: 8) {
                    Text("Document unavailable")
                        .font(.custom("Avenir Next Condensed Demi Bold", size: 20))
                        .foregroundColor(AppTheme.text)
                    Text("The file could not be loaded.")
                        .font(.custom("Avenir Next Regular", size: 14))
                        .foregroundColor(AppTheme.muted)
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(AppTheme.accent)
                }
                .accessibilityLabel("Share Document")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [store.url(for: item)])
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
