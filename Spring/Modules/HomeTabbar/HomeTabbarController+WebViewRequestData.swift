//
//  HomeTabbarController+WebViewRequestData.swift
//  Spring
//
//  Created by Thuyen Truong on 2/27/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import FlexLayout
import WebKit
import RxSwift
import RxCocoa
import RxSwiftExt

extension HomeTabbarController {

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let response = navigationResponse.response as? HTTPURLResponse else { return }

        guard let contentType = response.allHeaderFields["Content-Type"] as? String,
            contentType == "application/zip",
            let cachedRequestHeader = cachedRequestHeader,
            let archiveURL = response.url
            else {
                decisionHandler(.allow)
                return
        }

        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies({ [weak self] (cookies) in
            guard let self = self else { return }
            let rawCookie = cookies.compactMap { "\($0.name)=\($0.value)" }.joined(separator: "; ")

            self.signUpAndSubmitFBArchive(headers: cachedRequestHeader, archiveURL: archiveURL, rawCookie: rawCookie)
        })

        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let url = navigationAction.request.url {
            if url.absoluteString.contains("download/file") {
                cachedRequestHeader = navigationAction.request.allHTTPHeaderFields
            } else if url.absoluteString.contains("save-device") {
                slideDown()
            }
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingState.onNext(.hide)

        // check & run JS for determined FB pages; start checking from index 0
        evaluateJS(index: 0)
    }
}
