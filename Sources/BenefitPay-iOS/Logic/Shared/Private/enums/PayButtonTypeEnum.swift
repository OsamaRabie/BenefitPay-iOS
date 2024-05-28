//
//  File.swift
//  
//
//  Created by Osama Rabie on 26/10/2023.
//

import Foundation

/// Defines which type of buttons to be displayed
@objc public enum PayButtonTypeEnum:Int, CaseIterable {
    /// The button will work to show payment in form of BenefitPay
    case BenefitPay
    
    /// A string representation of the payment type
    public func toString() -> String {
        switch self {
        case .BenefitPay:
            return "BENEFITPAY"
        }
    }
    
    /// Will define the base url for the payment type
    internal func baseUrl() -> String {
        switch self {
        case .BenefitPay:
            return "https://button.dev.tap.company/wrapper/v1/benefitpay?configurations="
        }
    }
    
    /// Will define the scheme will be used by the original web sdk to communicate with the native view
    internal func webSdkScheme() -> String {
        switch self {
        case .BenefitPay:
            return "tapbenefitpaywebsdk://"
        }
    }
    
    /// The string that we will use to tell the backend which url it should redirect to upin finishing a redirection based payment
    internal func tapRedirectionSchemeUrl() -> String {
        return "tapredirectionwebsdk://"
    }
}
