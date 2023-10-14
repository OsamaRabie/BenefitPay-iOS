//
//  TapBenefitPayView.swift
//  
//
//  Created by Osama Rabie on 05/10/2023.
//

import UIKit
import WebKit
import SwiftEntryKit
import SharedDataModels_iOS

/// The custom view that provides an interface for the  benefit pay button
@objc public class BenefitPayButton: UIView {
    /// The scheme prefix used as aprotocol between the web view and the native part
    let tapBenefitWebSDKUrlScheme:String = "tapbenefitpaywebsdk://"
    /// The scheme prefix used by benefit pay sdk to show the benefit pay popup
    let benefitSDKUrlScheme:String = "https://benefit-checkout"
    /// The scheme prefix used by benefit pay sdk to show the benefit pay popup
    let benefitPayAppUrlScheme:String = "https://tbenefituser.page"
    /// The web view used to render the benefit pay button
    internal var webView: WKWebView = .init()
    /// A protocol that allows integrators to get notified from events fired from benefit pay button
    internal var delegate: BenefitPayButtonDelegate?
    /// Defines the base url for the benefit pay sdk
    internal static let benefitPayButtonBaseUrl:String = "https://button.dev.tap.company/wrapper/benefitpay?configurations="
    /// keeps a hold of the loaded web sdk configurations url
    internal var currentlyLoadedCardConfigurations:URL?
    /// Keeps a reference to whether or not we should handle the on cancel because it comes directly after onSuccess
    internal var handleOnCancel:Bool = true
    /// Keeps a reference to the gif loader we will display when coming back from pay with benefit pay app
    internal var benefitGifLoader:UIImageView?
    /// The headers encryption key
    internal var headersEncryptionPublicKey:String {
        if getBenefitPaySDKKey().contains("test") {
            return """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC8AX++RtxPZFtns4XzXFlDIxPB
h0umN4qRXZaKDIlb6a3MknaB7psJWmf2l+e4Cfh9b5tey/+rZqpQ065eXTZfGCAu
BLt+fYLQBhLfjRpk8S6hlIzc1Kdjg65uqzMwcTd0p7I4KLwHk1I0oXzuEu53fU1L
SZhWp4Mnd6wjVgXAsQIDAQAB
-----END PUBLIC KEY-----
"""
        }else{
            return """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC9hSRms7Ir1HmzdZxGXFYgmpi3
ez7VBFje0f8wwrxYS9oVoBtN4iAt0DOs3DbeuqtueI31wtpFVUMGg8W7R0SbtkZd
GzszQNqt/wyqxpDC9q+97XdXwkWQFA72s76ud7eMXQlsWKsvgwhY+Ywzt0KlpNC3
Hj+N6UWFOYK98Xi+sQIDAQAB
-----END PUBLIC KEY-----
"""
        }
    }
    
