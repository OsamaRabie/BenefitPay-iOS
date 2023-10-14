//
//  TapCardView+WebDelegate.swift
//  TapCardCheckOutKit
//
//  Created by Osama Rabie on 12/09/2023.
//

import Foundation
import UIKit
import WebKit
import SharedDataModels_iOS
import SwiftEntryKit
import Robin
import UserNotifications
import UserNotificationsUI

/// An extension to take care of the notifications being sent from the web view through the url schemes
extension BenefitPayButton:WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var action: WKNavigationActionPolicy?
        
        defer {
            decisionHandler(action ?? .allow)
        }
        
        guard let url = navigationAction.request.url else { return }
        
        if url.absoluteString.hasPrefix(tapBenefitWebSDKUrlScheme) {
            print("navigationAction", url.absoluteString)
            action = .cancel
        }else{
            print("navigationAction", url.absoluteString)
        }
        // Let us see if the web sdk is telling us something
        if( url.absoluteString.contains(tapBenefitWebSDKUrlScheme)) {
            switch url.absoluteString {
            case _ where url.absoluteString.contains(TapBenefitWebCallBacksEnums.onError.rawValue):
                self.removeBenefitPayPopupEntry(handleOnCancel: false) {
                    self.webView.isHidden = false
                    self.webView.alpha = 1
                    self.delegate?.onError?(data: tap_extractDataFromUrl(url, for: "data", shouldBase64Decode: true))
                }
                break
            case _ where url.absoluteString.contains(TapBenefitWebCallBacksEnums.onOrderCreated.rawValue):
                delegate?.onOrderCreated?(data: tap_extractDataFromUrl(url, for: "data", shouldBase64Decode: false))
                break
            case _ where url.absoluteString.contains(TapBenefitWebCallBacksEnums.onChargeCreated.rawValue):
                delegate?.onChargeCreated?(data: tap_extractDataFromUrl(url, for: "data", shouldBase64Decode: true))
                break
            case _ where url.absoluteString.contains(TapBenefitWebCallBacksEnums.onSuccess.rawValue):
                
                let notificationContent = UNMutableNotificationContent()
                   notificationContent.title = "Payment updated"
                   notificationContent.body = "Return to \(Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "the app") to complete your transaction."
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5,
                                                                    repeats: false)
                    let request = UNNotificationRequest(identifier: "testNotification",
                                                        content: notificationContent,
                                                        trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { (error) in
                        if let error = error {
                            print("Notification Error: ", error)
                        }
                    }
                
                self.removeBenefitPayPopupEntry(handleOnCancel: false) {
                    self.delegate?.onSuccess?(data: tap_extractDataFromUrl(url, for: "data", shouldBase64Decode: true))
                    self.openUrl(url: self.currentlyLoadedCardConfigurations)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                        self.webView.isHidden = false
                        self.webView.alpha = 1
                    }
                }
                break
            case _ where url.absoluteString.contains(TapBenefitWebCallBacksEnums.onReady.rawValue):
                delegate?.onReady?()
                break
            case _ where url.absoluteString.contains(TapBenefitWebCallBacksEnums.onClick.rawValue):
                self.handleOnCancel = true
                delegate?.onClick?()
                break
            case _ where url.absoluteString.contains(TapBenefitWebCallBacksEnums.onCancel.rawValue):
                guard self.handleOnCancel, SwiftEntryKit.isCurrentlyDisplaying else {
                    self.handleOnCancel = true
                    return
                }
                self.removeBenefitPayPopupEntry(handleOnCancel: true) {
                    self.webView.isHidden = false
                    self.webView.alpha = 1
                    self.delegate?.onCanceled?()
                }
                break
            default:
                break
            }
        }else if url.absoluteString.hasPrefix(benefitSDKUrlScheme) {
            // This means, BenefitPay popup wil be displayed and we need to make our weview full screen
            let view:UIView = createBenefitPayPopUpView()
            self.benefitGifLoader?.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                // Use class method of SwiftEntryKit to display the view using the desired attributes
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    self.webView.isHidden = false
                    self.handleOnCancel = true
                }
                SwiftEntryKit.display(entry: view, using: self.entryAttributes())
            }
        }
    }
}



extension BenefitPayButton:WKUIDelegate {
   
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let (view,web,backButton) = createBenefitPayWithAppPopupView()
        
        if let url = navigationAction.request.url {
            web.load(navigationAction.request)
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                //self.updateLoadingView(with: false)
                web.translatesAutoresizingMaskIntoConstraints = false
                backButton.translatesAutoresizingMaskIntoConstraints = false
                webView.alpha = 0
                SwiftEntryKit.display(entry: view, using: self.entryAttributes2(introAnimation: true, exitAnimation:  true))
            }
        }
        return nil
    }
}
