import SwiftUI
@preconcurrency import PDFKit

struct G3000View: View {
    @StateObject private var model = G3000ViewModel()
    @State private var showSettings = false
    @State private var showChapters = false
    @State private var currentPageIndex = 0
    @State private var pageCount = 1
    @State private var jumpText = ""
    @State private var sliderValue: Double = 1
    @State private var isSliderEditing = false
    @State private var lastNavigationFromTOC = false
    @State private var showFullScreen = false
    @FocusState private var isSearchFocused: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss

    private var isPadLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: isPadLayout ? 16 : 12) {
                headerView
                searchBar
                resultsBar
                pageNavBar
                resultsPanel

                PDFKitView(
                    document: model.document,
                    highlightedSelections: model.currentHighlight,
                    currentSelection: model.currentSelection,
                    currentPageIndex: $currentPageIndex,
                    pageCount: $pageCount
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
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
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        showFullScreen = true
                    }
                )
            }
            .padding(isPadLayout ? 18 : 14)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .background(InstrumentBackground().ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if lastNavigationFromTOC {
                            showChapters = true
                            lastNavigationFromTOC = false
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppTheme.accent)
                    }
                    .accessibilityLabel("Back")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(AppTheme.accent)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                G3000SettingsView()
            }
            .navigationDestination(isPresented: $showFullScreen) {
                G3000FullScreenView(
                    document: model.document,
                    highlightedSelections: model.currentHighlight,
                    currentSelection: model.currentSelection,
                    currentPageIndex: $currentPageIndex,
                    pageCount: $pageCount
                )
            }
            .sheet(isPresented: $showChapters) {
                NavigationStack {
                    G3000TableOfContentsView(
                        items: model.outlineItems,
                        onSelect: { pageIndex in
                            currentPageIndex = pageIndex
                            showChapters = false
                            lastNavigationFromTOC = true
                        },
                        onClose: {
                            showChapters = false
                        }
                    )
                }
            }
            .onAppear {
                model.onAppear()
                if let doc = model.document {
                    pageCount = max(doc.pageCount, 1)
                }
                if G3000IndexCache.consumeClearedFlag() {
                    Task {
                        await model.rebuildIndex()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: G3000IndexCache.didClearNotification)) { _ in
                model.indexBannerVisible = true
                Task {
                    await model.rebuildIndex()
                }
            }
            .onChange(of: model.document?.pageCount ?? 0) { newValue in
                if newValue > 0 {
                    pageCount = max(newValue, 1)
                }
            }
            .onChange(of: currentPageIndex) { newValue in
                jumpText = "\(newValue + 1)"
                let upper = max(pageCount, 1)
                let clamped = min(max(newValue + 1, 1), upper)
                sliderValue = Double(clamped)
            }
            .onChange(of: pageCount) { newValue in
                let maxIndex = max(newValue - 1, 0)
                if currentPageIndex > maxIndex {
                    currentPageIndex = maxIndex
                }
                let upper = max(newValue, 1)
                let clamped = min(max(currentPageIndex + 1, 1), upper)
                sliderValue = Double(clamped)
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 4) {
            Text("G3000 Pilot Guide")
                .font(.custom("Avenir Next Demi Bold", size: isPadLayout ? 18 : 15))
                .foregroundColor(AppTheme.text)

            Text("Reference and search")
                .font(.custom("Avenir Next Regular", size: isPadLayout ? 13 : 11))
                .foregroundColor(AppTheme.muted)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.muted)

            TextField("Search Guide", text: $model.query)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .foregroundColor(AppTheme.text)
                .focused($isSearchFocused)
                .onTapGesture {
                    isSearchFocused = true
                }

            if !model.query.isEmpty {
                Button {
                    model.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.muted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.accentSoft, lineWidth: 1)
                )
        )
    }

    private var resultsBar: some View {
        HStack(spacing: 12) {
            if model.isIndexing || model.indexBannerVisible {
                ProgressView(value: model.isIndexing ? model.indexProgress : nil)
                    .tint(AppTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    let percent = Int(model.indexProgress * 100)
                    let detail = model.indexDetail.isEmpty
                        ? "Indexing in progress... \(percent)%"
                        : "\(model.indexDetail) (\(percent)%)"
                    Text(detail)
                        .font(.custom("Avenir Next Regular", size: isPadLayout ? 13 : 11))
                        .foregroundColor(AppTheme.muted)
                }
            } else {
                Text(model.resultsSummary)
                    .font(.custom("Avenir Next Regular", size: isPadLayout ? 13 : 11))
                    .foregroundColor(AppTheme.muted)
            }

            Spacer()

            Button {
                model.goToPrevious()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: isPadLayout ? 16 : 14, weight: .semibold))
                    .foregroundColor(model.canGoPrevious ? AppTheme.text : AppTheme.muted)
            }
            .disabled(!model.canGoPrevious)

            Button {
                model.goToNext()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: isPadLayout ? 16 : 14, weight: .semibold))
                    .foregroundColor(model.canGoNext ? AppTheme.text : AppTheme.muted)
            }
            .disabled(!model.canGoNext)
        }
        .padding(.horizontal, 6)
    }

    private var pageNavBar: some View {
        let safePageCount = max(pageCount, 1)
        let safeIndex = min(max(currentPageIndex, 0), safePageCount - 1)

        return VStack(spacing: 8) {
            HStack {
                Button {
                    showChapters = true
                } label: {
                    Label("Table of Contents", systemImage: "list.bullet.rectangle")
                        .font(.custom("Avenir Next Demi Bold", size: isPadLayout ? 12 : 11))
                        .foregroundColor(AppTheme.accent)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Page \(safeIndex + 1) of \(safePageCount)")
                    .font(.custom("Avenir Next Regular", size: isPadLayout ? 12 : 11))
                    .foregroundColor(AppTheme.muted)
            }

            HStack(spacing: 10) {
                if safePageCount > 1 {
                    Slider(
                        value: $sliderValue,
                        in: 1...Double(safePageCount),
                        step: 1
                    ) { editing in
                        isSliderEditing = editing
                        if !editing {
                            let clamped = min(max(Int(sliderValue.rounded()), 1), safePageCount)
                            currentPageIndex = clamped - 1
                        }
                    }
                    .tint(AppTheme.accent)
                    .onChange(of: sliderValue) { newValue in
                        guard isSliderEditing else { return }
                        let clamped = min(max(Int(newValue.rounded()), 1), safePageCount)
                        sliderValue = Double(clamped)
                    }
                } else {
                    Capsule()
                        .fill(AppTheme.cardHighlight)
                        .frame(height: 6)
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.accentSoft, lineWidth: 1)
                        )
                }

                TextField("Page", text: $jumpText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: isPadLayout ? 60 : 48)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppTheme.accentSoft, lineWidth: 1)
                            )
                    )
                    .foregroundColor(AppTheme.text)
                    .onSubmit {
                        jumpToPage()
                    }

                Button("Go") {
                    jumpToPage()
                }
                .font(.custom("Avenir Next Demi Bold", size: isPadLayout ? 12 : 11))
                .foregroundColor(AppTheme.text)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.accentSoft)
                )
            }
        }
        .padding(.horizontal, 6)
    }

    private func jumpToPage() {
        let trimmed = jumpText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let page = Int(trimmed) else { return }
        let clamped = min(max(page, 1), max(pageCount, 1))
        currentPageIndex = clamped - 1
    }

    private var resultsPanel: some View {
        Group {
            if !model.results.isEmpty {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(model.results.enumerated()), id: \.element.id) { index, result in
                            Button {
                                model.selectResult(at: index)
                            } label: {
                                HStack(spacing: 12) {
                                    Text("Pg \(result.pageIndex + 1)")
                                        .font(.custom("Avenir Next Demi Bold", size: isPadLayout ? 13 : 11))
                                        .foregroundColor(AppTheme.text)
                                        .frame(width: isPadLayout ? 64 : 52, alignment: .leading)

                                    Text(result.excerpt)
                                        .font(.custom("Avenir Next Regular", size: isPadLayout ? 12 : 10))
                                        .foregroundColor(AppTheme.muted)
                                        .lineLimit(2)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: isPadLayout ? 12 : 11, weight: .semibold))
                                        .foregroundColor(AppTheme.muted)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(index == model.currentResultIndex ? AppTheme.cardHighlight : AppTheme.card)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppTheme.accentSoft, lineWidth: index == model.currentResultIndex ? 1.2 : 0.8)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: isPadLayout ? 180 : 140)
            }
        }
    }

}