    //MARK: - Init methods
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    //MARK: - Private methods
    /// Used as a consolidated method to do all the needed steps upon creating the view
    private func commonInit() {
        // Setuo the web view contais the web sdk
        setupWebView()
        // setup the constraint to put each view in its correct positiob
        setupConstraints()
        // we will need to be notified when the user moves outside the app, to move him back to the benefitpay popup
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovingTForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    /// A notificationfunction will be called once the app is moved to backgorund
    /// We will need to show back the benefitpay button, this will only be fired, if the user is showing the middle page that displays the benefitpay app afterwards
    @objc private func appMovingTForeground() {
        // Now let us check if the benefitpay app popup is displayed
        if SwiftEntryKit.isCurrentlyDisplaying(entryNamed: "TapBenefitPayEntry") {
            // let us close it and display the benefitay pay popup again
            removeBenefitPayAppEntry()
        }
    }
    
    /// Used to open a url inside the Tap card web sdk.
    /// - Parameter url: The url needed to load.
    internal func openUrl(url: URL?) {
        // Store it for further usages
        currentlyLoadedCardConfigurations = url
        handleOnCancel = true
        // instruct the web view to load the needed url
        let request = URLRequest(url: url!)
        
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.load(request)
    }
    
    /// used to setup the constraint of the Tap card sdk view
    private func setupWebView() {
        // Creates needed configuration for the web view
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        let configuration = WKWebViewConfiguration()
        
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        // Let us make sure it is of a clear background and opaque, not to interfer with the merchant's app background
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear
        webView.scrollView.bounces = false
        webView.isHidden = false
        // Let us add it to the view
        self.backgroundColor = .clear
        self.addSubview(webView)
        
        benefitGifLoader = benefitPayLoaderGif()
    }
    
    /// Setup Constaraints for the sub views.
    private func setupConstraints() {
        // Preprocessing needed setup
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Define the web view constraints
        let top  = webView.topAnchor.constraint(equalTo: self.topAnchor)
        let left = webView.leftAnchor.constraint(equalTo: self.leftAnchor)
        let right = webView.rightAnchor.constraint(equalTo: self.rightAnchor)
        let bottom = webView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        let buttonHeight = self.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        
        
        // Activate the constraints
        NSLayoutConstraint.activate([left, right, top, bottom, buttonHeight])
    }
    
    /// Will add the web view again to the normal view after removing it from the popup screen we presented to show the benefitpay popup
    internal func addWebViewToContainerView() {
        DispatchQueue.main.async {
            self.webView.removeFromSuperview()
            self.addSubview(self.webView)
            self.setupConstraints()
        }
    }
    
    /// A function responsible for closing the pay with benefitpay app popup and displays back the beneftpay QR code popup
    internal func removeBenefitPayAppEntry() {
        // First let us check that when the user left the app, he was at the BenefitPayAPp redirection page
        guard SwiftEntryKit.isCurrentlyDisplaying(entryNamed: "TapBenefitPayEntry") else { return } // nothing to do
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.webView.alpha = 1
            // Now, because the user left the app from BenefitPayApp redirection, we need to:
            // 1. Show back the benefit pay QR popup
            // 2. Display a loader for 5 seconds to allow listening to teh charge status change (if any) from
            SwiftEntryKit.dismiss(.specific(entryName: "TapBenefitPayEntry")) {
                // Show the QR original popup
                self.webView.alpha = 1
                let view:UIView = self.createBenefitPayPopUpView()
                self.webView.isHidden = false
                self.webView.isUserInteractionEnabled = false
                self.benefitGifLoader?.isHidden = false
                SwiftEntryKit.display(entry: view, using: self.entryAttributes(intoAnimation: false))
                // Hide the loader after 4 seconds, if nothing happened meaning, no charge updates
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                    self.benefitGifLoader?.isHidden = true
                    self.webView.isUserInteractionEnabled = true
                }
            }
        }
    }
    
    
    /// Call it when you want to remove the benefitpay entry and get back to the merchant app
    /// - Parameter shouldStopOnCancel: Whether or not, we should listen to the onCancel coming after this event or not.
    internal func removeBenefitPayPopupEntry(handleOnCancel:Bool = false,  onDismiss:@escaping()->()) {
        self.handleOnCancel = handleOnCancel
        webView.isHidden = false
        self.addWebViewToContainerView()
        benefitGifLoader?.isHidden = true
        SwiftEntryKit.dismiss{
            onDismiss()
        }
    }
    
    
    //MARK: - Public init methods
    ///  configures the benefit pay button with the needed configurations for it to work
    ///  - Parameter config: The configurations dctionary. Recommended, as it will make you able to customly add models without updating
    ///  - Parameter delegate:A protocol that allows integrators to get notified from events fired from benefit pay button
    @objc public func initBenefitPayButton(configDict: [String : Any], delegate: BenefitPayButtonDelegate? = nil) {
        self.delegate = delegate
        //let operatorModel:Operator = .init(publicKey: configDict["publicKey"] as? String ?? "", metadata: generateApplicationHeader())
        var updatedConfigurations:[String:Any] = configDict
        
        
        do {
            currentlyLoadedCardConfigurations = try URL(string:generateTapBenefitPaySdkURL(from: updatedConfigurations)) ?? nil
            updatedConfigurations["headers"] = generateApplicationHeader()
            try openUrl(url: URL(string: generateTapBenefitPaySdkURL(from: updatedConfigurations)))
        }
        catch {
            self.delegate?.onError?(data: "{error:\(error.localizedDescription)}")
        }
    }
}
