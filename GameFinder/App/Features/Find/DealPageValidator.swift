//
//  DealPageValidator.swift
//  GameFinder
//
//  Created by Claude on 3/12/26.
//

import UIKit
import WebKit

final class DealPageValidator: NSObject {

    private var webView: WKWebView?
    private var completion: ((_ isAvailable: Bool) -> Void)?
    private var timeoutWorkItem: DispatchWorkItem?

    /// redirect URL의 최종 페이지를 WKWebView로 로드하여 JS 렌더링 후 이용 불가 패턴을 감지
    func validate(url: URL, in parentView: UIView, completion: @escaping (_ isAvailable: Bool) -> Void) {
        self.completion = completion

        let webView = WKWebView(frame: .zero)
        webView.isHidden = true
        webView.navigationDelegate = self
        parentView.addSubview(webView)
        self.webView = webView

        // 12초 타임아웃 — 초과 시 Safari로 직접 이동
        let timeout = DispatchWorkItem { [weak self] in
            self?.finish(isAvailable: true)
        }
        timeoutWorkItem = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 12, execute: timeout)

        webView.load(URLRequest(url: url, timeoutInterval: 10))
    }

    private func checkPageContent() {
        guard let webView else {
            finish(isAvailable: true)
            return
        }

        webView.evaluateJavaScript("document.body ? document.body.innerText : ''") { [weak self] result, _ in
            guard let self, let text = result as? String else {
                self?.finish(isAvailable: true)
                return
            }

            let lowered = text.lowercased()
            let unavailablePatterns = [
                "currently unavailable in your platform or region",
                "this content is currently unavailable",
                "this page could not be found",
                "no longer available"
            ]
            let isUnavailable = unavailablePatterns.contains { lowered.contains($0) }
            self.finish(isAvailable: !isUnavailable)
        }
    }

    private func finish(isAvailable: Bool) {
        guard completion != nil else { return }
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView?.removeFromSuperview()
        webView = nil
        let cb = completion
        completion = nil
        cb?(isAvailable)
    }
}

extension DealPageValidator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // JS 렌더링 완료 대기 후 페이지 텍스트 확인
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.checkPageContent()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(isAvailable: true)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finish(isAvailable: true)
    }
}
