import SwiftUI
import WebKit
import UIKit

@main
struct HoshimimiApp: App {
    var body: some Scene {
        WindowGroup { LocalGameView().ignoresSafeArea() }
    }
}

struct LocalGameView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // Default data store keeps localStorage across normal application launches.
        configuration.websiteDataStore = .default()
        configuration.userContentController.add(context.coordinator, name: "exportSave")
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.isOpaque = false
        view.backgroundColor = .black
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.navigationDelegate = context.coordinator
        context.coordinator.webView = view
        if let index = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Web") {
            view.loadFileURL(index, allowingReadAccessTo: index.deletingLastPathComponent())
        } else {
            view.loadHTMLString("<meta name='viewport' content='width=device-width'><p>ゲームデータがありません。ビルド時に dist を同梱してください。</p>", baseURL: nil)
        }
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "exportSave")
        uiView.navigationDelegate = nil
    }
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        weak var webView: WKWebView?

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard message.name == "exportSave", message.frameInfo.isMainFrame,
                  let json = message.body as? String,
                  let data = json.data(using: .utf8), data.count <= 1_048_576,
                  (try? JSONSerialization.jsonObject(with: data)) is [String: Any] else { return }
            DispatchQueue.main.async { [weak self] in self?.shareSave(data) }
        }

        private func shareSave(_ data: Data) {
            guard let view = webView, let root = view.window?.rootViewController else { return }
            var presenter = root
            while let presented = presenter.presentedViewController { presenter = presented }
            guard !(presenter is UIActivityViewController) else { return }
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            let file = directory.appendingPathComponent("hoshimimi-save.json")
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try data.write(to: file, options: .atomic)
            } catch {
                let alert = UIAlertController(title: "保存できませんでした", message: "もう一度お試しください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "閉じる", style: .default))
                presenter.present(alert, animated: true)
                return
            }
            let share = UIActivityViewController(activityItems: [file], applicationActivities: nil)
            share.completionWithItemsHandler = { _, _, _, _ in
                try? FileManager.default.removeItem(at: directory)
            }
            if let popover = share.popoverPresentationController {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
                popover.permittedArrowDirections = []
            }
            presenter.present(share, animated: true)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // The bundled game needs no external navigation or arbitrary network content.
            guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
            decisionHandler(url.isFileURL || url.scheme == "about" ? .allow : .cancel)
        }
    }
}
