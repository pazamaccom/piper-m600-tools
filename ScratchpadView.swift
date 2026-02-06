import SwiftUI
import PencilKit

enum ScratchpadToolMode {
    case pen
    case eraser
}

struct ScratchpadView: View {
    @AppStorage("scratchpadDrawing") private var legacyScratchpadDrawing: String = ""
    @AppStorage("scratchpadPages") private var scratchpadPagesStorage: String = ""
    @State private var toolMode: ScratchpadToolMode = .pen
    @State private var clearTrigger: Int = 0
    @State private var undoTrigger: Int = 0
    @State private var redoTrigger: Int = 0
    @State private var inkColor: Color = .white
    @State private var lineWidth: CGFloat = 3
    @State private var canUndo: Bool = false
    @State private var canRedo: Bool = false
    @State private var pages: [String] = []
    @State private var currentPageIndex: Int = 0
    @State private var currentDrawing: String = ""
    @State private var showClearConfirm = false
    @State private var showDeletePageConfirm = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss

    private var isPadLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ZStack {
            InstrumentBackground()
                .ignoresSafeArea()

            VStack(spacing: isPadLayout ? 14 : 8) {
                settingsBar
                canvasCard
            }
            .padding(isPadLayout ? 18 : 12)
        }
        .navigationTitle("")
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
            ToolbarItem(placement: .navigationBarTrailing) {
                toolBarCompact
            }
        }
        .alert("Clear this page?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                currentDrawing = ""
                clearTrigger += 1
            }
        } message: {
            Text("This will erase all marks on the current page.")
        }
        .alert("Delete this page?", isPresented: $showDeletePageConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteCurrentPage()
            }
        } message: {
            Text("This removes the current page from the scratchpad.")
        }
        .onAppear {
            loadPagesIfNeeded()
        }
        .onChange(of: currentDrawing) { newValue in
            guard pages.indices.contains(currentPageIndex) else { return }
            pages[currentPageIndex] = newValue
            persistPages()
        }
    }

    private var toolBarCompact: some View {
        HStack(spacing: isPadLayout ? 10 : 8) {
            ToolButton(
                title: "",
                systemImage: "pencil.tip",
                isActive: toolMode == .pen
            ) {
                toolMode = .pen
            }

            ToolButton(
                title: "",
                systemImage: "eraser",
                isActive: toolMode == .eraser
            ) {
                toolMode = .eraser
            }

            IconToolButton(
                title: "Undo",
                systemImage: "arrow.uturn.backward",
                isEnabled: canUndo
            ) {
                undoTrigger += 1
            }

            IconToolButton(
                title: "Redo",
                systemImage: "arrow.uturn.forward",
                isEnabled: canRedo
            ) {
                redoTrigger += 1
            }

            Spacer(minLength: isPadLayout ? 12 : 8)

            IconToolButton(
                title: "",
                systemImage: "eraser.fill",
                isEnabled: true
            ) {
                showClearConfirm = true
            }
        }
    }

    private var settingsBar: some View {
        HStack(spacing: isPadLayout ? 12 : 8) {
            Button {
                goToPreviousPage()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(canGoPrevious ? AppTheme.text : AppTheme.muted)
            }
            .buttonStyle(.plain)
            .disabled(!canGoPrevious)

            Text("Page \(currentPageIndex + 1)/\(max(pages.count, 1))")
                .font(.custom("Avenir Next Regular", size: isPadLayout ? 13 : 9))
                .foregroundColor(AppTheme.muted)

            Button {
                goToNextPage()
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(canGoNext ? AppTheme.text : AppTheme.muted)
            }
            .buttonStyle(.plain)
            .disabled(!canGoNext)

            Button {
                addPage()
            } label: {
                Image(systemName: "plus.square.on.square")
                    .foregroundColor(AppTheme.text)
            }
            .buttonStyle(.plain)

            Button {
                showDeletePageConfirm = true
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(AppTheme.text)
            }
            .buttonStyle(.plain)

            Spacer()

            ColorPicker("Ink", selection: $inkColor)
                .labelsHidden()
                .frame(width: 28, height: 24)

            Text("Width")
                .font(.custom("Avenir Next Regular", size: isPadLayout ? 13 : 9))
                .foregroundColor(AppTheme.muted)

            Slider(value: $lineWidth, in: 0.1...12, step: 0.1)
                .tint(AppTheme.accent)

            Text(String(format: "%.1f", lineWidth))
                .font(.custom("Avenir Next Regular", size: isPadLayout ? 13 : 9))
                .foregroundColor(AppTheme.muted)
                .frame(width: 30, alignment: .trailing)
        }
    }

    private var canvasCard: some View {
        PencilCanvasView(
            toolMode: $toolMode,
            clearTrigger: $clearTrigger,
            undoTrigger: $undoTrigger,
            redoTrigger: $redoTrigger,
            inkColor: $inkColor,
            lineWidth: $lineWidth,
            serializedDrawing: $currentDrawing,
            canUndo: $canUndo,
            canRedo: $canRedo
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
    }

    private var canGoPrevious: Bool {
        currentPageIndex > 0
    }

    private var canGoNext: Bool {
        currentPageIndex + 1 < pages.count
    }

    private func loadPagesIfNeeded() {
        if let stored = ScratchpadPages.decode(from: scratchpadPagesStorage), !stored.isEmpty {
            pages = stored
        } else if !legacyScratchpadDrawing.isEmpty {
            pages = [legacyScratchpadDrawing]
            scratchpadPagesStorage = ScratchpadPages.encode(pages)
        } else {
            pages = [""]
        }
        currentPageIndex = min(currentPageIndex, max(pages.count - 1, 0))
        currentDrawing = pages[currentPageIndex]
    }

    private func persistPages() {
        scratchpadPagesStorage = ScratchpadPages.encode(pages)
    }

    private func goToPreviousPage() {
        guard canGoPrevious else { return }
        currentPageIndex -= 1
        currentDrawing = pages[currentPageIndex]
    }

    private func goToNextPage() {
        guard canGoNext else { return }
        currentPageIndex += 1
        currentDrawing = pages[currentPageIndex]
    }

    private func addPage() {
        pages.append("")
        currentPageIndex = pages.count - 1
        currentDrawing = pages[currentPageIndex]
        persistPages()
    }

    private func deleteCurrentPage() {
        guard !pages.isEmpty else { return }
        if pages.count == 1 {
            pages[0] = ""
            currentDrawing = ""
            persistPages()
            return
        }
        pages.remove(at: currentPageIndex)
        currentPageIndex = min(currentPageIndex, pages.count - 1)
        currentDrawing = pages[currentPageIndex]
        persistPages()
    }
}