@MainActor
final class G3000ViewModel: ObservableObject {
    @Published var query: String = "" {
        didSet {
            scheduleSearch()
        }
    }
    @Published var results: [G3000SearchHit] = []
    @Published var currentSelection: PDFSelection?
    @Published var currentHighlight: [PDFSelection] = []
    @Published var resultsCapped = false
    @Published var isIndexing = false
    @Published var indexProgress: Double = 0
    @Published var indexStatus = "Index loading..."
    @Published var indexBannerVisible = false
    @Published var outlineItems: [G3000OutlineItem] = []
    @Published var indexDetail = ""

    private(set) var document: PDFDocument?
    private var searchTask: Task<Void, Never>?
    private var index: G3000SearchIndex?
    private var statusToken = UUID()
    private var partialPageTexts: [String] = []
    private var partialTokenIndex: [String: Set<Int>] = [:]
    private var totalPageCount: Int = 0
    private var indexingCurrentPage = 0
    private var indexingPageTexts: [String] = []
    private var indexingTokenIndex: [String: Set<Int>] = [:]
    private var indexingTotal = 0
    private let indexingBatchSize = 4


    var resultsSummary: String {
        guard !isIndexing else { return "Indexing..." }
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "Enter a search term." }
        if query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 { return "Type at least 2 characters." }
        if results.isEmpty { return "No matches found." }
        if resultsCapped { return "Showing first 200 matches." }
        return "Matches: \(currentIndexDisplay)"
    }

    private var currentIndexDisplay: String {
        "\(min(currentResultIndex + 1, max(results.count, 1))) of \(results.count)"
    }

    var canGoPrevious: Bool {
        results.count > 1 && currentResultIndex > 0
    }

    var canGoNext: Bool {
        results.count > 1 && currentResultIndex < results.count - 1
    }

    var currentResultIndex: Int = 0 {
        didSet {
            if let document {
                updateSelection(document: document)
            } else {
                currentSelection = nil
                currentHighlight = []
            }
        }
    }

    func onAppear() {
        guard document == nil else { return }
        document = G3000DocumentProvider.loadDocument()
        if let document {
            outlineItems = G3000OutlineItem.build(from: document)
        }
        Task {
            await buildIndexIfNeeded()
        }
    }

    func rebuildIndex() async {
        if document == nil {
            document = G3000DocumentProvider.loadDocument()
        }
        indexBannerVisible = true
        isIndexing = true
        index = nil
        results = []
        currentSelection = nil
        currentHighlight = []
        currentResultIndex = 0
        resultsCapped = false
        await buildIndexIfNeeded()
    }

    func clearSearch() {
        query = ""
        results = []
        currentSelection = nil
        currentHighlight = []
        currentResultIndex = 0
        resultsCapped = false
    }

    func goToNext() {
        guard canGoNext else { return }
        currentResultIndex += 1
    }

    func goToPrevious() {
        guard canGoPrevious else { return }
        currentResultIndex -= 1
    }

    func selectResult(at index: Int) {
        guard results.indices.contains(index) else { return }
        currentResultIndex = index
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        let queryText = query
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard let self else { return }
            await self.performSearch(query: queryText)
        }
    }

    private func performSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < 2 {
            results = []
            currentSelection = nil
            currentHighlight = []
            currentResultIndex = 0
            resultsCapped = false
            return
        }
        guard !trimmed.isEmpty else {
            results = []
            currentSelection = nil
            currentHighlight = []
            currentResultIndex = 0
            resultsCapped = false
            return
        }

        guard let document else {
            return
        }

        let pageTexts: [String]
        let tokenIndex: [String: [Int]]
        let pageCount: Int

        if let index {
            pageTexts = index.pageTexts
            tokenIndex = index.tokenIndex
            pageCount = index.pageCount
        } else if !partialPageTexts.isEmpty {
            pageTexts = partialPageTexts
            tokenIndex = partialTokenIndex.mapValues { Array($0) }
            pageCount = totalPageCount
        } else {
            return
        }

        let hits = await Task.detached {
            G3000SearchIndex.findHits(
                query: trimmed,
                pageTexts: pageTexts,
                tokenIndex: tokenIndex,
                pageCount: pageCount,
                limit: 200
            )
        }.value

        results = hits
        resultsCapped = hits.count >= 200
        currentResultIndex = 0
        updateSelection(document: document)
    }

    private func buildIndexIfNeeded() async {
        guard let pdfURL = G3000DocumentProvider.documentURL else { return }
        if document == nil {
            document = G3000DocumentProvider.loadDocument()
        }
        guard document != nil else { return }

        if let cached = G3000SearchIndex.loadIfValid(from: pdfURL) {
            if cached.hasUsableText {
                index = cached
                if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Task { [weak self] in
                        guard let self else { return }
                        await self.performSearch(query: self.query)
                    }
                }
                return
            }
        }

        isIndexing = true
        indexBannerVisible = true
        indexProgress = 0
        indexStatus = "Indexing in progress..."
        startIncrementalIndexing(pdfURL: pdfURL)
    }

    private func updateSelection(document: PDFDocument) {
        guard results.indices.contains(currentResultIndex) else {
            currentSelection = nil
            currentHighlight = []
            return
        }

        let hit = results[currentResultIndex]
        guard let page = document.page(at: hit.pageIndex),
              let selection = page.selection(for: hit.range) else {
            currentSelection = nil
            currentHighlight = []
            return
        }

        currentSelection = selection
        currentHighlight = [selection]
    }

    private func startIncrementalIndexing(pdfURL: URL) {
        guard let document else { return }
        indexingTotal = document.pageCount
        indexingCurrentPage = 0
        indexingPageTexts = Array(repeating: "", count: indexingTotal)
        indexingTokenIndex = [:]
        partialPageTexts = []
        partialTokenIndex = [:]
        totalPageCount = indexingTotal
        indexDetail = ""
        processNextIndexBatch(pdfURL: pdfURL)
    }

    private func processNextIndexBatch(pdfURL: URL) {
        guard isIndexing else { return }
        guard indexingTotal > 0 else {
            finishIndexing(pdfURL: pdfURL)
            return
        }

        let end = min(indexingCurrentPage + indexingBatchSize, indexingTotal)
        for pageIndex in indexingCurrentPage..<end {
            autoreleasepool {
                if let page = document?.page(at: pageIndex) {
                    indexingPageTexts[pageIndex] = page.string ?? ""
                }
            }

            let tokens = Set(G3000SearchIndex.tokens(from: indexingPageTexts[pageIndex]))
            for token in tokens {
                indexingTokenIndex[token, default: []].insert(pageIndex)
            }
        }

        indexingCurrentPage = end
        let progressValue = Double(indexingCurrentPage) / Double(max(indexingTotal, 1))
        indexProgress = progressValue
        indexDetail = "Page \(indexingCurrentPage) of \(max(indexingTotal, 1))"
        partialPageTexts = indexingPageTexts
        partialTokenIndex = indexingTokenIndex
        totalPageCount = indexingTotal

        if indexingCurrentPage >= indexingTotal {
            finishIndexing(pdfURL: pdfURL)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                self?.processNextIndexBatch(pdfURL: pdfURL)
            }
        }
    }

    private func finishIndexing(pdfURL: URL) {
        if let built = G3000SearchIndex.build(from: indexingPageTexts, tokenIndex: indexingTokenIndex) {
            built.save(to: pdfURL)
            index = built
        }
        isIndexing = false
        indexDetail = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.indexBannerVisible = false
        }
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task { [weak self] in
                guard let self else { return }
                await self.performSearch(query: self.query)
            }
        }
    }

    private func scheduleStatusHide() {}
}

