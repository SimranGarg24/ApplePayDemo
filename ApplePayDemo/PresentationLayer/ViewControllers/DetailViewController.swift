//
//  ViewController.swift
//  ApplePayDemo
//
//  Created by Saheem Hussain on 05/09/23.
//

import UIKit
import PassKit

class DetailViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var nameLbl: UILabel!
    
    @IBOutlet weak var priceLbl: UILabel!
    
    @IBOutlet weak var applePayView: UIView!
    
    // MARK: - Properties
    let viewModel = DetailViewModel()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        nameLbl.text = viewModel.name
        priceLbl.text = "Price: Rs. \(String(format: "%.02f", viewModel.price))"
        self.addApplePayButton()
    }
    
    // MARK: - Methods
    func addApplePayButton() {
        let result  = viewModel.applePayStatus()
        var button: UIButton?

        if result.canMakePayments {
            // The iOS app displays the payment button by adding an instance of PKPaymentButton.
            button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
            button?.addTarget(self, action: #selector(self.payPressed), for: .touchUpInside)

        } else if result.canSetupCards {
            button = PKPaymentButton(paymentButtonType: .setUp, paymentButtonStyle: .black)
            button?.addTarget(self, action: #selector(self.setupPressed), for: .touchUpInside)
            
        } else {
            displayDefaultAlert(title: "Error", message: "Unable to make Apple Pay transaction.")
        }
        
        if let applePayButton = button {
            
            applePayView.addSubview(applePayButton)
            applePayButton.translatesAutoresizingMaskIntoConstraints = false
            applePayButton.centerXAnchor.constraint(equalTo: applePayView.centerXAnchor).isActive = true
            applePayButton.centerYAnchor.constraint(equalTo: applePayView.centerYAnchor).isActive = true
        }
    }
    
    func displayDefaultAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
       let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func payPressed(sender: AnyObject) {
        viewModel.startPayment()
    }
    
    @objc func setupPressed(sender: AnyObject) {
        let passLibrary = PKPassLibrary()
        passLibrary.openPaymentSetup()
    }

}