private struct ToolButton: View {
    let title: String
    let systemImage: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isActive ? .black : AppTheme.text)
                .frame(width: 36, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isActive ? AppTheme.accent : AppTheme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.accentSoft, lineWidth: isActive ? 0 : 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

private struct IconToolButton: View {
    let title: String
    let systemImage: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isEnabled ? AppTheme.text : AppTheme.muted)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.accentSoft, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(title.isEmpty ? systemImage : title)
    }
}

private struct PencilCanvasView: UIViewRepresentable {
    @Binding var toolMode: ScratchpadToolMode
    @Binding var clearTrigger: Int
    @Binding var undoTrigger: Int
    @Binding var redoTrigger: Int
    @Binding var inkColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var serializedDrawing: String
    @Binding var canUndo: Bool
    @Binding var canRedo: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.tool = penTool
        canvasView.delegate = context.coordinator
        context.coordinator.attach(canvasView)
        context.coordinator.lastClearTrigger = clearTrigger
        context.coordinator.lastUndoTrigger = undoTrigger
        context.coordinator.lastRedoTrigger = redoTrigger
        context.coordinator.lastSerializedDrawing = serializedDrawing
        if let restored = loadDrawing() {
            canvasView.drawing = restored
        }
        updateUndoRedoState(canvasView)
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.tool = (toolMode == .pen) ? penTool : eraserTool

        if context.coordinator.lastClearTrigger != clearTrigger {
            uiView.drawing = PKDrawing()
            context.coordinator.lastClearTrigger = clearTrigger
            context.coordinator.lastSerializedDrawing = ""
            updateUndoRedoState(uiView)
        }

        if context.coordinator.lastUndoTrigger != undoTrigger {
            uiView.undoManager?.undo()
            context.coordinator.lastUndoTrigger = undoTrigger
            updateUndoRedoState(uiView)
        }

        if context.coordinator.lastRedoTrigger != redoTrigger {
            uiView.undoManager?.redo()
            context.coordinator.lastRedoTrigger = redoTrigger
            updateUndoRedoState(uiView)
        }

        if context.coordinator.lastSerializedDrawing != serializedDrawing {
            if let restored = loadDrawing() {
                uiView.drawing = restored
            } else {
                uiView.drawing = PKDrawing()
            }
            context.coordinator.lastSerializedDrawing = serializedDrawing
            updateUndoRedoState(uiView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            serializedDrawing: $serializedDrawing,
            canUndo: $canUndo,
            canRedo: $canRedo
        )
    }

    private var penTool: PKInkingTool {
        let scaled = max(0.1, min(12, lineWidth))
        return PKInkingTool(.pen, color: UIColor(inkColor), width: scaled)
    }

    private var eraserTool: PKEraserTool {
        PKEraserTool(.vector)
    }

    private func loadDrawing() -> PKDrawing? {
        guard let data = Data(base64Encoded: serializedDrawing) else { return nil }
        return try? PKDrawing(data: data)
    }

    private func updateUndoRedoState(_ view: PKCanvasView) {
        let undoAvailable = view.undoManager?.canUndo ?? false
        let redoAvailable = view.undoManager?.canRedo ?? false
        if canUndo != undoAvailable {
            DispatchQueue.main.async {
                canUndo = undoAvailable
            }
        }
        if canRedo != redoAvailable {
            DispatchQueue.main.async {
                canRedo = redoAvailable
            }
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var lastClearTrigger: Int = 0
        var lastUndoTrigger: Int = 0
        var lastRedoTrigger: Int = 0
        var lastSerializedDrawing: String = ""
        private weak var canvasView: PKCanvasView?
        private let serializedDrawing: Binding<String>
        private let canUndo: Binding<Bool>
        private let canRedo: Binding<Bool>

        init(serializedDrawing: Binding<String>, canUndo: Binding<Bool>, canRedo: Binding<Bool>) {
            self.serializedDrawing = serializedDrawing
            self.canUndo = canUndo
            self.canRedo = canRedo
        }

        func attach(_ view: PKCanvasView) {
            canvasView = view
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let data = canvasView.drawing.dataRepresentation()
            let encoded = data.base64EncodedString()
            DispatchQueue.main.async {
                if let view = self.canvasView {
                    let undoAvailable = view.undoManager?.canUndo ?? false
                    let redoAvailable = view.undoManager?.canRedo ?? false
                    self.lastSerializedDrawing = encoded
                    self.serializedDrawing.wrappedValue = encoded
                    self.canUndo.wrappedValue = undoAvailable
                    self.canRedo.wrappedValue = redoAvailable
                }
            }
        }
    }
}

private enum ScratchpadPages {
    static func decode(from storage: String) -> [String]? {
        guard let data = storage.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }

    static func encode(_ pages: [String]) -> String {
        guard let data = try? JSONEncoder().encode(pages),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}