private enum G3000DocumentProvider {
    static var documentURL: URL? {
        Bundle.main.url(forResource: "M600 G3000 Pilot Guide", withExtension: "pdf")
    }

    static func loadDocument() -> PDFDocument? {
        guard let url = documentURL else { return nil }
        return PDFDocument(url: url)
    }
}

struct G3000SearchHit: Identifiable {
    let id = UUID()
    let pageIndex: Int
    let range: NSRange
    let excerpt: String
}

struct G3000OutlineItem: Identifiable {
    let id = UUID()
    let title: String
    let pageIndex: Int
    let children: [G3000OutlineItem]

    static func build(from document: PDFDocument) -> [G3000OutlineItem] {
        guard let outlineRoot = document.outlineRoot else { return [] }
        var items: [G3000OutlineItem] = []

        func buildNode(_ outline: PDFOutline) -> G3000OutlineItem? {
            let title = outline.label?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let pageIndex: Int = {
                if let page = outline.destination?.page {
                    let index = document.index(for: page)
                    if index != NSNotFound { return index }
                }
                return 0
            }()

            var children: [G3000OutlineItem] = []
            for i in 0..<outline.numberOfChildren {
                if let child = outline.child(at: i), let node = buildNode(child) {
                    children.append(node)
                }
            }

            guard !title.isEmpty else {
                return children.isEmpty ? nil : G3000OutlineItem(title: "Section", pageIndex: pageIndex, children: children)
            }

            return G3000OutlineItem(title: title, pageIndex: pageIndex, children: children)
        }

        for i in 0..<outlineRoot.numberOfChildren {
            if let child = outlineRoot.child(at: i), let node = buildNode(child) {
                items.append(node)
            }
        }

        return items.filter { titleIsSection($0.title) }
    }

