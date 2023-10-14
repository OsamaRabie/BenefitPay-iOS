//
//  CardWebSDKExample.swift
//  TapCardCheckoutExample
//
//

import UIKit
import BenefitPay_iOS
import Toast

class BenefitPayButtonExample: UIViewController {
    @IBOutlet weak var benefitPayButton: BenefitPayButton!
    @IBOutlet weak var eventsTextView: UITextView!
    
    
    
    var dictConfig:[String:Any] = ["operator":["publicKey":"pk_test_HJN863LmO15EtDgo9cqK7sjS","hashString":""],
                                   "order":["id":"",
                                            "amount":0.1,
                                            "currency":"BHD",
                                            "description": "Authentication description",
                                            "reference":"",
                                            "metadata":[:]],
                                   "invoice":["id":""],
                                   "merchant":["id":""],
                                   "customer":["id":"",
                                               "name":[["lang":"en","first":"TAP","middle":"","last":"PAYMENTS"]],
                                               "contact":["email":"tap@tap.company",
                                                          "phone":["countryCode":"+965","number":"88888888"]]],
                                   "interface":["locale": "en",
                                                "theme": UIView().traitCollection.userInterfaceStyle == .dark ? "dark": "light",
                                                "edges": "curved",
                                                "colorStyle":UIView().traitCollection.userInterfaceStyle == .dark ? "monochrome": "colored",
                                                "loader": true],
                                   "post":["url":""]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBenfitPayButton()
    }

    func setupBenfitPayButton() {
        benefitPayButton.initBenefitPayButton(configDict: self.dictConfig, delegate: self)
    }
    
    @IBAction func optionsClicked(_ sender: Any) {
        let alertController:UIAlertController = .init(title: "Options", message: "Select one please", preferredStyle: .actionSheet)
        alertController.addAction(.init(title: "Copy logs", style: .default, handler: { _ in
            UIPasteboard.general.string = self.eventsTextView.text
        }))
        
        alertController.addAction(.init(title: "Clear logs", style: .default, handler: { _ in
            self.eventsTextView.text = ""
        }))
        
        alertController.addAction(.init(title: "Configs", style: .default, handler: { _ in
            self.configClicked()
        }))
        
        alertController.addAction(.init(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
    
    func configClicked() {
        let configCtrl:BenefitPayButtonSettingsViewController = storyboard?.instantiateViewController(withIdentifier: "BenefitPayButtonSettingsViewController") as! BenefitPayButtonSettingsViewController
        configCtrl.config = dictConfig
        configCtrl.delegate = self
        //present(configCtrl, animated: true)
        self.navigationController?.pushViewController(configCtrl, animated: true)
        
    }
    
    /*func setConfig(config: CardWebSDKConfig) {
        self.config = config
    }*/
}


extension BenefitPayButtonExample: BenefitPayButtonSettingsViewControllerDelegate {
    
    func updateConfig(config: [String:Any]) {
        self.dictConfig = config
        setupBenfitPayButton()
    }
}

extension BenefitPayButtonExample: BenefitPayButtonDelegate {
    
    func onError(data: String) {
        //print("CardWebSDKExample onError \(data)")
        eventsTextView.text = "\n\n========\n\nonError \(data)\(eventsTextView.text ?? "")"
    }
    
    func onSuccess(data: String) {
        //print("CardWebSDKExample onError \(data)")
        eventsTextView.text = "\n\n========\n\nonSuccess \(data)\(eventsTextView.text ?? "")"
        if let json = try? JSONSerialization.jsonObject(with: Data(data.utf8), options: .mutableContainers),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            let controller:OnSuccessViewController = storyboard?.instantiateViewController(withIdentifier: "OnSuccessViewController") as! OnSuccessViewController
            controller.string = String(decoding: jsonData, as: UTF8.self)
            self.present(controller, animated: true, completion: nil)
        } else {
            print("json data malformed")
        }
    }
    
    func onOrderCreated(data: String) {
        //print("CardWebSDKExample onError \(data)")
        eventsTextView.text = "\n\n========\n\nonOrderCreated \(data)\(eventsTextView.text ?? "")"
    }
    
    func onChargeCreated(data: String) {
        //print("CardWebSDKExample onError \(data)")
        eventsTextView.text = "\n\n========\n\nonChargeCreated \(data)\(eventsTextView.text ?? "")"
    }
    
    func onReady(){
        //print("CardWebSDKExample onReady")
        eventsTextView.text = "\n\n========\n\nonReady\(eventsTextView.text ?? "")"
    }
    
    func onClicked() {
        //print("CardWebSDKExample onFocus")
        eventsTextView.text = "\n\n========\n\nonClicked\(eventsTextView.text ?? "")"
    }
    
    func onCanceled() {
        eventsTextView.text = "\n\n========\n\nonCanceled\(eventsTextView.text ?? "")"
    }
}
