import SwiftUI
import PDFKit

struct DocumentPDFView: UIViewRepresentable {
    let document: PDFDocument?

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true, withViewOptions: nil)
        pdfView.displaysPageBreaks = true
        pdfView.backgroundColor = UIColor.clear
        pdfView.document = document
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document !== document {
            pdfView.document = document
        }
    }
}