    private static func titleIsSection(_ title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed.lowercased().hasPrefix("section")
    }
}

struct G3000TableOfContentsView: View {
    let items: [G3000OutlineItem]
    let onSelect: (Int) -> Void
    let onClose: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if items.isEmpty {
                Text("No table of contents found in this PDF.")
                    .foregroundColor(AppTheme.muted)
                    .listRowBackground(AppTheme.card)
            } else {
                ForEach(items) { item in
                    NavigationLink {
                        G3000SectionChaptersView(title: item.title, items: item.children, onSelect: onSelect)
                    } label: {
                        HStack {
                            SectionTitleView(title: item.title)
                            Spacer()
                            Text("Pg \(item.pageIndex + 1)")
                                .font(.custom("Avenir Next Regular", size: 12))
                                .foregroundColor(AppTheme.muted)
                        }
                    }
                    .listRowBackground(AppTheme.card)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(InstrumentBackground().ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .navigationTitle("Table of Contents")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    onClose()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
    }
}

struct G3000SectionChaptersView: View {
    let title: String
    let items: [G3000OutlineItem]
    let onSelect: (Int) -> Void

    var body: some View {
        List {
            if items.isEmpty {
                Text("No sections found.")
                    .foregroundColor(AppTheme.muted)
                    .listRowBackground(AppTheme.card)
            } else {
                ForEach(items) { item in
                    Button {
                        onSelect(item.pageIndex)
                    } label: {
                        HStack {
                            SectionTitleView(title: item.title)
                            Spacer()
                            Text("Pg \(item.pageIndex + 1)")
                                .font(.custom("Avenir Next Regular", size: 12))
                                .foregroundColor(AppTheme.muted)
                        }
                    }
                    .listRowBackground(AppTheme.card)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(InstrumentBackground().ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .navigationTitle(title)
    }
}

private struct SectionTitleView: View {
    let title: String

    var body: some View {
        if let split = splitTitle(title) {
            HStack(spacing: 8) {
                Text(split.prefix)
                    .font(.custom("Avenir Next Demi Bold", size: 14))
                    .foregroundColor(AppTheme.text)
                    .frame(width: 86, alignment: .leading)
                if let colored = emergencySuffix(split.suffix) {
                    Text(colored.leading)
                        .font(.custom("Avenir Next Regular", size: 14))
                        .foregroundColor(AppTheme.text)
                    Text(colored.emergency)
                        .font(.custom("Avenir Next Regular", size: 14))
                        .foregroundColor(Color(red: 1.0, green: 0.28, blue: 0.28))
                    if !colored.trailing.isEmpty {
                        Text(colored.trailing)
                            .font(.custom("Avenir Next Regular", size: 14))
                            .foregroundColor(AppTheme.text)
                    }
                } else {
                    Text(split.suffix)
                        .font(.custom("Avenir Next Regular", size: 14))
                        .foregroundColor(AppTheme.text)
                }
            }
        } else {
            Text(title)
                .font(.custom("Avenir Next Regular", size: 14))
                .foregroundColor(AppTheme.text)
        }
    }

    private func splitTitle(_ title: String) -> (prefix: String, suffix: String)? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let range = trimmed.range(of: " - ") ?? trimmed.range(of: " – ") {
            let prefix = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            let suffix = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if !prefix.isEmpty, !suffix.isEmpty {
                return (prefix, suffix)
            }
        }

        let parts = trimmed.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        if parts.count >= 2 {
            let first = String(parts[0])
            let second = String(parts[1])
            if first.lowercased() == "section" {
                let suffix = parts.dropFirst(2).joined(separator: " ")
                if !suffix.isEmpty {
                    return ("Section \(second)", suffix)
                }
            } else if Int(first) != nil {
                let suffix = parts.dropFirst(1).joined(separator: " ")
                if !suffix.isEmpty {
                    return ("Section \(first)", suffix)
                }
            }
        }

        return nil
    }

    private func emergencySuffix(_ text: String) -> (leading: String, emergency: String, trailing: String)? {
        let target = "Emergency Procedures"
        if let range = text.range(of: target) {
            let leading = String(text[..<range.lowerBound])
            let trailing = String(text[range.upperBound...])
            return (leading, target, trailing)
        }
        return nil
    }
}

private struct G3000SearchIndex: Codable {
    let version: Int
    let pageCount: Int
    let pdfFileSize: UInt64
    let pageTexts: [String]
    let tokenIndex: [String: [Int]]

    var hasUsableText: Bool {
        let sampleCount = min(pageTexts.count, 25)
        let sample = pageTexts.prefix(sampleCount).joined()
        return sample.trimmingCharacters(in: .whitespacesAndNewlines).count > 50
    }

    static func loadIfValid(from pdfURL: URL) -> G3000SearchIndex? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: pdfURL.path),
              let fileSize = attributes[.size] as? UInt64 else {
            return nil
        }

        guard let data = try? Data(contentsOf: G3000IndexCache.url),
              let cached = try? JSONDecoder().decode(G3000SearchIndex.self, from: data) else {
            return nil
        }

        guard cached.pdfFileSize == fileSize else { return nil }
        return cached
    }

    func save(to pdfURL: URL) {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: pdfURL.path),
              let fileSize = attributes[.size] as? UInt64 else {
            return
        }

        let updated = G3000SearchIndex(
            version: version,
            pageCount: pageCount,
            pdfFileSize: fileSize,
            pageTexts: pageTexts,
            tokenIndex: tokenIndex
        )

        guard let data = try? JSONEncoder().encode(updated) else { return }
        try? data.write(to: G3000IndexCache.url, options: [.atomic])
    }

    static func findHits(
        query: String,
        pageTexts: [String],
        tokenIndex: [String: [Int]],
        pageCount: Int,
        limit: Int
    ) -> [G3000SearchHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let tokens = tokens(from: trimmed)
        let candidatePages = pages(matching: tokens, tokenIndex: tokenIndex, pageCount: pageCount)

        var results: [G3000SearchHit] = []
        for pageIndex in candidatePages {
            guard pageTexts.indices.contains(pageIndex) else { continue }
            let pageText = pageTexts[pageIndex]
            var searchRange = pageText.startIndex..<pageText.endIndex

            while let range = pageText.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive], range: searchRange) {
                let nsRange = NSRange(range, in: pageText)
                let excerpt = makeExcerpt(from: pageText, matchRange: range)
                results.append(
                    G3000SearchHit(
                        pageIndex: pageIndex,
                        range: nsRange,
                        excerpt: excerpt
                    )
                )
                if results.count >= limit {
                    return results
                }
                searchRange = range.upperBound..<pageText.endIndex
            }
        }

        return results
    }

