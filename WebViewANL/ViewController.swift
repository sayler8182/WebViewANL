//
//  ViewController.swift
//  WebViewANL
//
//  Created by Konrad on 24/04/2024.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    var webView: WKWebView!
    let mockServer: MockServer = MockServer(port: 5013)

    lazy var documentPath: URL = {
        let fileManager = FileManager.default
        return try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }()
    lazy var dataPath: URL = {
        documentPath.appendingPathComponent("Folder")
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let userController = WKUserContentController()
        let consoleLog = """
            function log(emoji, type, args) {
              window.webkit.messageHandlers.logging.postMessage(
                `${emoji} JS ${type}: ${Object.values(args)
                  .map(v => typeof(v) === "undefined" ? "undefined" : typeof(v) === "object" ? JSON.stringify(v) : v.toString())
                  .map(v => v.substring(0, 3000)) // Limit msg to 3000 chars
                  .join(", ")}`
              )
            }

            let originalLog = window.console.log
            let originalWarn = window.console.warn
            let originalError = window.console.error
            let originalDebug = window.console.debug

            window.console.log = function() { log("📗", "log", arguments); originalLog.apply(null, arguments) }
            window.console.warn = function() { log("📙", "warning", arguments); originalWarn.apply(null, arguments) }
            window.console.error = function() { log("📕", "error", arguments); originalError.apply(null, arguments) }
            window.console.debug = function() { log("📘", "debug", arguments); originalDebug.apply(null, arguments) }

            window.addEventListener("error", function(e) {
               log("💥", "Uncaught", [`${e.message} at ${e.filename}:${e.lineno}:${e.colno}`])
            })
        """
        let script = WKUserScript(source: consoleLog, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        userController.addUserScript(script)
        userController.add(self, name: "logging")
        let webPageDefaultPreferences = WKWebpagePreferences()
        webPageDefaultPreferences.allowsContentJavaScript = true
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.defaultWebpagePreferences = webPageDefaultPreferences
        configuration.ignoresViewportScaleLimits = false
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        configuration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        configuration.userContentController = userController

        webView = WKWebView(
            frame: UIScreen.main.bounds,
            configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view.addSubview(webView)
        saveFiles()

        // load file://
        // loadContent()

        // start mock server
        do {
            try mockServer.start()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func saveFiles() {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: dataPath.path) {
            try! fileManager.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
        }

        let indexPath = dataPath.appendingPathComponent("index").appendingPathExtension("html")
        if !fileManager.fileExists(atPath: indexPath.path) {
            assertionFailure("Copy file to: \(dataPath)")
        }
    }

    func loadContent() {
        let indexPath = dataPath.appendingPathComponent("index").appendingPathExtension("html")
        print("Load: \(indexPath)")
        webView.loadFileURL(indexPath, allowingReadAccessTo: dataPath)
    }
}

// MARK: WKUIDelegate
extension ViewController: WKUIDelegate {
    public func webView(_ webView: WKWebView,
                        createWebViewWith configuration: WKWebViewConfiguration,
                        for navigationAction: WKNavigationAction,
                        windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
}


// MARK: WKNavigationDelegate
extension ViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView,
                        didFinish navigation: WKNavigation!) {
        print("Load success")
    }

    public func webView(_ webView: WKWebView,
                        didFailProvisionalNavigation navigation: WKNavigation!,
                        withError error: Error) {
        print("Load error: \(error.localizedDescription)")
    }
}

// MARK: WKScriptMessageHandler
extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        print("\(message.body)")
    }
}
