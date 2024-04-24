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

    lazy var dataPath: URL = {
        let fileManager = FileManager.default
        let documentDirectory = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create:false)
        return documentDirectory.appendingPathComponent("Folder")
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 320, height: 666),
            configuration: configuration)
        view.addSubview(webView)
        saveFiles()
        loadContent()
    }

    func saveFiles() {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: dataPath.path) {
            try! fileManager.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
        }

        do {
            let scriptsPath = dataPath.appendingPathComponent("scripts").appendingPathExtension("js")
            try scriptsContent.data(using: .utf8)?.write(to: scriptsPath)
            let indexPath = dataPath.appendingPathComponent("index").appendingPathExtension("html")
            try htmlContent.data(using: .utf8)?.write(to: indexPath)
            let subpagePath = dataPath.appendingPathComponent("subpage").appendingPathExtension("html")
            try subpageContent.data(using: .utf8)?.write(to: subpagePath)
            let image = UIImage(named: "download")!
            let imagePath = dataPath.appendingPathComponent("image").appendingPathExtension("png")
            try image.pngData()?.write(to: imagePath)
        } catch {
            assertionFailure(error.localizedDescription)
        }

        print("Stored in \(dataPath)")
    }

    func loadContent() {
        let indexPath = dataPath.appendingPathComponent("index").appendingPathExtension("html")
        webView.loadFileURL(indexPath, allowingReadAccessTo: dataPath)
    }
}

let scriptsContent = """
let d = new Date();
document.getElementById("main").innerHTML = "<h1>Today's date is " + d + "</h1>"
"""

let htmlContent = """
<!DOCTYPE html>
<html lang="en-US">

<body>
    <h1>Main Page</h1>
    <div id="main">
    </div>
    <img src="./image.png">
    <a href="./subpage.html">Sub Page</a>
    <script src="./scripts.js"></script>
</body>

</html>
"""

let subpageContent = """
<!DOCTYPE html>
<html lang="en-US">

<body>
    <h1>Subpage</h1>
    <div id="main">
    </div>
    <a href="./index.html">Index</a>
    <script src="./scripts.js"></script>
</body>

</html>
"""