    private static func makeExcerpt(from text: String, matchRange: Range<String.Index>) -> String {
        let radius = 48
        let start = text.index(matchRange.lowerBound, offsetBy: -radius, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(matchRange.upperBound, offsetBy: radius, limitedBy: text.endIndex) ?? text.endIndex
        var snippet = String(text[start..<end])
        snippet = snippet.replacingOccurrences(of: "\n", with: " ")
        snippet = snippet.replacingOccurrences(of: "\t", with: " ")
        while snippet.contains("  ") {
            snippet = snippet.replacingOccurrences(of: "  ", with: " ")
        }
        return snippet.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func pages(matching tokens: [String], tokenIndex: [String: [Int]], pageCount: Int) -> [Int] {
        guard !tokens.isEmpty else {
            return Array(0..<pageCount)
        }

        var candidate: Set<Int>?
        for token in tokens {
            guard let pages = tokenIndex[token] else {
                return []
            }
            let pageSet = Set(pages)
            if let existing = candidate {
                candidate = existing.intersection(pageSet)
            } else {
                candidate = pageSet
            }
        }

        return (candidate ?? []).sorted()
    }

    static func build(from pageTexts: [String], progress: @escaping (Double) -> Void) -> G3000SearchIndex? {
        let total = pageTexts.count
        guard total > 0 else { return nil }

        var tokenIndex: [String: Set<Int>] = [:]

        for pageIndex in 0..<total {
            let text = pageTexts[pageIndex]
            let tokens = Set(tokens(from: text))
            for token in tokens {
                if tokenIndex[token] != nil {
                    tokenIndex[token]?.insert(pageIndex)
                } else {
                    tokenIndex[token] = [pageIndex]
                }
            }

            if pageIndex % 10 == 0 || pageIndex == total - 1 {
                let progressValue = Double(pageIndex + 1) / Double(total)
                progress(progressValue)
            }
        }

        var compactIndex: [String: [Int]] = [:]
        compactIndex.reserveCapacity(tokenIndex.count)
        for (token, pages) in tokenIndex {
            compactIndex[token] = pages.sorted()
        }

        return G3000SearchIndex(
            version: 1,
            pageCount: total,
            pdfFileSize: 0,
            pageTexts: pageTexts,
            tokenIndex: compactIndex
        )
    }

    static func build(from pageTexts: [String], tokenIndex: [String: Set<Int>]) -> G3000SearchIndex? {
        let total = pageTexts.count
        guard total > 0 else { return nil }

        var compactIndex: [String: [Int]] = [:]
        compactIndex.reserveCapacity(tokenIndex.count)
        for (token, pages) in tokenIndex {
            compactIndex[token] = pages.sorted()
        }

        return G3000SearchIndex(
            version: 1,
            pageCount: total,
            pdfFileSize: 0,
            pageTexts: pageTexts,
            tokenIndex: compactIndex
        )
    }

    static func tokens(from text: String) -> [String] {
        let lowered = text.lowercased()
        let scalars = lowered.unicodeScalars
        var tokens: [String] = []
        var current = ""

        for scalar in scalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                current.unicodeScalars.append(scalar)
            } else if !current.isEmpty {
                tokens.append(current)
                current = ""
            }
        }

        if !current.isEmpty {
            tokens.append(current)
        }

        return tokens
    }

}

private struct G3000FullScreenView: View {
    let document: PDFDocument?
    let highlightedSelections: [PDFSelection]
    let currentSelection: PDFSelection?
    @Binding var currentPageIndex: Int
    @Binding var pageCount: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            InstrumentBackground()
                .ignoresSafeArea()

            PDFKitView(
                document: document,
                highlightedSelections: highlightedSelections,
                currentSelection: currentSelection,
                currentPageIndex: $currentPageIndex,
                pageCount: $pageCount
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppTheme.accent)
                }
                .accessibilityLabel("Back")
            }
        }
    }
}

private struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument?
    let highlightedSelections: [PDFSelection]
    let currentSelection: PDFSelection?
    @Binding var currentPageIndex: Int
    @Binding var pageCount: Int

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true, withViewOptions: nil)
        pdfView.displaysPageBreaks = true
        pdfView.backgroundColor = UIColor.clear
        pdfView.document = document
        context.coordinator.attach(to: pdfView)
        if let doc = document {
            DispatchQueue.main.async {
                pageCount = max(doc.pageCount, 1)
            }
        }
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document !== document {
            pdfView.document = document
            if let doc = document {
                DispatchQueue.main.async {
                    pageCount = max(doc.pageCount, 1)
                }
            }
        }

        pdfView.highlightedSelections = highlightedSelections

        if let selection = currentSelection {
            pdfView.currentSelection = selection
            pdfView.go(to: selection)
        }

        if let doc = pdfView.document, currentPageIndex < doc.pageCount {
            let target = doc.page(at: currentPageIndex)
            if target != pdfView.currentPage, let target {
                DispatchQueue.main.async {
                    pdfView.go(to: target)
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(currentPageIndex: $currentPageIndex, pageCount: $pageCount)
    }

    final class Coordinator: NSObject {
        private let currentPageIndex: Binding<Int>
        private let pageCount: Binding<Int>
        private weak var pdfView: PDFView?

        init(currentPageIndex: Binding<Int>, pageCount: Binding<Int>) {
            self.currentPageIndex = currentPageIndex
            self.pageCount = pageCount
        }

        func attach(to pdfView: PDFView) {
            self.pdfView = pdfView
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(pageChanged),
                name: Notification.Name.PDFViewPageChanged,
                object: pdfView
            )
        }

        @objc private func pageChanged() {
            guard let pdfView, let doc = pdfView.document, let page = pdfView.currentPage else { return }
            let index = doc.index(for: page)
            if index != NSNotFound {
                DispatchQueue.main.async {
                    self.currentPageIndex.wrappedValue = index
                    self.pageCount.wrappedValue = max(doc.pageCount, 1)
                }
            }
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}
